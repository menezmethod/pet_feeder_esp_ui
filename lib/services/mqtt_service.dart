import 'dart:async';
import 'dart:io' show Platform;
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:mqtt_client/mqtt_browser_client.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../core/utils/log.dart';

enum MqttConnectionState { disconnected, connecting, connected }

class MqttService {
  final String broker;
  final int port;
  final String clientIdentifier;

  late MqttClient _client;
  final _connectionStateController = StreamController<MqttConnectionState>.broadcast();
  final _messageController = StreamController<ReceivedMessage>.broadcast();

  MqttService({
    required this.broker,
    required this.port,
    String? clientIdentifier,
  }) : this.clientIdentifier = clientIdentifier ?? 'flutter_pet_feeder_${DateTime.now().millisecondsSinceEpoch}' {
    _initializeClient();
  }

  void _initializeClient() {
    logDebug('Initializing MQTT Client...');
    final wsUrl = 'wss://$broker:$port/mqtt';

    if (!kIsWeb && (Platform.isIOS || Platform.isAndroid)) {
      _client = MqttServerClient.withPort(wsUrl, clientIdentifier, port);
      (_client as MqttServerClient).useWebSocket = true;
      (_client as MqttServerClient).websocketProtocols = ['mqtt'];
    } else {
      _client = MqttBrowserClient.withPort(wsUrl, clientIdentifier, port);
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
