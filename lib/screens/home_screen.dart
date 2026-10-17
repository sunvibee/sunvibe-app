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
    if (!MQTTService.instance.isConnected) {
      _showFeedback('Cannot start: Robot / MQTT is offline', Colors.red);
      return;
    }
    MQTTService.instance.publishToAll('ON');
    setState(() { robotState = RobotState.online; });
    _showFeedback('Robot Started', AppColors.orange);

    NotificationService().addNotification(
      title: 'Robot Started',
      message: 'Robot cleaning operation has been started.',
      type: NotificationType.success,
    );
  }

  void _onStop() {
    if (!MQTTService.instance.isConnected) {
      _showFeedback('Robot is offline', Colors.red);
      return;
    }
    MQTTService.instance.publishToAll('OFF');
    setState(() { robotState = RobotState.stopped; });
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

  //---------------- Robot Status Card ----------------
  Widget _buildRobotStatusCard(double scale) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(22 * scale),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.orange, AppColors.orangeDark],
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: AppColors.orange.withValues(alpha: .35),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Robot Status",
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white,
              fontSize: 22 * scale,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 18 * scale),
          LayoutBuilder(
            builder: (context, cardConstraints) {
              // Stack image + info vertically on very narrow cards,
              // side-by-side otherwise — keeps everything visible
              // and never overflows on small devices.
              final isNarrow = cardConstraints.maxWidth < 300;
              final robotImage = _robotImage(scale, isNarrow);
              final infoColumn = Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _statusPill(scale),
                ],
              );

              if (isNarrow) {
                return Column(
                  children: [
                    robotImage,
                    SizedBox(height: 16 * scale),
                    infoColumn,
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 5, child: robotImage),
                  SizedBox(width: 16 * scale),
                  Expanded(flex: 6, child: infoColumn),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _robotImage(double scale, bool isNarrow) {
    return SizedBox(
      height: (isNarrow ? 150 : 190) * scale,
      width: double.infinity,
      child: Image.asset(
        'assets/images/robot.png',
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          // Placeholder shown until you add assets/images/robot.png
          // (and register it under `flutter: assets:` in pubspec.yaml).
          return Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.smart_toy,
              size: 72 * scale,
              color: Colors.white.withValues(alpha: .9),
            ),
          );
        },
      ),
    );
  }

  Widget _statusPill(double scale) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 18 * scale,
        vertical: 14 * scale,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 14 * scale,
            height: 14 * scale,
            decoration: BoxDecoration(
              color: _statusColor,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 10 * scale),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                _statusLabel,
                maxLines: 1,
                style: TextStyle(
                  color: _statusColor,
                  fontSize: 20 * scale,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  //---------------- Controls Grid ----------------
  Widget _buildControlsGrid(double scale) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
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
