import 'package:flutter/material.dart';
import '../widgets/bottom_nav_bar.dart';
import 'home_screen.dart';
import '../utils/app_colors.dart';
import 'notification_screen.dart';

class RobotsScreen extends StatefulWidget {
  const RobotsScreen({super.key});

  @override
  State<RobotsScreen> createState() => _RobotsScreenState();
}

class _RobotsScreenState extends State<RobotsScreen> {
  int selectedIndex = 1; // Robots tab active on this screen
  final TextEditingController _searchController = TextEditingController();

  // Replace with real data from your backend/state layer.
  final int totalRobots = 0;
  final int onlineRobots = 0;
  final int offlineRobots = 0;
  final int alerts = 0;

  double _scale(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return (width / 375).clamp(0.85, 1.3);
  }

  @override
  void dispose() {
    _searchController.dispose();
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

  void _onNavTap(int index) {
    if (index == selectedIndex) return;

    setState(() {
      selectedIndex = index;
    });

    // Navigate to different screens
    if (index == 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } else if (index == 1) {
      // Already on Robots
    } else if (index == 2) {
      // Navigate to Reports Screen
      // Navigator.pushReplacement(
      //   context,
      //   MaterialPageRoute(builder: (_) => const ReportsScreen()),
      // );
    } else if (index == 3) {
      // Navigate to Support Screen
      // Navigator.pushReplacement(
      //   context,
      //   MaterialPageRoute(builder: (_) => const SupportScreen()),
      // );
    }
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
                    _buildEmptyState(scale),
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
      bottomNavigationBar: BottomNavBar(
        currentIndex: selectedIndex,
        onTap: _onNavTap,
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
        onPressed: () =>
            _showFeedback("Opening robot pairing…", AppColors.blue),
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
              onTap: () {
                // Navigate to Add Robot Screen
                _showFeedback("Add a new robot", AppColors.blue);
              },
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
