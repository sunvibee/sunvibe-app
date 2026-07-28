import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

class MQTTService {
  static final MQTTService instance = MQTTService._internal();

  factory MQTTService() => instance;

  MQTTService._internal();

  late MqttServerClient client;

  Future<void> connect() async {
    client = MqttServerClient(
      "i16d357e.ala.asia-southeast1.emqxsl.com",
      "FlutterApp",
    );

    client.port = 8883;

    client.secure = true;

    client.keepAlivePeriod = 30;

    client.logging(on: true);

    client.onConnected = () {
      print("MQTT Connected");

      client.subscribe(
        "solarcleaner/status",
        MqttQos.atLeastOnce,
      );

      client.subscribe(
        "solarcleaner/response",
        MqttQos.atLeastOnce,
      );
    };

    client.onDisconnected = () {
      print("MQTT Disconnected");
    };

    client.connectionMessage = MqttConnectMessage()
        .withClientIdentifier("FlutterApp")
        .authenticateAs(
          "SunVibee",
          "SunVibee@123",
        )
        .startClean();

    try {
      await client.connect();

      client.updates!.listen((event) {
        final rec = event.first.payload as MqttPublishMessage;

        final msg = MqttPublishPayload.bytesToStringAsString(
          rec.payload.message,
        );

        print("Received : $msg");
      });
    } catch (e) {
      print(e);
      client.disconnect();
    }
  }

  void publish(String cmd) {
    final builder = MqttClientPayloadBuilder();

    builder.addString(cmd);

    client.publishMessage(
      "solarcleaner/command",
      MqttQos.atLeastOnce,
      builder.payload!,
    );
  }

  void disconnect() {
    client.disconnect();
  }
}