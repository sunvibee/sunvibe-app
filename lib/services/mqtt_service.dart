import 'dart:async';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

class MqttMessage {
  final String topic;
  final String payload;
  const MqttMessage(this.topic, this.payload);
}

class MQTTService {
  static final MQTTService instance = MQTTService._internal();

  factory MQTTService() => instance;

  MQTTService._internal();

  MqttServerClient? _client;

  // Tracks per-robot subscriptions so they survive MQTT reconnects.
  final Set<String> _subscribedRobots = {};

  final _messageController = StreamController<MqttMessage>.broadcast();
  Stream<MqttMessage> get onMessage => _messageController.stream;

  bool get isConnected =>
      _client?.connectionStatus?.state == MqttConnectionState.connected;

  Future<void> connect() async {
    if (isConnected) return; // already connected, skip
    final clientId = 'FlutterApp_${DateTime.now().millisecondsSinceEpoch}';
    _client = MqttServerClient(
      'i16d357e.ala.asia-southeast1.emqxsl.com',
      clientId,
    );

    _client!.port = 8883;
    _client!.secure = true;
    _client!.keepAlivePeriod = 30;
    _client!.logging(on: false);
    // Allow broker's TLS certificate even if device CA store doesn't include it.
    _client!.onBadCertificate = (dynamic _) => true;

    _client!.onConnected = () {
      print('MQTT Connected');
      _client!.subscribe('solarcleaner/status', MqttQos.atLeastOnce);
      _client!.subscribe('solarcleaner/response', MqttQos.atLeastOnce);
      // Re-subscribe to any robots that were added before/during reconnect.
      for (final robotId in _subscribedRobots) {
        _client!.subscribe('solarcleaner/$robotId/status', MqttQos.atLeastOnce);
        _client!.subscribe('solarcleaner/$robotId/response', MqttQos.atLeastOnce);
      }
    };

    _client!.onDisconnected = () {
      print('MQTT Disconnected');
    };

    _client!.connectionMessage = MqttConnectMessage()
        .withClientIdentifier(clientId)
        .withProtocolName('MQTT')
        .withProtocolVersion(4)
        .authenticateAs('SunVibee02', 'SunVibee@123')
        .startClean();

    try {
      await _client!.connect();
      _client!.updates!.listen((event) {
        final rec = event.first;
        final topic = rec.topic;
        final msg = MqttPublishPayload.bytesToStringAsString(
          (rec.payload as MqttPublishMessage).payload.message,
        );
        print("MQTT [$topic]: $msg");
        _messageController.add(MqttMessage(topic, msg));
      });
    } catch (e) {
      print("MQTT connect error: $e");
      _client?.disconnect();
    }
  }

  /// Subscribe to a robot's status/response topics using its client ID.
  void subscribeToRobot(String robotId) {
    _subscribedRobots.add(robotId); // persists across reconnects
    if (!isConnected) return;
    _client!.subscribe('solarcleaner/$robotId/status', MqttQos.atLeastOnce);
    _client!.subscribe('solarcleaner/$robotId/response', MqttQos.atLeastOnce);
  }

  /// Unsubscribe from a robot's topics when disconnecting it.
  void unsubscribeFromRobot(String robotId) {
    _subscribedRobots.remove(robotId);
    if (!isConnected) return;
    _client!.unsubscribe('solarcleaner/$robotId/status');
    _client!.unsubscribe('solarcleaner/$robotId/response');
  }

  /// Publish a command to a specific robot's command topic.
  void publishToRobot(String robotId, String cmd) {
    if (!isConnected) return;
    final builder = MqttClientPayloadBuilder()..addString(cmd);
    _client!.publishMessage(
      "solarcleaner/$robotId/command",
      MqttQos.atLeastOnce,
      builder.payload!,
    );
  }

  /// Publish to the legacy flat topic (used by HomeScreen).
  void publish(String cmd) {
    if (!isConnected) return;
    final builder = MqttClientPayloadBuilder()..addString(cmd);
    _client!.publishMessage(
      "solarcleaner/command",
      MqttQos.atLeastOnce,
      builder.payload!,
    );
  }

  void disconnect() {
    _client?.disconnect();
  }
}