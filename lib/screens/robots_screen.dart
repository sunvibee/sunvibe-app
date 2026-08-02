import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../utils/app_colors.dart';
import 'notification_screen.dart';
import '../services/notification_service.dart';
import '../models/notification_model.dart';

class RobotsScreen extends StatefulWidget {
  const RobotsScreen({super.key});

  @override
  State<RobotsScreen> createState() => _RobotsScreenState();
}

class _RobotsScreenState extends State<RobotsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _robotIdController = TextEditingController();
  final FocusNode _robotIdFocusNode = FocusNode();

  List<Map<String, dynamic>> robots = [];
  bool _isConnecting = false;
  bool _isLoading = true;

  int get totalRobots => robots.length;
  int get onlineRobots => robots.where((r) => r['online'] == true).length;
  int get offlineRobots => robots.where((r) => r['online'] == false).length;
  int get alerts => robots.where((r) => r['alerts'] == true).length;

  double _scale(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return (width / 375).clamp(0.85, 1.3);
  }

  @override
  void initState() {
    super.initState();
    _loadRobots();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _robotIdController.dispose();
    _robotIdFocusNode.dispose();
    super.dispose();
  }

  // Save robots to SharedPreferences
  Future<void> _saveRobots() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> robotJsonList = robots.map((robot) => jsonEncode(robot)).toList();
      await prefs.setStringList('robots', robotJsonList);
    } catch (e) {
      debugPrint('Error saving robots: $e');
    }
  }

  // Load robots from SharedPreferences
  Future<void> _loadRobots() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String>? robotJsonList = prefs.getStringList('robots');
      
      if (robotJsonList != null) {
        setState(() {
          robots = robotJsonList
              .map((jsonString) => jsonDecode(jsonString) as Map<String, dynamic>)
              .toList();
        });
      }
    } catch (e) {
      debugPrint('Error loading robots: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
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
      payload: 'robot_connection',
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

  void _showAddRobotDialog() {
    _robotIdController.clear();
    
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        Future.delayed(Duration(milliseconds: 300), () {
          _robotIdFocusNode.requestFocus();
        });
        
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Container(
            padding: EdgeInsets.all(24),
            width: MediaQuery.of(context).size.width * 0.9,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Animated Icon
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.orange.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.animation,
                    color: AppColors.orange,
                    size: 40,
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  "Add New Robot",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  "Enter the Robot ID to connect",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                SizedBox(height: 20),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: TextField(
                    controller: _robotIdController,
                    focusNode: _robotIdFocusNode,
                    autofocus: true,
                    textInputAction: TextInputAction.done,
                    decoration: InputDecoration(
                      hintText: "Enter Robot ID",
                      prefixIcon: Icon(Icons.precision_manufacturing, color: AppColors.orange),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    ),
                    style: TextStyle(fontSize: 16),
                    onSubmitted: (_) => _connectRobot(context),
                  ),
                ),
                SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          _robotIdFocusNode.unfocus();
                          Navigator.pop(context);
                        },
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          "Cancel",
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isConnecting ? null : () => _connectRobot(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.orange,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: _isConnecting
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                "Connect Robot",
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    ).then((_) {
      _robotIdFocusNode.unfocus();
      _robotIdController.clear();
    });
  }

  Future<void> _connectRobot(BuildContext context) async {
    final robotId = _robotIdController.text.trim();
    
    if (robotId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Please enter Robot ID"),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          duration: Duration(milliseconds: 1500),
        ),
      );
      return;
    }

    if (robots.any((r) => r['id'] == robotId)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Robot $robotId is already connected"),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          duration: Duration(milliseconds: 1500),
        ),
      );
      return;
    }

    setState(() {
      _isConnecting = true;
    });

    await Future.delayed(Duration(milliseconds: 800));

    final newRobot = {
      'id': robotId,
      'name': 'SV-$robotId',
      'online': true,
      'battery': 85,
      'cleaning': false,
      'alerts': false,
      'lastActive': DateTime.now().toIso8601String(),
    };

    setState(() {
      robots.add(newRobot);
      _isConnecting = false;
    });

    await _saveRobots();

    _showNotification(
      'Ã¢Å“â€¦ Robot Connected',
      'Robot $robotId has been successfully connected!',
      NotificationType.success,
    );

    if (!context.mounted) return;
    _robotIdFocusNode.unfocus();
    Navigator.pop(context);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Ã¢Å“â€¦ Robot $robotId connected successfully!"),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _removeRobot(int index) {
    final robotName = robots[index]['name'];
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        title: Text(
          "Remove Robot",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.red,
          ),
        ),
        content: Text(
          "Are you sure you want to remove ${robots[index]['name']}?",
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              setState(() {
                robots.removeAt(index);
              });
              await _saveRobots();
              if (!context.mounted) return;
              Navigator.pop(context);
              
              _showNotification(
                'Ã°Å¸â€”â€˜Ã¯Â¸Â Robot Removed',
                '$robotName has been removed',
                NotificationType.warning,
              );
            },
            child: Text("Remove"),
          ),
        ],
      ),
    );
  }

  void _toggleRobotStatus(int index) {
    setState(() {
      robots[index]['online'] = !robots[index]['online'];
      if (robots[index]['online']) {
        _showNotification(
          'Ã°Å¸Å¸Â¢ Robot Online',
          '${robots[index]['name']} is now online',
          NotificationType.success,
        );
      } else {
        _showNotification(
          'Ã°Å¸â€Â´ Robot Offline',
          '${robots[index]['name']} is now offline',
          NotificationType.warning,
        );
      }
    });
    _saveRobots();
  }

  @override
  Widget build(BuildContext context) {
    final scale = _scale(context);
    final horizontalPadding = (20 * scale).clamp(16, 30).toDouble();
    final hasRobots = robots.isNotEmpty;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(
            color: AppColors.orange,
          ),
        ),
      );
    }

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
                    hasRobots 
                        ? _buildRobotList(scale)
                        : _buildEmptyState(scale),
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

  Widget _buildSearchBar(double scale) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: .12),
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
        ],
      ),
    );
  }

  Widget _buildStatsRow(double scale) {
    final stats = [
      _StatData(
        icon: Icons.smart_toy_outlined,
        iconBg: const Color(0xFFDCEAFB),
        iconColor: const Color(0xFF1D6FF2),
        label: "Total Robots",
        value: totalRobots,
        valueColor: Colors.black,
      ),
      _StatData(
        icon: Icons.wifi,
        iconBg: const Color(0xFFDCF5E4),
        iconColor: AppColors.green,
        label: "Online",
        value: onlineRobots,
        valueColor: AppColors.green,
      ),
      _StatData(
        icon: Icons.wifi_off,
        iconBg: const Color(0xFFFBDCDC),
        iconColor: AppColors.red,
        label: "Offline",
        value: offlineRobots,
        valueColor: AppColors.red,
      ),
      _StatData(
        icon: Icons.warning_amber_rounded,
        iconBg: const Color(0xFFFBEACB),
        iconColor: AppColors.orange,
        label: "Alerts",
        value: alerts,
        valueColor: AppColors.orange,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 340;

        if (isNarrow) {
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
            color: Colors.grey.withValues(alpha: .10),
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

  Widget _buildEmptyState(double scale) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 30 * scale),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated Robot Illustration
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 200 * scale,
                height: 200 * scale,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.orange.withValues(alpha: 0.1),
                      AppColors.orange.withValues(alpha: 0.05),
                    ],
                  ),
                ),
              ),
              Icon(
                Icons.smart_toy_outlined,
                size: 100 * scale,
                color: AppColors.orange.withValues(alpha: 0.4),
              ),
              Positioned(
                top: 30 * scale,
                right: 30 * scale,
                child: Icon(
                  Icons.add,
                  size: 20 * scale,
                  color: AppColors.orange.withValues(alpha: 0.3),
                ),
              ),
              Positioned(
                bottom: 30 * scale,
                left: 30 * scale,
                child: Icon(
                  Icons.add,
                  size: 16 * scale,
                  color: AppColors.orange.withValues(alpha: 0.3),
                ),
              ),
              Positioned(
                top: 50 * scale,
                left: 20 * scale,
                child: Container(
                  width: 6 * scale,
                  height: 6 * scale,
                  decoration: BoxDecoration(
                    color: AppColors.orange.withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Positioned(
                bottom: 50 * scale,
                right: 20 * scale,
                child: Container(
                  width: 6 * scale,
                  height: 6 * scale,
                  decoration: BoxDecoration(
                    color: AppColors.orange.withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 24 * scale),
          Text(
            "No Robots Connected",
            style: TextStyle(
              fontSize: 22 * scale,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          SizedBox(height: 10 * scale),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 30 * scale),
            child: Text(
              "Add your first robot to monitor, manage and keep it running smoothly.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14 * scale,
                color: Colors.grey.shade600,
                height: 1.5,
              ),
            ),
          ),
          SizedBox(height: 30 * scale),
          _connectRobotButton(scale),
        ],
      ),
    );
  }

  Widget _connectRobotButton(double scale) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.orange,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: 16 * scale),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 4,
        ),
        onPressed: _showAddRobotDialog,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.link, size: 22 * scale),
            SizedBox(width: 10 * scale),
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

  Widget _buildRobotList(double scale) {
    final filteredRobots = _searchController.text.isEmpty
        ? robots
        : robots.where((r) => 
            r['id'].toString().toLowerCase().contains(
              _searchController.text.toLowerCase()
            )
          ).toList();

    if (filteredRobots.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 20 * scale),
        child: Center(
          child: Text(
            "No robots found",
            style: TextStyle(
              fontSize: 16 * scale,
              color: Colors.grey.shade600,
            ),
          ),
        ),
      );
    }

    return Column(
      children: filteredRobots.asMap().entries.map((entry) {
        final index = entry.key;
        final robot = entry.value;
        return _buildRobotCard(scale, robot, index);
      }).toList(),
    );
  }

  Widget _buildRobotCard(double scale, Map<String, dynamic> robot, int index) {
    final isOnline = robot['online'] ?? false;
    final battery = robot['battery'] ?? 0;
    final isCleaning = robot['cleaning'] ?? false;

    return Container(
      margin: EdgeInsets.only(bottom: 12 * scale),
      padding: EdgeInsets.all(16 * scale),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50 * scale,
            height: 50 * scale,
            decoration: BoxDecoration(
              color: isOnline ? AppColors.green.withValues(alpha: 0.1) : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              isCleaning ? Icons.cleaning_services : Icons.smart_toy,
              color: isOnline ? AppColors.green : Colors.grey.shade400,
              size: 28 * scale,
            ),
          ),
          SizedBox(width: 14 * scale),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  robot['name'] ?? 'Robot',
                  style: TextStyle(
                    fontSize: 16 * scale,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 4 * scale),
                Row(
                  children: [
                    Container(
                      width: 8 * scale,
                      height: 8 * scale,
                      decoration: BoxDecoration(
                        color: isOnline ? AppColors.green : Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: 6 * scale),
                    Text(
                      isOnline ? 'Online' : 'Offline',
                      style: TextStyle(
                        fontSize: 12 * scale,
                        color: isOnline ? AppColors.green : Colors.red,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(width: 12 * scale),
                    Icon(
                      Icons.battery_std,
                      size: 14 * scale,
                      color: battery > 50 ? AppColors.green : Colors.orange,
                    ),
                    SizedBox(width: 4 * scale),
                    Text(
                      '$battery%',
                      style: TextStyle(
                        fontSize: 12 * scale,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    if (isCleaning) ...[
                      SizedBox(width: 12 * scale),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8 * scale,
                          vertical: 3 * scale,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.blue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          "Cleaning",
                          style: TextStyle(
                            fontSize: 10 * scale,
                            color: AppColors.blue,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Row(
            children: [
              GestureDetector(
                onTap: () => _toggleRobotStatus(index),
                child: Container(
                  padding: EdgeInsets.all(8 * scale),
                  decoration: BoxDecoration(
                    color: isOnline ? AppColors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isOnline ? Icons.wifi : Icons.wifi_off,
                    color: isOnline ? AppColors.green : Colors.red,
                    size: 18 * scale,
                  ),
                ),
              ),
              SizedBox(width: 8 * scale),
              GestureDetector(
                onTap: () => _removeRobot(index),
                child: Container(
                  padding: EdgeInsets.all(8 * scale),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.delete_outline,
                    color: Colors.red,
                    size: 18 * scale,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAddNewRobot(double scale) {
    return Align(
      alignment: Alignment.centerRight,
      child: Column(
        children: [
          Material(
            color: AppColors.orange,
            shape: const CircleBorder(),
            elevation: 4,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: _showAddRobotDialog,
              child: Padding(
                padding: EdgeInsets.all(16 * scale),
                child: Icon(Icons.add, color: Colors.white, size: 28 * scale),
              ),
            ),
          ),
          SizedBox(height: 8 * scale),
          Text(
            "Add New Robot",
            style: TextStyle(
              fontSize: 13 * scale,
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
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