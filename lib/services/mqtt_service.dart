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
  final Map<String, DateTime> _robotLastSeen = {};

  bool? _mockIsConnected;
  bool? _mockRobotOnline;

  /// Used in unit/widget tests to mock connection or online state
  void setMockState({bool? isConnected, bool? isRobotOnline}) {
    _mockIsConnected = isConnected;
    _mockRobotOnline = isRobotOnline;
    if (isRobotOnline != null) {
      _robotOnlineStatusController.add(isRobotOnline);
    }
  }

  void resetMockState() {
    _mockIsConnected = null;
    _mockRobotOnline = null;
  }

  final _messageController = StreamController<MqttMessage>.broadcast();
  Stream<MqttMessage> get onMessage => _messageController.stream;

  final _connectionStatusController = StreamController<bool>.broadcast();
  Stream<bool> get onConnectionStatus => _connectionStatusController.stream;

  final _robotOnlineStatusController = StreamController<bool>.broadcast();
  Stream<bool> get onRobotOnlineStatus => _robotOnlineStatusController.stream;

  Timer? _heartbeatCheckTimer;

  bool get isConnected {
    if (_mockIsConnected != null) return _mockIsConnected!;
    return _client?.connectionStatus?.state == MqttConnectionState.connected;
  }

  /// True if at least one robot has sent telemetry or heartbeat within the
  /// last 90 seconds. The extended window accounts for ESP32 firmware that
  /// only publishes on state changes (not periodic heartbeats).
  bool get isRobotOnline {
    if (_mockRobotOnline != null) return _mockRobotOnline!;
    if (!isConnected) return false;
    if (_subscribedRobots.isNotEmpty && _robotLastSeen.isEmpty) return true;
    final now = DateTime.now();
    return _robotLastSeen.values.any((t) => now.difference(t).inSeconds <= 90);
  }

  void _recordRobotTelemetry(String topic, String payload) {
    final upper = payload.toUpperCase().trim();
    final parts = topic.split('/');
    final robotId = parts.length >= 2 ? parts[1] : 'general';

    final wasOnline = isRobotOnline;
    if (upper.contains('OFFLINE') || upper.contains('DISCONNECT')) {
      _robotLastSeen.remove(robotId);
    } else {
      _robotLastSeen[robotId] = DateTime.now();
    }

    if (wasOnline != isRobotOnline) {
      _robotOnlineStatusController.add(isRobotOnline);
    }
  }

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
      _connectionStatusController.add(true);
      _client!.subscribe('solarcleaner/status', MqttQos.atLeastOnce);
      _client!.subscribe('solarcleaner/response', MqttQos.atLeastOnce);
      _client!.subscribe('solarcleaner/+/status', MqttQos.atLeastOnce);
      _client!.subscribe('solarcleaner/+/response', MqttQos.atLeastOnce);
      // Re-subscribe to any robots that were added before/during reconnect.
      for (final robotId in _subscribedRobots) {
        _client!.subscribe('solarcleaner/$robotId/status', MqttQos.atLeastOnce);
        _client!.subscribe('solarcleaner/$robotId/response', MqttQos.atLeastOnce);
      }

      _heartbeatCheckTimer?.cancel();
      _heartbeatCheckTimer = Timer.periodic(const Duration(seconds: 10), (_) {
        final wasOnline = isRobotOnline;
        final now = DateTime.now();
        _robotLastSeen.removeWhere((_, time) => now.difference(time).inSeconds > 90);
        if (wasOnline != isRobotOnline) {
          _robotOnlineStatusController.add(isRobotOnline);
        }
      });
    };

    _client!.onDisconnected = () {
      print('MQTT Disconnected');
      _heartbeatCheckTimer?.cancel();
      _robotLastSeen.clear();
      _connectionStatusController.add(false);
      _robotOnlineStatusController.add(false);
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
        _recordRobotTelemetry(topic, msg);
        _messageController.add(MqttMessage(topic, msg));
      });
    } catch (e) {
      print("MQTT connect error: $e");
      _heartbeatCheckTimer?.cancel();
      _robotLastSeen.clear();
      _connectionStatusController.add(false);
      _robotOnlineStatusController.add(false);
      _client?.disconnect();
    }
  }

  /// Subscribe to a robot's status/response topics using its client ID.
  /// Seeds [_robotLastSeen] immediately so the robot is considered reachable
  /// as soon as it is subscribed, rather than waiting for the first telemetry
  /// frame which may never come if the ESP32 only publishes on state changes.
  void subscribeToRobot(String robotId) {
    _subscribedRobots.add(robotId); // persists across reconnects
    if (!isConnected) return;
    _client!.subscribe('solarcleaner/$robotId/status', MqttQos.atLeastOnce);
    _client!.subscribe('solarcleaner/$robotId/response', MqttQos.atLeastOnce);
    // Assume the robot is reachable until proven otherwise.
    // This prevents a false "Robot Offline" when the ESP32 is running but
    // hasn't published its first heartbeat yet.
    _robotLastSeen[robotId] = DateTime.now();
    final wasOnline = isRobotOnline;
    if (wasOnline != isRobotOnline) {
      _robotOnlineStatusController.add(isRobotOnline);
    }
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

  /// Publish to all currently connected robot command topics.
  void publishToAll(String cmd) {
    for (final robotId in Set.of(_subscribedRobots)) {
      publishToRobot(robotId, cmd);
    }
  }

  /// Publish to the legacy flat topic (used by HomeScreen).
  void publish(String cmd) {
    if (!isConnected) return;
    final builder = MqttClientPayloadBuilder()..addString(cmd);
    _client!.publishMessage(
      'solarcleaner/command',
      MqttQos.atLeastOnce,
      builder.payload!,
    );
  }

  void disconnect() {
    _heartbeatCheckTimer?.cancel();
    _robotLastSeen.clear();
    _connectionStatusController.add(false);
    _robotOnlineStatusController.add(false);
    _client?.disconnect();
  }
}