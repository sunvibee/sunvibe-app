import 'dart:async';
import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import 'notification_screen.dart';
import '../services/mqtt_service.dart';
import '../services/notification_service.dart';
import '../models/notification_model.dart';

/// Current operating state of the robot. Drives the ONLINE/OFFLINE
/// pill on the status card and which SnackBar message is shown.
enum RobotState { offline, online, stopped, resumed, emergencyStopped }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  StreamSubscription<bool>? _statusSub;
  StreamSubscription<MqttMessage>? _mqttSub;
  RobotState robotState = RobotState.offline;

  @override
  void initState() {
    super.initState();
    final connected = MQTTService.instance.isConnected;
    robotState = connected ? RobotState.stopped : RobotState.offline;

    _statusSub = MQTTService.instance.onConnectionStatus.listen((connected) {
      if (!mounted) return;
      setState(() {
        if (!connected) {
          robotState = RobotState.offline;
        } else if (robotState == RobotState.offline) {
          robotState = RobotState.stopped;
        }
      });
    });

    _mqttSub = MQTTService.instance.onMessage.listen((msg) {
      if (!mounted) return;
      final payload = msg.payload.toUpperCase().trim();
      final prevState = robotState;
      setState(() {
        if (payload.contains('OFFLINE') || payload.contains('DISCONNECT')) {
          robotState = RobotState.offline;
        } else if (payload.contains('ON') || payload.contains('RUN') || payload.contains('START')) {
          robotState = RobotState.online;
        } else if (payload.contains('OFF') || payload.contains('STOP')) {
          robotState = RobotState.stopped;
        } else if (robotState == RobotState.offline) {
          robotState = RobotState.stopped;
        }
      });

      if (prevState != robotState) {
        if (robotState == RobotState.online && prevState != RobotState.online) {
          NotificationService().addNotification(
            title: 'Robot Started',
            message: 'Robot cleaning operation is now active.',
            type: NotificationType.success,
          );
        } else if (robotState == RobotState.stopped && prevState == RobotState.online) {
          NotificationService().addNotification(
            title: 'Robot Stopped',
            message: 'Robot cleaning operation was stopped.',
            type: NotificationType.warning,
          );
        } else if (robotState == RobotState.offline && prevState != RobotState.offline) {
          NotificationService().addNotification(
            title: 'Robot Offline',
            message: 'Robot has lost connection and is now offline.',
            type: NotificationType.error,
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _statusSub?.cancel();
    _mqttSub?.cancel();
    super.dispose();
  }

  // Simple responsive scale based on screen width.
  // 375 = standard reference width (iPhone-ish). Clamped so text/icons
  // never blow up or shrink too far on very large/small screens.
  double _scale(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return (width / 375).clamp(0.85, 1.3);
  }

  bool get _isOnline =>
      MQTTService.instance.isConnected &&
      (robotState == RobotState.online || robotState == RobotState.resumed);

  String get _statusLabel {
    if (!MQTTService.instance.isConnected) return "OFFLINE";
    switch (robotState) {
      case RobotState.offline:
        return "OFFLINE";
      case RobotState.online:
        return "ONLINE";
      case RobotState.resumed:
        return "ONLINE";
      case RobotState.stopped:
        return "STOPPED";
      case RobotState.emergencyStopped:
        return "E-STOP";
    }
  }

  Color get _statusColor => _isOnline ? AppColors.green : Colors.red;

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

  void _onStart() {
    if (MQTTService.instance.isConnected) {
      MQTTService.instance.publishToAll('ON');
    }
    setState(() {
      robotState = RobotState.online;
    });
    _showFeedback(
      MQTTService.instance.isConnected
          ? 'Robot Started'
          : 'Robot Started (Local Mode)',
      AppColors.orange,
    );

    NotificationService().addNotification(
      title: 'Robot Started',
      message: 'Robot cleaning operation has been started.',
      type: NotificationType.success,
    );
  }

  void _onStop() {
    if (MQTTService.instance.isConnected) {
      MQTTService.instance.publishToAll('OFF');
    }
    setState(() {
      robotState = RobotState.stopped;
    });
    _showFeedback('Robot Stopped', AppColors.navy);

    NotificationService().addNotification(
      title: 'Robot Stopped',
      message: 'Robot cleaning operation has been stopped.',
      type: NotificationType.warning,
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
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - (20 * scale),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(scale),
                        SizedBox(height: 20 * scale),
                        _buildRobotStatusCard(scale),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 20 * scale),
                        Text(
                          "Robot Controls",
                          style: TextStyle(
                            fontSize: 22 * scale,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        SizedBox(height: 14 * scale),
                        _buildControlsGrid(scale),
                        SizedBox(height: 14 * scale),
                      ],
                    ),
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
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/logo.png',
              height: 38 * scale,
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
            ),
            SizedBox(width: 8 * scale),
            Text(
              "SunVibee",
              style: TextStyle(
                fontSize: 26 * scale,
                fontWeight: FontWeight.bold,
                color: Colors.black,
                letterSpacing: 0.4,
              ),
            ),
          ],
        ),
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
              child: ListenableBuilder(
                listenable: NotificationService(),
                builder: (context, _) {
                  final hasUnread = NotificationService().unreadCount > 0;
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Icon(
                        hasUnread
                            ? Icons.notifications_active_outlined
                            : Icons.notifications_none,
                        size: 24 * scale,
                        color: Colors.black87,
                      ),
                      if (hasUnread)
                        Positioned(
                          right: -1 * scale,
                          top: -1 * scale,
                          child: Container(
                            width: 9 * scale,
                            height: 9 * scale,
                            decoration: BoxDecoration(
                              color: AppColors.red,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  //---------------- Hero Robot Status Card ----------------
  Widget _buildRobotStatusCard(double scale) {
    return Container(
      width: double.infinity,
      height: 290 * scale,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28 * scale),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: _statusColor.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28 * scale),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 1. Hero Photograph Background
            Image.asset(
              'assets/images/robot_hero.jpg',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.orange, AppColors.orangeDark],
                  ),
                ),
                child: Center(
                  child: Icon(Icons.smart_toy, size: 72 * scale, color: Colors.white),
                ),
              ),
            ),

            // 2. High-contrast Gradient Overlay
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.55),
                    Colors.black.withValues(alpha: 0.15),
                    Colors.black.withValues(alpha: 0.85),
                  ],
                  stops: const [0.0, 0.45, 1.0],
                ),
              ),
            ),

            // 3. Card Content (Title, Status Pill, Operating State)
            Padding(
              padding: EdgeInsets.all(20 * scale),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Top Row: Tag / Label + Dynamic Status Pill
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12 * scale,
                          vertical: 6 * scale,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.45),
                          borderRadius: BorderRadius.circular(14 * scale),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.25),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.solar_power_rounded,
                              color: AppColors.orange,
                              size: 16 * scale,
                            ),
                            SizedBox(width: 6 * scale),
                            Text(
                              "Solar Cleaner",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13 * scale,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _statusPill(scale),
                    ],
                  ),

                  // Bottom Info
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _isOnline
                            ? "Cleaning Operation Active"
                            : (robotState == RobotState.stopped
                                ? "Standby • Ready to Clean"
                                : "Robot System Offline"),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18 * scale,
                          fontWeight: FontWeight.bold,
                          shadows: const [
                            Shadow(color: Colors.black87, blurRadius: 6),
                          ],
                        ),
                      ),
                      SizedBox(height: 5 * scale),
                      Row(
                        children: [
                          Container(
                            width: 8 * scale,
                            height: 8 * scale,
                            decoration: BoxDecoration(
                              color: _statusColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          SizedBox(width: 6 * scale),
                          Text(
                            MQTTService.instance.isConnected
                                ? "MQTT Connected • Real-time telemetry"
                                : "Local / Standalone Mode",
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.90),
                              fontSize: 12 * scale,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusPill(double scale) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 14 * scale,
        vertical: 7 * scale,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(16 * scale),
        border: Border.all(
          color: _statusColor.withValues(alpha: 0.65),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: _statusColor.withValues(alpha: 0.25),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10 * scale,
            height: 10 * scale,
            decoration: BoxDecoration(
              color: _statusColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _statusColor,
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          SizedBox(width: 8 * scale),
          Text(
            _statusLabel,
            style: TextStyle(
              color: Colors.white,
              fontSize: 13.5 * scale,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }

  //---------------- Controls Grid ----------------
  Widget _buildControlsGrid(double scale) {
    return Row(
      children: [
        Expanded(
          child: _controlCard(
            scale: scale,
            icon: Icons.play_arrow_rounded,
            title: "Start Cleaning",
            subtitle: "Begin Operation",
            background: AppColors.orange,
            onTap: _onStart,
          ),
        ),
        SizedBox(width: 14 * scale),
        Expanded(
          child: _controlCard(
            scale: scale,
            icon: Icons.stop_rounded,
            title: "Stop Cleaning",
            subtitle: "Stop Operation",
            background: AppColors.navy,
            onTap: _onStop,
          ),
        ),
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
      borderRadius: BorderRadius.circular(22),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Container(
          constraints: BoxConstraints(minHeight: 108 * scale),
          padding: EdgeInsets.all(16 * scale),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 22 * scale,
                backgroundColor: Colors.white,
                child: Icon(icon, color: background, size: 24 * scale),
              ),
              SizedBox(width: 12 * scale),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
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
                    SizedBox(height: 3 * scale),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: .85),
                        fontSize: 12.5 * scale,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
