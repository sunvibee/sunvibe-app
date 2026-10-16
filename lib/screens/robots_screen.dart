import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import '../utils/app_colors.dart';
import 'notification_screen.dart';
import '../providers/auth_provider.dart';
import 'dart:async';
import '../services/mqtt_service.dart';
import '../services/api_service.dart';

class RobotsScreen extends StatefulWidget {
  const RobotsScreen({super.key});

  @override
  State<RobotsScreen> createState() => _RobotsScreenState();
}

class _RobotsScreenState extends State<RobotsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _robotIdController = TextEditingController();
  final FocusNode _robotIdFocusNode = FocusNode();
  final TextEditingController _robotPasswordController = TextEditingController();
  final FocusNode _robotPasswordFocusNode = FocusNode();

  List<Map<String, dynamic>> robots = [];
  bool _isConnecting = false;
  bool _isLoading = true;
  String? _masterRobotId;
  StreamSubscription<MqttMessage>? _mqttSub;
  StreamSubscription<bool>? _mqttStatusSub;
  Timer? _heartbeatTimer;

  int get totalRobots => robots.length;
  int get onlineRobots => MQTTService.instance.isConnected
      ? robots.where((r) => r['online'] == true).length
      : 0;
  int get offlineRobots => totalRobots - onlineRobots;
  int get alerts => robots.where((r) => r['alerts'] == true).length;

  double _scale(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return (width / 375).clamp(0.85, 1.3);
  }

  @override
  void initState() {
    super.initState();
    _loadRobots();
    _getMasterRobotId();
    _mqttSub = MQTTService.instance.onMessage.listen(_handleMqttMessage);
    _mqttStatusSub = MQTTService.instance.onConnectionStatus.listen((connected) {
      if (!mounted) return;
      setState(() {
        if (!connected) {
          for (final r in robots) {
            r['online'] = false;
            r['cleaning'] = false;
          }
        }
      });
    });

    // Check periodically: if MQTT is down or no ping received for > 45s, mark offline
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (!mounted) return;
      final now = DateTime.now();
      bool changed = false;
      for (final r in robots) {
        if (r['online'] == true) {
          if (!MQTTService.instance.isConnected) {
            r['online'] = false;
            r['cleaning'] = false;
            changed = true;
          } else if (r['lastActive'] != null) {
            final lastActive = DateTime.tryParse(r['lastActive'].toString());
            if (lastActive != null && now.difference(lastActive).inSeconds > 45) {
              r['online'] = false;
              r['cleaning'] = false;
              changed = true;
            }
          }
        }
      }
      if (changed) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _heartbeatTimer?.cancel();
    _mqttStatusSub?.cancel();
    _mqttSub?.cancel();
    _searchController.dispose();
    _robotIdController.dispose();
    _robotIdFocusNode.dispose();
    _robotPasswordController.dispose();
    _robotPasswordFocusNode.dispose();
    super.dispose();
  }

  void _getMasterRobotId() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    _masterRobotId = authProvider.robotId;
  }

  // Cache key scoped to the current user — prevents cross-account data leaks.
  String _cacheKey() {
    final userId = Provider.of<AuthProvider>(context, listen: false).userId;
    return 'robots_$userId';
  }

  Future<void> _saveRobots() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
        _cacheKey(),
        robots.map((r) => jsonEncode(r)).toList(),
      );
    } catch (e) {
      print('Error saving robots: $e');
    }
  }

  Future<void> _loadRobots() async {
    setState(() { _isLoading = true; });
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final cacheKey = 'robots_${auth.userId}';

    try {
      // API is the authoritative source — returns only this user's robots.
      final rows = await ApiService(token: auth.token).getRobots();
      final loaded = rows.map((r) => <String, dynamic>{
        'id':         r['robot_uid'] as String,
        'name':       r['robot_uid'] as String,
        'online':     false,
        'battery':    85,
        'cleaning':   false,
        'alerts':     false,
        'isMaster':   false,
        'lastActive': DateTime.now().toIso8601String(),
      }).toList();

      setState(() { robots = loaded; });
      for (final r in loaded) {
        MQTTService.instance.subscribeToRobot(r['id'] as String);
      }
      await _saveRobots();

      // Remove old non-scoped key left over from previous builds.
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('robots');
    } catch (_) {
      // API unreachable — fall back to the user-scoped local cache.
      try {
        final prefs = await SharedPreferences.getInstance();
        final cached = prefs.getStringList(cacheKey);
        if (cached != null) {
          final loaded = cached
              .map((j) {
                final map = jsonDecode(j) as Map<String, dynamic>;
                map['online'] = false;
                map['cleaning'] = false;
                return map;
              })
              .toList();
          setState(() { robots = loaded; });
          for (final r in loaded) {
            MQTTService.instance.subscribeToRobot(r['id'] as String);
          }
        }
      } catch (_) {}
    } finally {
      setState(() { _isLoading = false; });
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

  void _showAddRobotDialog() {
    _robotIdController.clear();
    _robotPasswordController.clear();
    bool isPasswordVisible = false;
    
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        Future.delayed(Duration(milliseconds: 300), () {
          _robotIdFocusNode.requestFocus();
        });
        
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final mediaQuery = MediaQuery.of(context);
            final scale = (mediaQuery.size.width / 375).clamp(0.85, 1.15);

            return Dialog(
              insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: 400,
                  maxHeight: mediaQuery.size.height * 0.85,
                ),
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(20 * scale),
                  physics: const ClampingScrollPhysics(),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: EdgeInsets.all(12 * scale),
                        decoration: BoxDecoration(
                          color: AppColors.orange.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.smart_toy,
                          color: AppColors.orange,
                          size: 36 * scale,
                        ),
                      ),
                      SizedBox(height: 12 * scale),
                      Text(
                        "Add New Robot",
                        style: TextStyle(
                          fontSize: 20 * scale,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(height: 6 * scale),
                      Text(
                        "Enter the Robot ID and Password to connect",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13 * scale,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      SizedBox(height: 16 * scale),
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
                          textInputAction: TextInputAction.next,
                          onSubmitted: (_) {
                            _robotPasswordFocusNode.requestFocus();
                          },
                          decoration: InputDecoration(
                            hintText: "Enter Robot ID (e.g. SolarCleaner01)",
                            hintStyle: TextStyle(fontSize: 14 * scale),
                            prefixIcon: Icon(Icons.precision_manufacturing, color: AppColors.orange, size: 22 * scale),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 14 * scale, vertical: 12 * scale),
                          ),
                          style: TextStyle(fontSize: 15 * scale),
                        ),
                      ),
                      SizedBox(height: 10 * scale),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: TextField(
                          controller: _robotPasswordController,
                          focusNode: _robotPasswordFocusNode,
                          obscureText: !isPasswordVisible,
                          textInputAction: TextInputAction.done,
                          decoration: InputDecoration(
                            hintText: "Enter Robot Password",
                            hintStyle: TextStyle(fontSize: 14 * scale),
                            prefixIcon: Icon(Icons.lock_outline, color: AppColors.orange, size: 22 * scale),
                            suffixIcon: IconButton(
                              icon: Icon(
                                isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                                color: Colors.grey.shade600,
                                size: 20 * scale,
                              ),
                              onPressed: () {
                                setDialogState(() {
                                  isPasswordVisible = !isPasswordVisible;
                                });
                              },
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 14 * scale, vertical: 12 * scale),
                          ),
                          style: TextStyle(fontSize: 15 * scale),
                          onSubmitted: (_) => _connectRobot(context),
                        ),
                      ),
                      SizedBox(height: 18 * scale),
                      Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: () {
                                _robotIdFocusNode.unfocus();
                                _robotPasswordFocusNode.unfocus();
                                Navigator.pop(context);
                              },
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.symmetric(vertical: 12 * scale),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: Text(
                                "Cancel",
                                style: TextStyle(
                                  fontSize: 14 * scale,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 10 * scale),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _isConnecting ? null : () => _connectRobot(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.orange,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(vertical: 12 * scale),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: _isConnecting
                                  ? SizedBox(
                                      width: 18 * scale,
                                      height: 18 * scale,
                                      child: const CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Text(
                                      "Connect Robot",
                                      style: TextStyle(
                                        fontSize: 14 * scale,
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
              ),
            );
          },
        );
      },
    ).then((_) {
      _robotIdFocusNode.unfocus();
      _robotPasswordFocusNode.unfocus();
      _robotIdController.clear();
      _robotPasswordController.clear();
    });
  }

  Future<void> _connectRobot(BuildContext context) async {
    final robotId = _robotIdController.text.trim();
    final password = _robotPasswordController.text.trim();
    
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

    if (password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Please enter Robot Password"),
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

    setState(() { _isConnecting = true; });

    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      final api = ApiService(token: token);

      // Validate ID and Password in the pre-registered robot registry
      final info = await api.validateRobot(robotId, password: password);
      final canonicalId = info['robot_uid'] as String? ?? robotId;

      await api.registerRobot(robotUid: canonicalId, robotName: canonicalId, password: password);
      MQTTService.instance.subscribeToRobot(canonicalId);

      final newRobot = {
        'id': canonicalId,
        'name': canonicalId,
        'online': false,
        'battery': 85,
        'cleaning': false,
        'alerts': false,
        'isMaster': false,
        'lastActive': DateTime.now().toIso8601String(),
      };

      setState(() {
        robots.add(newRobot);
        _isConnecting = false;
      });

      await _saveRobots();
      _robotIdFocusNode.unfocus();
      _robotPasswordFocusNode.unfocus();
      if (mounted) Navigator.pop(context);
      _showFeedback('Robot $canonicalId connected!', AppColors.green);
    } on ApiException catch (e) {
      setState(() { _isConnecting = false; });
      _showFeedback(e.message, AppColors.red);
    } catch (_) {
      setState(() { _isConnecting = false; });
      _showFeedback('Connection failed. Check your Robot ID & Password.', AppColors.red);
    }
  }

  void _removeRobot(int index) {
    final robotName = robots[index]['name'];
    final isMaster = robots[index]['isMaster'] ?? false;
    
    if (isMaster) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Cannot remove Master Robot"),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    
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
              final robotId = robots[index]['id'] as String;
              MQTTService.instance.unsubscribeFromRobot(robotId);
              try {
                final token = Provider.of<AuthProvider>(context, listen: false).token;
                await ApiService(token: token).removeRobot(robotId);
              } catch (_) {}
              setState(() { robots.removeAt(index); });
              await _saveRobots();
              Navigator.pop(context);
              _showFeedback('$robotName removed', AppColors.red);
            },
            child: Text("Remove"),
          ),
        ],
      ),
    );
  }

  void _handleMqttMessage(MqttMessage msg) {
    final parts = msg.topic.split('/');
    String? robotId;
    if (parts.length >= 3) {
      robotId = parts[1];
    } else if (robots.length == 1) {
      robotId = robots.first['id']?.toString();
    }
    if (robotId == null) return;
    final payload = msg.payload.toUpperCase().trim();
    final idx = robots.indexWhere((r) => r['id'].toString().toUpperCase() == robotId!.toUpperCase());
    if (idx == -1) return;

    setState(() {
      if (payload.contains('OFFLINE') || payload.contains('DISCONNECT')) {
        robots[idx]['online'] = false;
        robots[idx]['cleaning'] = false;
      } else {
        // Valid status/telemetry message received from ESP32
        robots[idx]['online'] = true;
        robots[idx]['lastActive'] = DateTime.now().toIso8601String();
        if (payload.contains('ON') || payload.contains('RUN') || payload.contains('START')) {
          robots[idx]['cleaning'] = true;
        } else if (payload.contains('OFF') || payload.contains('STOP')) {
          robots[idx]['cleaning'] = false;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final scale = _scale(context);
    final horizontalPadding = (20 * scale).clamp(16, 30).toDouble();

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

    // Ensure master robot is always in the list
    if (_masterRobotId != null && !robots.any((r) => r['id'] == _masterRobotId)) {
      final masterRobot = {
        'id': _masterRobotId,
        'name': 'SV-$_masterRobotId',
        'online': false,
        'battery': 85,
        'cleaning': false,
        'alerts': false,
        'isMaster': true,
        'lastActive': DateTime.now().toIso8601String(),
      };
      robots.insert(0, masterRobot);
      _saveRobots();
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

  Widget _buildRobotList(double scale) {
    final filteredRobots = _searchController.text.isEmpty
        ? robots
        : robots.where((r) => 
            r['id'].toString().toLowerCase().contains(
              _searchController.text.toLowerCase()
            )
          ).toList();

    if (filteredRobots.isEmpty) {
      return Container(
        padding: EdgeInsets.symmetric(vertical: 40 * scale),
        child: Column(
          children: [
            Icon(
              Icons.smart_toy_outlined,
              size: 80 * scale,
              color: Colors.grey.shade300,
            ),
            SizedBox(height: 16 * scale),
            Text(
              "No robots connected",
              style: TextStyle(
                fontSize: 16 * scale,
                color: Colors.grey.shade600,
              ),
            ),
          ],
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
    final isOnline = (robot['online'] == true) && MQTTService.instance.isConnected;
    final battery = robot['battery'] ?? 0;
    final isCleaning = robot['cleaning'] ?? false;
    final isMaster = robot['isMaster'] ?? false;

    return Container(
      margin: EdgeInsets.only(bottom: 12 * scale),
      padding: EdgeInsets.all(16 * scale),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isMaster 
            ? Border.all(color: AppColors.orange, width: 2)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
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
              color: isOnline ? AppColors.green.withOpacity(0.1) : Colors.grey.shade100,
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
                Row(
                  children: [
                    Text(
                      robot['name'] ?? 'Robot',
                      style: TextStyle(
                        fontSize: 16 * scale,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    if (isMaster) ...[
                      SizedBox(width: 8 * scale),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8 * scale,
                          vertical: 2 * scale,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          "MASTER",
                          style: TextStyle(
                            fontSize: 8 * scale,
                            color: AppColors.orange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
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
                          color: AppColors.blue.withOpacity(0.1),
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
          if (!isMaster)
            GestureDetector(
              onTap: () => _removeRobot(index),
              child: Container(
                padding: EdgeInsets.all(8 * scale),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
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