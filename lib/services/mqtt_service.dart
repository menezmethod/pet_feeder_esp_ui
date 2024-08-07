import 'dart:async';
import 'dart:io' show Platform;
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:mqtt_client/mqtt_browser_client.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

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
    print('Initializing MQTT Client...');
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
        .keepAliveFor(20)
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
      print('MQTT: Connecting to broker $broker:$port');
      await _client.connect();
    } catch (e) {
      print('MQTT: Exception during connect: $e');
      disconnect();
    }
  }

  void disconnect() {
    print('MQTT: Disconnecting');
    _client.disconnect();
    _connectionStateController.add(MqttConnectionState.disconnected);
  }

  void subscribe(String topic) {
    print('MQTT: Subscribing to $topic');
    _client.subscribe(topic, MqttQos.atLeastOnce);
  }

  void publish(String topic, String message) {
    print('MQTT: Publishing to $topic: $message');
    final builder = MqttClientPayloadBuilder();
    builder.addString(message);
    _client.publishMessage(topic, MqttQos.atLeastOnce, builder.payload!);
  }

  void _onConnected() {
    print('MQTT: Connected');
    _connectionStateController.add(MqttConnectionState.connected);
    _client.updates!.listen((List<MqttReceivedMessage<MqttMessage>> c) {
      final recMess = c[0].payload as MqttPublishMessage;
      final message = ReceivedMessage(
        c[0].topic,
        MqttPublishPayload.bytesToStringAsString(recMess.payload.message),
      );
      print('MQTT: Received message - Topic: ${message.topic}, Payload: ${message.payload}');
      _messageController.add(message);
    });
  }

  void _onDisconnected() {
    print('MQTT: Disconnected');
    _connectionStateController.add(MqttConnectionState.disconnected);
  }

  void _onSubscribed(String topic) {
    print('MQTT: Subscribed to topic: $topic');
  }

  void _pongCallback() {
    print('MQTT: Ping response received');
  }
}

class ReceivedMessage {
  final String topic;
  final String payload;

  ReceivedMessage(this.topic, this.payload);
}