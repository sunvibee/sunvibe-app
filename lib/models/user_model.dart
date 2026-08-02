class UserModel {
  final int id;
  final String username;
  final String? wifiSsid;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.username,
    this.wifiSsid,
    required this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'] as int,
        username: json['username'] as String,
        wifiSsid: json['wifi_ssid'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}
