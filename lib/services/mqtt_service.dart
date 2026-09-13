import 'dart:async';
import 'dart:convert' show base64;
import 'dart:io' show Platform, X509Certificate;
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:mqtt_client/mqtt_browser_client.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../core/utils/log.dart';
import '../core/config/mqtt_ca_cert.dart';
import '../core/config/secrets.dart';

enum MqttConnectionState { disconnected, connecting, connected }

class MqttService {
  final String broker;
  final int port;
  final String clientIdentifier;

  // Browsers can't open raw TLS sockets -- only the web build uses this,
  // over the broker's separate websocket+TLS listener.
  static const int _webPort = 9883;

  static List<int> get _pinnedCertDer {
    final body = mqttCaCertPem.split('\n').where((l) => !l.startsWith('-----')).join();
    return base64.decode(body.trim());
  }

  static bool _listEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  late MqttClient _client;
  final _connectionStateController = StreamController<MqttConnectionState>.broadcast();
  final _messageController = StreamController<ReceivedMessage>.broadcast();

  MqttService({
    required this.broker,
    required this.port,
    String? clientIdentifier,
  }) : clientIdentifier = clientIdentifier ?? 'flutter_pet_feeder_${DateTime.now().millisecondsSinceEpoch}' {
    _initializeClient();
  }

  void _initializeClient() {
    logDebug('Initializing MQTT Client...');

    if (!kIsWeb && (Platform.isIOS || Platform.isAndroid)) {
      // Raw TCP + TLS, matching the firmware's own connection to the same
      // broker -- no websocket layer needed off the browser.
      //
      // Exact-certificate pinning via onBadCertificate, not
      // SecurityContext.setTrustedCertificatesBytes: that call does not
      // reliably trust a self-signed leaf as its own root on this platform
      // (verified with a minimal repro outside Flutter -- trust-chain
      // validation fails even with CA:TRUE set and the right SAN). Pinning
      // the exact DER bytes is stronger anyway for a single fixed cert.
      final serverClient = MqttServerClient.withPort(broker, clientIdentifier, port);
      serverClient.secure = true;
      serverClient.onBadCertificate = (dynamic cert) {
        final presented = (cert as X509Certificate).der;
        return _listEquals(presented, _pinnedCertDer);
      };
      _client = serverClient;
    } else {
      final wsUrl = 'wss://$broker:$_webPort/mqtt';
      _client = MqttBrowserClient.withPort(wsUrl, clientIdentifier, _webPort);
    }

    _client.logging(on: true);
    _client.onConnected = _onConnected;
    _client.onDisconnected = _onDisconnected;
    _client.onSubscribed = _onSubscribed;
    _client.pongCallback = _pongCallback;
    _client.keepAlivePeriod = 20;
    _client.autoReconnect = true;

    final connMess = MqttConnectMessage()
        .withClientIdentifier(clientIdentifier)
        .authenticateAs(mqttUsername, mqttPassword)
        .withWillTopic('willtopic')
        .withWillMessage('My Will message')
        .startClean()
        .withWillQos(MqttQos.atLeastOnce);
    _client.connectionMessage = connMess;
  }

  Stream<MqttConnectionState> get connectionStatus => _connectionStateController.stream;
  Stream<ReceivedMessage> get messageStream => _messageController.stream;

  Future<void> connect() async {
    _connectionStateController.add(MqttConnectionState.connecting);
    try {
      logDebug('MQTT: Connecting to broker $broker:$port');
      await _client.connect();
    } catch (e) {
      logDebug('MQTT: Exception during connect: $e');
      disconnect();
    }
  }

  void disconnect() {
    logDebug('MQTT: Disconnecting');
    _client.disconnect();
    _connectionStateController.add(MqttConnectionState.disconnected);
  }

  void subscribe(String topic) {
    logDebug('MQTT: Subscribing to $topic');
    _client.subscribe(topic, MqttQos.atLeastOnce);
  }

  void publish(String topic, String message) {
    logDebug('MQTT: Publishing to $topic: $message');
    final builder = MqttClientPayloadBuilder();
    builder.addString(message);
    final messageId = _client.publishMessage(topic, MqttQos.atLeastOnce, builder.payload!);
    logDebug('MQTT: Published message with ID: $messageId');
  }

  void _onConnected() {
    logDebug('MQTT: Connected');
    _connectionStateController.add(MqttConnectionState.connected);

    _client.updates!.listen((List<MqttReceivedMessage<MqttMessage>> c) {
      final recMess = c[0].payload as MqttPublishMessage;
      final pt = MqttPublishPayload.bytesToStringAsString(recMess.payload.message);
      final message = ReceivedMessage(c[0].topic, pt);
      final messageId = recMess.variableHeader?.messageIdentifier ?? -1;
      final qos = recMess.header?.qos ?? MqttQos.atMostOnce;

      // No dedup here: MQTT only delivers a message when the broker actually
      // received a publish. Two identical payloads in a row (e.g. the same
      // feed confirmation twice) are two real events, not one duplicate --
      // dropping the second one previously made a double-feed invisible.
      logDebug('MQTT: Received message - Topic: ${message.topic}, Payload: ${message.payload}, Message ID: $messageId, QoS: $qos');
      _messageController.add(message);
    });
  }

  void _onDisconnected() {
    logDebug('MQTT: Disconnected');
    _connectionStateController.add(MqttConnectionState.disconnected);
  }

  void _onSubscribed(String topic) {
    logDebug('MQTT: Subscribed to topic: $topic');
  }

  void _pongCallback() {
    logDebug('MQTT: Ping response received');
  }
}

class ReceivedMessage {
  final String topic;
  final String payload;

  ReceivedMessage(this.topic, this.payload);
}
