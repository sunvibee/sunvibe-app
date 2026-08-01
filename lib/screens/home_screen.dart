import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'robots_screen.dart';
import 'reports_screen.dart';
import 'support_screen.dart';
import '../utils/app_colors.dart';
import 'notification_screen.dart';
import '../services/mqtt_service.dart';
import '../services/notification_service.dart';
import '../models/notification_model.dart';
import '../providers/auth_provider.dart';

enum RobotState { online, stopped, resumed, emergencyStopped }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    MQTTService.instance.connect();
    NotificationService().init();
  }

  RobotState robotState = RobotState.online;

  double _scale(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return (width / 375).clamp(0.85, 1.3);
  }

  bool get _isOnline =>
      robotState == RobotState.online || robotState == RobotState.resumed;

  String get _statusLabel {
    switch (robotState) {
      case RobotState.online:
      case RobotState.resumed:
        return "ONLINE";
      case RobotState.stopped:
        return "STOPPED";
      case RobotState.emergencyStopped:
        return "E-STOP";
    }
  }

  Color get _statusColor => _isOnline ? AppColors.green : AppColors.red;

  String get _masterRobotId {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    return authProvider.robotId ?? 'SV-001';
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

  void _showNotification(String title, String message, NotificationType type) {
    final color = _getNotificationColor(type);
    _showFeedback(message, color);

    NotificationService().showNotification(
      title: title,
      body: message,
      type: type,
      payload: 'robot_command',
    );
  }

  Color _getNotificationColor(NotificationType type) {
    switch (type) {
      case NotificationType.info:
        return AppColors.blue;
      case NotificationType.warning:
        return AppColors.orange;
      case NotificationType.error:
        return AppColors.red;
      case NotificationType.success:
        return AppColors.green;
    }
  }

  void _onStart() {
    MQTTService.instance.publish("ON");
    setState(() => robotState = RobotState.online);
    _showNotification(
      '✅ Robot Started',
      'Robot $_masterRobotId has started cleaning',
      NotificationType.success,
    );
  }

  void _onStop() {
    MQTTService.instance.publish("OFF");
    setState(() => robotState = RobotState.stopped);
    _showNotification(
      '⏹️ Robot Stopped',
      'Robot $_masterRobotId has stopped cleaning',
      NotificationType.warning,
    );
  }

  // void _onResume() {
  //   MQTTService.instance.publish("ON");
  //   setState(() => robotState = RobotState.resumed);
  //   _showNotification(
  //     '🔄 Robot Resumed',
  //     'Robot $_masterRobotId has resumed cleaning',
  //     NotificationType.info,
  //   );
  // }

  // void _onEmergencyStop() {
  //   MQTTService.instance.publish("OFF");
  //   setState(() => robotState = RobotState.emergencyStopped);
  //   _showNotification(
  //     '⚠️ Emergency Stop',
  //     'Emergency stop activated on Robot $_masterRobotId',
  //     NotificationType.error,
  //   );
  // }

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
                    SizedBox(height: 22 * scale),
                    _buildRobotStatusCard(scale),
                    SizedBox(height: 28 * scale),
                    Text(
                      "Robot Controls",
                      style: TextStyle(
                        fontSize: 22 * scale,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(height: 16 * scale),
                    _buildControlsGrid(scale),
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

  Widget _buildHeader(double scale) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            "SunVibee",
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

  Widget _buildRobotStatusCard(double scale) {
    final masterRobotId = _masterRobotId;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24 * scale),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.orange, AppColors.orangeDark],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.orange.withOpacity(.35),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  "Robot Status",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22 * scale,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(width: 8 * scale),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 12 * scale,
                  vertical: 6 * scale,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8 * scale,
                      height: 8 * scale,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: 6 * scale),
                    Text(
                      "Live",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12 * scale,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 18 * scale),

          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              horizontal: 20 * scale,
              vertical: 16 * scale,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 14 * scale,
                  height: 14 * scale,
                  decoration: BoxDecoration(
                    color: _statusColor,
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: 12 * scale),
                Flexible(
                  child: Text(
                    _statusLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _statusColor,
                      fontSize: 20 * scale,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 18 * scale),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _idCard(
                  scale: scale,
                  icon: Icons.smart_toy_outlined,
                  label: "Master Robot ID",
                  value: masterRobotId,
                ),
              ),
              SizedBox(width: 14 * scale),
              Expanded(
                child: _idCard(
                  scale: scale,
                  icon: Icons.router_outlined,
                  label: "Gateway ID",
                  value: "N/A",
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _idCard({
    required double scale,
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14 * scale),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(6 * scale),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  size: 14 * scale,
                  color: Colors.black87,
                ),
              ),
              SizedBox(width: 8 * scale),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 11 * scale,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 10 * scale),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 15 * scale,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlsGrid(double scale) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _controlCard(
                scale: scale,
                icon: Icons.play_arrow_rounded,
                title: "Start",
                subtitle: "Begin Cleaning",
                background: AppColors.orange,
                onTap: _onStart,
              ),
            ),
            SizedBox(width: 14 * scale),
            Expanded(
              child: _controlCard(
                scale: scale,
                icon: Icons.stop_rounded,
                title: "Stop",
                subtitle: "Stop Operation",
                background: AppColors.navy,
                onTap: _onStop,
              ),
            ),
          ],
        ),
        // Resume and Emergency buttons commented out
        // SizedBox(height: 14 * scale),
        // Row(
        //   children: [
        //     Expanded(
        //       child: _controlCard(
        //         scale: scale,
        //         icon: Icons.autorenew_rounded,
        //         title: "Resume",
        //         subtitle: "Resume Task",
        //         background: AppColors.blue,
        //         onTap: _onResume,
        //       ),
        //     ),
        //     SizedBox(width: 14 * scale),
        //     Expanded(
        //       child: _controlCard(
        //         scale: scale,
        //         icon: Icons.warning_rounded,
        //         title: "Emergency",
        //         subtitle: "Immediate Stop",
        //         background: AppColors.red,
        //         onTap: _onEmergencyStop,
        //       ),
        //     ),
        //   ],
        // ),
      ],
    );
  }

  Widget _controlCard({
    required double scale,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color background,
    required VoidCallback onTap,
  }) {
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(16),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: 16 * scale,
            vertical: 14 * scale,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CircleAvatar(
                    radius: 18 * scale,
                    backgroundColor: Colors.white.withOpacity(0.3),
                    child: Icon(
                      icon,
                      color: Colors.white,
                      size: 20 * scale,
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.white.withOpacity(0.7),
                    size: 14 * scale,
                  ),
                ],
              ),
              SizedBox(height: 12 * scale),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 17 * scale,
                ),
              ),
              SizedBox(height: 2 * scale),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.85),
                  fontSize: 12.5 * scale,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    MQTTService.instance.disconnect();
    super.dispose();
  }
}