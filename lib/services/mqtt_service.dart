import 'dart:async';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_browser_client.dart';

enum MqttConnectionState { disconnected, connecting, connected }

class MqttService {
  final String broker;
  final int port;
  final String clientIdentifier;

  late MqttBrowserClient _client;
  final _connectionStateController = StreamController<MqttConnectionState>.broadcast();
  final _messageController = StreamController<ReceivedMessage>.broadcast();

  MqttService({
    required this.broker,
    required this.port,
    String? clientIdentifier,
  }) : this.clientIdentifier = clientIdentifier ?? 'flutter_pet_feeder_${DateTime.now().millisecondsSinceEpoch}' {
    _client = MqttBrowserClient.withPort('ws://$broker', this.clientIdentifier, port);
    _client.logging(on: true);
    _client.onConnected = _onConnected;
    _client.onDisconnected = _onDisconnected;
    _client.onSubscribed = _onSubscribed;
    _client.pongCallback = _pongCallback;
  }

  Stream<MqttConnectionState> get connectionStatus => _connectionStateController.stream;
  Stream<ReceivedMessage> get messageStream => _messageController.stream;

  Future<void> connect() async {
    _connectionStateController.add(MqttConnectionState.connecting);
    try {
      await _client.connect();
    } catch (e) {
      print('Exception: $e');
      disconnect();
    }
  }

  void disconnect() {
    _client.disconnect();
    _connectionStateController.add(MqttConnectionState.disconnected);
  }

  void subscribe(String topic) {
    _client.subscribe(topic, MqttQos.atLeastOnce);
  }

  void publish(String topic, String message) {
    final builder = MqttClientPayloadBuilder();
    builder.addString(message);
    _client.publishMessage(topic, MqttQos.atLeastOnce, builder.payload!);
  }

  void _onConnected() {
    _connectionStateController.add(MqttConnectionState.connected);
    _client.updates!.listen((List<MqttReceivedMessage<MqttMessage>> c) {
      final recMess = c[0].payload as MqttPublishMessage;
      final message = ReceivedMessage(
        c[0].topic,
        MqttPublishPayload.bytesToStringAsString(recMess.payload.message),
      );
      _messageController.add(message);
    });
  }

  void _onDisconnected() {
    _connectionStateController.add(MqttConnectionState.disconnected);
  }

  void _onSubscribed(String topic) {
    print('Subscribed to topic: $topic');
  }

  void _pongCallback() {
    print('Ping response received');
  }
}

class ReceivedMessage {
  final String topic;
  final String payload;

  ReceivedMessage(this.topic, this.payload);
}