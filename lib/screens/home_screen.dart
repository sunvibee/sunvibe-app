import 'dart:async';
import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import 'notification_screen.dart';
import 'cleaning_history_screen.dart';
import '../services/mqtt_service.dart';
import '../services/notification_service.dart';
import '../services/robot_timer_service.dart';
import '../models/notification_model.dart';

/// Current operating state of the robot. Drives the RUNNING/STOPPED
/// indicator on the status card and which feedback message is shown.
enum RobotState { offline, online, stopped, resumed, emergencyStopped }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  StreamSubscription<bool>? _statusSub;
  StreamSubscription<MqttMessage>? _mqttSub;
  RobotState robotState = RobotState.offline;

  late AnimationController _clockAnimController;

  @override
  void initState() {
    super.initState();
    final connected = MQTTService.instance.isConnected;
    robotState = connected ? RobotState.stopped : RobotState.offline;

    _clockAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );

    if (RobotTimerService().isRunning) {
      _clockAnimController.repeat();
    }

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
        } else if (payload.contains('ON') ||
            payload.contains('RUN') ||
            payload.contains('START')) {
          robotState = RobotState.online;
        } else if (payload.contains('OFF') || payload.contains('STOP')) {
          robotState = RobotState.stopped;
        } else if (robotState == RobotState.offline) {
          robotState = RobotState.stopped;
        }
      });

      if (prevState != robotState) {
        if (robotState == RobotState.online && prevState != RobotState.online) {
          final timer = RobotTimerService();
          if (!timer.isRunning) {
            timer.start();
          }
          _clockAnimController.repeat();

          final startTimeStr = timer.formattedStartTime;
          final startTimestamp = timer.startTime ?? DateTime.now();
          NotificationService().addNotification(
            title: 'Robot Started',
            message: 'Robot cleaning operation started at $startTimeStr.',
            type: NotificationType.success,
            timestamp: startTimestamp,
          );
        } else if (robotState == RobotState.stopped &&
            prevState == RobotState.online) {
          _clockAnimController.stop();

          final timer = RobotTimerService();
          final startTimeStr = timer.formattedStartTime;
          final startTimestamp = timer.startTime ??
              DateTime.now().subtract(const Duration(seconds: 1));
          timer.stop();
          final elapsedStr = timer.formattedElapsed;
          final stopTimeStr = timer.formattedStopTime;

          var stopTimestamp = timer.stopTime ?? DateTime.now();
          if (!stopTimestamp
              .isAfter(startTimestamp.add(const Duration(milliseconds: 2)))) {
            stopTimestamp = startTimestamp.add(const Duration(milliseconds: 2));
          }
          final runtimeTimestamp =
              stopTimestamp.subtract(const Duration(milliseconds: 1));

          // Notification 2: Robot Run Time (between Start and Stop)
          NotificationService().addNotification(
            title: 'Robot Run Time',
            message:
                'Total Cleaning Time: $elapsedStr ($startTimeStr - $stopTimeStr).',
            type: NotificationType.info,
            timestamp: runtimeTimestamp,
          );

          // Notification 3: Robot Stopped
          NotificationService().addNotification(
            title: 'Robot Stopped',
            message: 'Robot cleaning operation stopped at $stopTimeStr.',
            type: NotificationType.warning,
            timestamp: stopTimestamp,
          );
        } else if (robotState == RobotState.offline &&
            prevState != RobotState.offline) {
          if (RobotTimerService().isRunning) {
            _clockAnimController.stop();
            RobotTimerService().stop();
          }
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
    _clockAnimController.dispose();
    super.dispose();
  }

  double _scale(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return (width / 375).clamp(0.85, 1.3);
  }

  bool get _isOnline =>
      robotState == RobotState.online || robotState == RobotState.resumed;

  String get _statusLabel {
    if (_isOnline) return "RUNNING";
    if (robotState == RobotState.offline) return "OFFLINE";
    return "STOPPED";
  }

  Color get _statusDotColor =>
      _isOnline ? AppColors.green : AppColors.red;

  bool get _isConnected => MQTTService.instance.isConnected;

  String get _connectionLabel =>
      _isConnected ? "MQTT Connected" : "Local Mode";

  Color get _connectionDotColor =>
      _isConnected ? AppColors.green : Colors.grey.shade500;

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

    final timer = RobotTimerService();
    if (!timer.isRunning) {
      timer.start();
    }
    _clockAnimController.repeat();

    final startTimeStr = timer.formattedStartTime;
    final startTimestamp = timer.startTime ?? DateTime.now();

    _showFeedback(
      MQTTService.instance.isConnected
          ? 'Robot Started'
          : 'Robot Started (Local Mode)',
      AppColors.orange,
    );

    NotificationService().addNotification(
      title: 'Robot Started',
      message: 'Robot cleaning operation started at $startTimeStr.',
      type: NotificationType.success,
      timestamp: startTimestamp,
    );
  }

  void _onStop() {
    if (MQTTService.instance.isConnected) {
      MQTTService.instance.publishToAll('OFF');
    }
    setState(() {
      robotState = RobotState.stopped;
    });

    _clockAnimController.stop();

    final timer = RobotTimerService();
    final startTimeStr = timer.formattedStartTime;
    final startTimestamp = timer.startTime ??
        DateTime.now().subtract(const Duration(seconds: 1));
    timer.stop();
    final elapsedStr = timer.formattedElapsed;
    final stopTimeStr = timer.formattedStopTime;

    _showFeedback('Robot Stopped', AppColors.navy);

    var stopTimestamp = timer.stopTime ?? DateTime.now();
    if (!stopTimestamp
        .isAfter(startTimestamp.add(const Duration(milliseconds: 2)))) {
      stopTimestamp = startTimestamp.add(const Duration(milliseconds: 2));
    }
    final runtimeTimestamp =
        stopTimestamp.subtract(const Duration(milliseconds: 1));

    // Notification 2: Robot Run Time (in between Start and Stop)
    NotificationService().addNotification(
      title: 'Robot Run Time',
      message:
          'Total Cleaning Time: $elapsedStr ($startTimeStr - $stopTimeStr).',
      type: NotificationType.info,
      timestamp: runtimeTimestamp,
    );

    // Notification 3: Robot Stopped
    NotificationService().addNotification(
      title: 'Robot Stopped',
      message: 'Robot cleaning operation stopped at $stopTimeStr.',
      type: NotificationType.warning,
      timestamp: stopTimestamp,
    );
  }

  @override
  Widget build(BuildContext context) {
    final scale = _scale(context);
    final horizontalPadding = (20 * scale).clamp(16, 28).toDouble();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            16 * scale,
            horizontalPadding,
            24 * scale,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(scale),
              SizedBox(height: 14 * scale),
              _buildRobotStatusCard(scale),
              SizedBox(height: 12 * scale),
              _buildStatusAndConnectionCard(scale),
              SizedBox(height: 12 * scale),
              _buildCleaningTimeCard(scale),
              SizedBox(height: 14 * scale),
              _buildControlsGrid(scale),
            ],
          ),
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

  //---------------- Pure Hero Photograph Card ----------------
  Widget _buildRobotStatusCard(double scale) {
    return Container(
      width: double.infinity,
      height: 205 * scale,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24 * scale),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24 * scale),
        child: Image.asset(
          'assets/images/robot_hero.jpg',
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.orange, AppColors.orangeDark],
              ),
            ),
            child: Center(
              child: Icon(
                Icons.smart_toy,
                size: 64 * scale,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  //---------------- Status & Connection Bar Card ----------------
  Widget _buildStatusAndConnectionCard(double scale) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: 16 * scale,
        vertical: 13 * scale,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20 * scale),
        border: Border.all(
          color: Colors.grey.withValues(alpha: 0.15),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Left: Robot Status
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 42 * scale,
                  height: 42 * scale,
                  decoration: BoxDecoration(
                    color: AppColors.orange.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(13 * scale),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.solar_power_rounded,
                      color: AppColors.orange,
                      size: 22 * scale,
                    ),
                  ),
                ),
                SizedBox(width: 10 * scale),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "Status",
                        style: TextStyle(
                          fontSize: 11.5 * scale,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      SizedBox(height: 2 * scale),
                      Row(
                        children: [
                          Container(
                            width: 8 * scale,
                            height: 8 * scale,
                            decoration: BoxDecoration(
                              color: _statusDotColor,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: _statusDotColor.withValues(alpha: 0.4),
                                  blurRadius: 4,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: 6 * scale),
                          Expanded(
                            child: Text(
                              _statusLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13.5 * scale,
                                fontWeight: FontWeight.w800,
                                color: Colors.black87,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Center Divider
          Container(
            height: 38 * scale,
            width: 1,
            color: Colors.grey.withValues(alpha: 0.2),
            margin: EdgeInsets.symmetric(horizontal: 10 * scale),
          ),

          // Right: Connection
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 42 * scale,
                  height: 42 * scale,
                  decoration: BoxDecoration(
                    color: AppColors.navy.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(13 * scale),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.wifi_rounded,
                      color: AppColors.navy,
                      size: 22 * scale,
                    ),
                  ),
                ),
                SizedBox(width: 10 * scale),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "Connection",
                        style: TextStyle(
                          fontSize: 11.5 * scale,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      SizedBox(height: 2 * scale),
                      Row(
                        children: [
                          Container(
                            width: 8 * scale,
                            height: 8 * scale,
                            decoration: BoxDecoration(
                              color: _connectionDotColor,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      _connectionDotColor.withValues(alpha: 0.4),
                                  blurRadius: 4,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: 6 * scale),
                          Expanded(
                            child: Text(
                              _connectionLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13 * scale,
                                fontWeight: FontWeight.w700,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  //---------------- Cleaning Time & History Card ----------------
  Widget _buildCleaningTimeCard(double scale) {
    return ListenableBuilder(
      listenable: RobotTimerService(),
      builder: (context, _) {
        final timer = RobotTimerService();
        final isRunning = timer.isRunning;
        final elapsedStr = timer.formattedElapsed; // 00:00:00

        return Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: 14 * scale,
            vertical: 14 * scale,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20 * scale),
            border: Border.all(
              color: isRunning
                  ? AppColors.orange.withValues(alpha: 0.50)
                  : Colors.grey.withValues(alpha: 0.16),
              width: isRunning ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isRunning
                    ? AppColors.orange.withValues(alpha: 0.10)
                    : Colors.black.withValues(alpha: 0.04),
                blurRadius: isRunning ? 16 : 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Animated Clock Icon with Sweeping Arc
                  SizedBox(
                    width: 50 * scale,
                    height: 50 * scale,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        RotationTransition(
                          turns: _clockAnimController,
                          child: CustomPaint(
                            size: Size(48 * scale, 48 * scale),
                            painter: _ClockArcPainter(
                              sweepAngle: 2.1,
                              color: isRunning
                                  ? AppColors.orange
                                  : Colors.grey.shade300,
                            ),
                          ),
                        ),
                        Container(
                          width: 32 * scale,
                          height: 32 * scale,
                          decoration: BoxDecoration(
                            color: isRunning
                                ? AppColors.orange
                                : AppColors.navy.withValues(alpha: 0.85),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: (isRunning
                                        ? AppColors.orange
                                        : AppColors.navy)
                                    .withValues(alpha: 0.25),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Icon(
                              Icons.access_time_filled_rounded,
                              color: Colors.white,
                              size: 19 * scale,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(width: 12 * scale),

                  // Center: Cleaning Time & Digits
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Cleaning Time",
                          style: TextStyle(
                            fontSize: 12 * scale,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade600,
                            letterSpacing: 0.2,
                          ),
                        ),
                        SizedBox(height: 1 * scale),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            elapsedStr,
                            style: TextStyle(
                              fontSize: 27 * scale,
                              fontWeight: FontWeight.w900,
                              fontFamily: 'monospace',
                              color: isRunning
                                  ? AppColors.orange
                                  : AppColors.navy,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                        SizedBox(height: 2 * scale),
                        Text(
                          "Hours   |   Minutes   |   Seconds",
                          style: TextStyle(
                            fontSize: 9.5 * scale,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade400,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Vertical Divider
                  Container(
                    height: 48 * scale,
                    width: 1,
                    color: Colors.grey.withValues(alpha: 0.2),
                    margin: EdgeInsets.symmetric(horizontal: 8 * scale),
                  ),

                  // Right: History Button
                  Material(
                    color: const Color(0xFFF7F8FA),
                    borderRadius: BorderRadius.circular(14 * scale),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14 * scale),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CleaningHistoryScreen(),
                          ),
                        );
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 10 * scale,
                          vertical: 9 * scale,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14 * scale),
                          border: Border.all(
                            color: Colors.grey.withValues(alpha: 0.18),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: EdgeInsets.all(4 * scale),
                              decoration: BoxDecoration(
                                color: AppColors.orange.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.history_rounded,
                                color: AppColors.orange,
                                size: 16 * scale,
                              ),
                            ),
                            SizedBox(width: 6 * scale),
                            Text(
                              "History",
                              style: TextStyle(
                                fontSize: 13 * scale,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            SizedBox(width: 2 * scale),
                            Icon(
                              Icons.chevron_right_rounded,
                              size: 17 * scale,
                              color: Colors.grey.shade600,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // Bottom timeline synced with mobile clock
              SizedBox(height: 10 * scale),
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(
                  horizontal: 10 * scale,
                  vertical: 6 * scale,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(10 * scale),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.schedule_rounded,
                      size: 13 * scale,
                      color: AppColors.orange,
                    ),
                    SizedBox(width: 5 * scale),
                    Text(
                      "Start: ${timer.formattedStartTime}",
                      style: TextStyle(
                        fontSize: 11 * scale,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    Text(
                      "  •  ",
                      style: TextStyle(
                        fontSize: 11 * scale,
                        color: Colors.grey.shade400,
                      ),
                    ),
                    Text(
                      "Stop: ${timer.formattedStopTime}",
                      style: TextStyle(
                        fontSize: 11 * scale,
                        fontWeight: FontWeight.w600,
                        color: isRunning ? AppColors.orange : Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  //---------------- Control Buttons (Start & Stop) ----------------
  Widget _buildControlsGrid(double scale) {
    return Row(
      children: [
        // Start Cleaning Button
        Expanded(
          child: Material(
            borderRadius: BorderRadius.circular(20 * scale),
            elevation: 2,
            shadowColor: AppColors.orange.withValues(alpha: 0.3),
            child: Ink(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF7A00), Color(0xFFFF4800)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20 * scale),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(20 * scale),
                onTap: _onStart,
                child: Container(
                  constraints: BoxConstraints(minHeight: 76 * scale),
                  padding: EdgeInsets.symmetric(
                    horizontal: 12 * scale,
                    vertical: 12 * scale,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 38 * scale,
                        height: 38 * scale,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Icon(
                            Icons.play_arrow_rounded,
                            color: AppColors.orange,
                            size: 24 * scale,
                          ),
                        ),
                      ),
                      SizedBox(width: 10 * scale),
                      Flexible(
                        child: Text(
                          "Start Cleaning",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15.5 * scale,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),

        SizedBox(width: 12 * scale),

        // Stop Cleaning Button
        Expanded(
          child: Material(
            borderRadius: BorderRadius.circular(20 * scale),
            elevation: 2,
            shadowColor: Colors.black.withValues(alpha: 0.2),
            child: Ink(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF242B38), Color(0xFF141A24)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20 * scale),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(20 * scale),
                onTap: _onStop,
                child: Container(
                  constraints: BoxConstraints(minHeight: 76 * scale),
                  padding: EdgeInsets.symmetric(
                    horizontal: 12 * scale,
                    vertical: 12 * scale,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 38 * scale,
                        height: 38 * scale,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Icon(
                            Icons.stop_rounded,
                            color: AppColors.navy,
                            size: 22 * scale,
                          ),
                        ),
                      ),
                      SizedBox(width: 10 * scale),
                      Flexible(
                        child: Text(
                          "Stop Cleaning",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15.5 * scale,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Custom painter for the animated sweeping arc around the clock dial
class _ClockArcPainter extends CustomPainter {
  final double sweepAngle;
  final Color color;

  _ClockArcPainter({
    required this.sweepAngle,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 2;

    // Faint circular track
    final trackPaint = Paint()
      ..color = color.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawCircle(center, radius, trackPaint);

    // Active arc
    final arcPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -1.5708, // Start at 12 o'clock (-pi/2)
      sweepAngle,
      false,
      arcPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ClockArcPainter oldDelegate) {
    return oldDelegate.sweepAngle != sweepAngle || oldDelegate.color != color;
  }
}
