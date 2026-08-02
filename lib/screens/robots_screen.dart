import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'home_screen.dart';
import 'reports_screen.dart';
import 'support_screen.dart';
import '../utils/app_colors.dart';
import 'notification_screen.dart';
import '../services/mqtt_service.dart';
import '../services/api_service.dart';
import '../providers/auth_provider.dart';

class RobotsScreen extends StatefulWidget {
  const RobotsScreen({super.key});

  @override
  State<RobotsScreen> createState() => _RobotsScreenState();
}

class _RobotsScreenState extends State<RobotsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final List<_ConnectedRobot> _connectedRobots = [];
  StreamSubscription<MqttMessage>? _mqttSub;

  int get _totalRobots => _connectedRobots.length;
  int get _onlineRobots => _connectedRobots.where((r) => r.isRunning).length;
  int get _offlineRobots => _connectedRobots.where((r) => !r.isRunning).length;
  static const int _alerts = 0;

@override
  void initState() {
    super.initState();
    _mqttSub = MQTTService.instance.onMessage.listen(_handleMqttMessage);
    // Load robots saved to this account from previous sessions
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadRobotsFromApi());
  }

  double _scale(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return (width / 375).clamp(0.85, 1.3);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _mqttSub?.cancel();
    super.dispose();
  }

  void _showFeedback(String message, Color color) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: color,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
  }


  @override
  Widget build(BuildContext context) {
    final scale = _scale(context);
    final horizontalPadding = (20 * scale).clamp(16, 30).toDouble();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                18 * scale,
                horizontalPadding,
                0,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(scale),
                    SizedBox(height: 18 * scale),
                    _buildSearchBar(scale),
                    SizedBox(height: 18 * scale),
                    _buildStatsRow(scale),
                    SizedBox(height: 12 * scale),
                    if (_connectedRobots.isEmpty)
                      _buildEmptyState(scale)
                    else
                      _buildRobotList(scale),
                    SizedBox(height: 20 * scale),
                    _buildAddNewRobot(scale),
                    SizedBox(height: 20 * scale),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  //---------------- Header ----------------
  Widget _buildHeader(double scale) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            "Robots",
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 28 * scale,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),
        SizedBox(width: 12 * scale),
        Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          elevation: 1,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NotificationsScreen()),
            ),
            child: Padding(
              padding: EdgeInsets.all(10 * scale),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    Icons.notifications_none,
                    size: 24 * scale,
                    color: Colors.black87,
                  ),
                  Positioned(
                    right: -1 * scale,
                    top: -1 * scale,
                    child: Container(
                      width: 9 * scale,
                      height: 9 * scale,
                      decoration: const BoxDecoration(
                        color: AppColors.orange,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  //---------------- Search Bar ----------------
  Widget _buildSearchBar(double scale) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: EdgeInsets.symmetric(
        horizontal: 16 * scale,
        vertical: 4 * scale,
      ),
      child: Row(
        children: [
          Icon(Icons.search, color: Colors.grey.shade500, size: 22 * scale),
          SizedBox(width: 10 * scale),
          Expanded(
            child: TextField(
              controller: _searchController,
              style: TextStyle(fontSize: 15 * scale),
              decoration: InputDecoration(
                hintText: "Search by Robot ID",
                hintStyle: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 15 * scale,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 14 * scale),
              ),
            ),
          ),
          InkWell(
            onTap: () => _showFeedback("Filters", AppColors.navy),
            child: Padding(
              padding: EdgeInsets.all(6 * scale),
              child: Icon(Icons.tune, color: Colors.black87, size: 20 * scale),
            ),
          ),
        ],
      ),
    );
  }

  //---------------- Stats Row ----------------
  Widget _buildStatsRow(double scale) {
    final stats = [
      _StatData(
        icon: Icons.smart_toy_outlined,
        iconBg: const Color(0xFFDCEAFB),
        iconColor: const Color(0xFF1D6FF2),
        label: "Total Robots",
        value: _totalRobots,
        valueColor: Colors.black,
      ),
      _StatData(
        icon: Icons.wifi,
        iconBg: const Color(0xFFDCF5E4),
        iconColor: AppColors.green,
        label: "Online",
        value: _onlineRobots,
        valueColor: AppColors.green,
      ),
      _StatData(
        icon: Icons.wifi_off,
        iconBg: const Color(0xFFFBDCDC),
        iconColor: AppColors.red,
        label: "Offline",
        value: _offlineRobots,
        valueColor: AppColors.red,
      ),
      _StatData(
        icon: Icons.warning_amber_rounded,
        iconBg: const Color(0xFFFBEACB),
        iconColor: AppColors.orange,
        label: "Alerts",
        value: _alerts,
        valueColor: AppColors.orange,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 340;

        if (isNarrow) {
          // 2x2 grid on very small screens so nothing gets squeezed.
          return Column(
            children: [
              Row(
                children: [
                  Expanded(child: _statCard(scale, stats[0])),
                  SizedBox(width: 12 * scale),
                  Expanded(child: _statCard(scale, stats[1])),
                ],
              ),
              SizedBox(height: 12 * scale),
              Row(
                children: [
                  Expanded(child: _statCard(scale, stats[2])),
                  SizedBox(width: 12 * scale),
                  Expanded(child: _statCard(scale, stats[3])),
                ],
              ),
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: _statCard(scale, stats[0])),
            SizedBox(width: 10 * scale),
            Expanded(child: _statCard(scale, stats[1])),
            SizedBox(width: 10 * scale),
            Expanded(child: _statCard(scale, stats[2])),
            SizedBox(width: 10 * scale),
            Expanded(child: _statCard(scale, stats[3])),
          ],
        );
      },
    );
  }

  Widget _statCard(double scale, _StatData data) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        vertical: 16 * scale,
        horizontal: 10 * scale,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(.10),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 22 * scale,
            backgroundColor: data.iconBg,
            child: Icon(data.icon, color: data.iconColor, size: 20 * scale),
          ),
          SizedBox(height: 10 * scale),
          Text(
            data.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12.5 * scale, color: Colors.black87),
          ),
          SizedBox(height: 6 * scale),
          Text(
            "${data.value}",
            style: TextStyle(
              fontSize: 22 * scale,
              fontWeight: FontWeight.bold,
              color: data.valueColor,
            ),
          ),
        ],
      ),
    );
  }

  //---------------- Empty State ----------------
  Widget _buildEmptyState(double scale) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 12 * scale),
      child: Column(
        children: [
          _decorativeRobotIllustration(scale),
          SizedBox(height: 24 * scale),
          Text(
            "No robots connected yet.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20 * scale,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          SizedBox(height: 10 * scale),
          Text(
            "Add your first robot to monitor, manage and keep it running smoothly.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14 * scale,
              color: Colors.grey.shade600,
              height: 1.4,
            ),
          ),
          SizedBox(height: 22 * scale),
          _connectRobotButton(scale),
        ],
      ),
    );
  }

  Widget _decorativeRobotIllustration(double scale) {
    final size = 260 * scale;
    return SizedBox(
      height: size,
      width: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.orange.withOpacity(.10),
            ),
          ),
          Positioned(
            top: size * 0.06,
            left: size * 0.06,
            child: Icon(
              Icons.add,
              size: 16 * scale,
              color: AppColors.orange.withOpacity(.5),
            ),
          ),
          Positioned(
            top: size * 0.06,
            right: size * 0.06,
            child: Icon(
              Icons.add,
              size: 16 * scale,
              color: AppColors.orange.withOpacity(.5),
            ),
          ),
          Positioned(
            bottom: size * 0.18,
            right: size * 0.02,
            child: Icon(
              Icons.add,
              size: 14 * scale,
              color: AppColors.orange.withOpacity(.4),
            ),
          ),
          Positioned(
            top: size * 0.30,
            left: size * 0.0,
            child: Icon(
              Icons.circle,
              size: 6 * scale,
              color: AppColors.orange.withOpacity(.4),
            ),
          ),
          Positioned(
            top: size * 0.34,
            right: size * 0.02,
            child: Icon(
              Icons.circle,
              size: 6 * scale,
              color: AppColors.orange.withOpacity(.4),
            ),
          ),
          SizedBox(
            width: size * 0.72,
            height: size * 0.72,
            child: Image.asset(
              'assets/images/robot.png',
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                // Placeholder shown until you add assets/images/robot.png
                // (and register it under `flutter: assets:` in pubspec.yaml).
                return Icon(
                  Icons.smart_toy,
                  size: size * 0.4,
                  color: AppColors.orange.withOpacity(.6),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _connectRobotButton(double scale) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.blue,
          foregroundColor: Colors.white,
          elevation: 3,
          padding: EdgeInsets.symmetric(vertical: 16 * scale),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
        ),
        onPressed: _showConnectDialog,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.link, size: 20 * scale),
            SizedBox(width: 8 * scale),
            Text(
              "Connect Robot",
              style: TextStyle(
                fontSize: 16 * scale,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  //---------------- Add New Robot (inline FAB-style) ----------------
  Widget _buildAddNewRobot(double scale) {
    return Align(
      alignment: Alignment.centerRight,
      child: Column(
        children: [
          Material(
            color: AppColors.blue,
            shape: const CircleBorder(),
            elevation: 4,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: _showConnectDialog,
              child: Padding(
                padding: EdgeInsets.all(18 * scale),
                child: Icon(Icons.add, color: Colors.white, size: 26 * scale),
              ),
            ),
          ),
          SizedBox(height: 8 * scale),
          Text(
            "Add New Robot",
            style: TextStyle(fontSize: 13 * scale, color: Colors.black87),
          ),
        ],
      ),
    );
  }

  // ---- Connect dialog ----
  void _showConnectDialog() {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.link, color: AppColors.orange),
            SizedBox(width: 10),
            Text(
              "Connect Robot",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Enter the Client ID provided with your robot.",
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: controller,
                decoration: InputDecoration(
                  labelText: "Client ID",
                  hintText: "e.g. SV-001",
                  prefixIcon: const Icon(Icons.smart_toy_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: AppColors.orange,
                      width: 2,
                    ),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Client ID is required';
                  if (_connectedRobots.any((r) =>
                      r.clientId.toLowerCase() == v.trim().toLowerCase())) {
                    return 'This robot is already connected';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.orange,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              if (formKey.currentState!.validate()) {
                final id = controller.text.trim();
                Navigator.pop(ctx);
                _connectRobot(id);
              }
            },
            child: const Text("Connect"),
          ),
        ],
      ),
    );
  }

  Future<void> _loadRobotsFromApi() async {
    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      if (token == null) return;
      final robots = await ApiService(token: token).getRobots();
      if (!mounted) return;
      setState(() {
        for (final r in robots) {
          final uid = r['robot_uid'] as String;
          if (!_connectedRobots.any((c) => c.clientId == uid)) {
            _connectedRobots.add(_ConnectedRobot(
              clientId: uid,
              label: r['robot_name'] as String? ?? uid,
            ));
            MQTTService.instance.subscribeToRobot(uid);
          }
        }
      });
    } catch (_) {
      // silently ignore — robots will just start empty
    }
  }

  Future<void> _connectRobot(String clientId) async {
    // Show a compact loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AlertDialog(
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppColors.orange),
            SizedBox(width: 18),
            Text("Verifying robot…"),
          ],
        ),
      ),
    );

    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      final api = ApiService(token: token);

      // 1. Validate the ID exists in the pre-registered registry
      final info = await api.validateRobot(clientId);
      // Use DB-stored uid for exact topic casing (MQTT topics are case-sensitive).
      final canonicalId = info['robot_uid'] as String? ?? clientId;
      final label = info['label'] as String? ?? canonicalId;

      // 2. Associate with the user's account
      await api.registerRobot(robotUid: canonicalId, robotName: label);

      // 3. Subscribe to MQTT topics for this robot
      MQTTService.instance.subscribeToRobot(canonicalId);

      if (!mounted) return;
      Navigator.pop(context); // close loading
      setState(() => _connectedRobots.add(
        _ConnectedRobot(clientId: canonicalId, label: label),
      ));
      _showFeedback('Robot $canonicalId connected!', AppColors.green);
    } on ApiException catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      _showFeedback(e.message, AppColors.red);
    } catch (_) {
      if (!mounted) return;
      Navigator.pop(context);
      _showFeedback("Connection failed. Try again.", AppColors.red);
    }
  }

  void _startRobot(String clientId) {
    MQTTService.instance.publishToRobot(clientId, "ON");
    final idx = _connectedRobots.indexWhere((r) => r.clientId == clientId);
    if (idx != -1) setState(() => _connectedRobots[idx].status = _RobotStatus.running);
    _showFeedback("Robot $clientId started", AppColors.orange);
  }

  void _stopRobot(String clientId) {
    MQTTService.instance.publishToRobot(clientId, 'OFF');
    final idx = _connectedRobots.indexWhere((r) => r.clientId == clientId);
    if (idx != -1) setState(() => _connectedRobots[idx].status = _RobotStatus.stopped);
    _showFeedback('Robot $clientId stopped', AppColors.navy);
  }

  Future<void> _disconnectRobot(String clientId) async {
    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      await ApiService(token: token).removeRobot(clientId);
    } catch (_) {}
    MQTTService.instance.unsubscribeFromRobot(clientId);
    if (!mounted) return;
    setState(() => _connectedRobots.removeWhere((r) => r.clientId == clientId));
    _showFeedback('Robot $clientId disconnected', AppColors.red);
  }

  void _handleMqttMessage(MqttMessage msg) {
    final parts = msg.topic.split('/');
    if (parts.length < 3) return;
    final robotId = parts[1];
    final payload = msg.payload.toUpperCase();
    final idx = _connectedRobots.indexWhere((r) => r.clientId == robotId);
    if (idx == -1) return;
    setState(() {
      if (payload.contains('ON') || payload.contains('RUN') || payload.contains('START')) {
        _connectedRobots[idx].status = _RobotStatus.running;
      } else if (payload.contains('OFF') || payload.contains('STOP')) {
        _connectedRobots[idx].status = _RobotStatus.stopped;
      }
    });
  }

  // ---- Robot list & card ----
  Widget _buildRobotList(double scale) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Connected Robots",
          style: TextStyle(
            fontSize: 18 * scale,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        SizedBox(height: 12 * scale),
        ..._connectedRobots.map((r) => _buildRobotCard(r, scale)),
      ],
    );
  }

  Widget _buildRobotCard(_ConnectedRobot robot, double scale) {
    final statusColor = robot.isRunning ? AppColors.green : Colors.grey;
    return Container(
      margin: EdgeInsets.only(bottom: 12 * scale),
      padding: EdgeInsets.all(16 * scale),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(.10),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50 * scale,
            height: 50 * scale,
            decoration: BoxDecoration(
              color: statusColor.withOpacity(.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.smart_toy_outlined,
              color: statusColor,
              size: 26 * scale,
            ),
          ),
          SizedBox(width: 14 * scale),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Client ID",
                  style: TextStyle(
                    fontSize: 11 * scale,
                    color: Colors.grey.shade500,
                  ),
                ),
                Text(
                  robot.label,
                  style: TextStyle(
                    fontSize: 16 * scale,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                if (robot.label != robot.clientId)
                  Text(
                    robot.clientId,
                    style: TextStyle(
                      fontSize: 11 * scale,
                      color: Colors.grey.shade500,
                    ),
                  ),
                SizedBox(height: 5 * scale),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7 * scale,
                      height: 7 * scale,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: 5 * scale),
                    Text(
                      robot.isRunning ? "RUNNING" : "STOPPED",
                      style: TextStyle(
                        fontSize: 11 * scale,
                        fontWeight: FontWeight.w600,
                        color: robot.isRunning
                            ? AppColors.green
                            : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 34 * scale,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.orange,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade200,
                    padding: EdgeInsets.symmetric(horizontal: 10 * scale),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                  icon: Icon(Icons.play_arrow, size: 15 * scale),
                  label: Text('Start', style: TextStyle(fontSize: 12 * scale)),
                  onPressed: robot.isRunning
                      ? null
                      : () => _startRobot(robot.clientId),
                ),
              ),
              SizedBox(height: 7 * scale),
              SizedBox(
                height: 34 * scale,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.navy,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade200,
                    padding: EdgeInsets.symmetric(horizontal: 10 * scale),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                  icon: Icon(Icons.stop, size: 15 * scale),
                  label: Text('Stop', style: TextStyle(fontSize: 12 * scale)),
                  onPressed: !robot.isRunning
                      ? null
                      : () => _stopRobot(robot.clientId),
                ),
              ),
              SizedBox(height: 7 * scale),
              SizedBox(
                height: 34 * scale,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.red,
                    side: BorderSide(color: AppColors.red, width: 1.5),
                    padding: EdgeInsets.symmetric(horizontal: 10 * scale),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: Icon(Icons.link_off, size: 15 * scale),
                  label: Text('Disconnect', style: TextStyle(fontSize: 11 * scale)),
                  onPressed: () => _disconnectRobot(robot.clientId),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

enum _RobotStatus { running, stopped }

class _ConnectedRobot {
  final String clientId;
  final String label;
  _RobotStatus status;

  _ConnectedRobot({
    required this.clientId,
    String? label,
    this.status = _RobotStatus.stopped,
  }) : label = label ?? clientId;

  bool get isRunning => status == _RobotStatus.running;
}

class _StatData {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String label;
  final int value;
  final Color valueColor;

  _StatData({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.valueColor,
  });
}
