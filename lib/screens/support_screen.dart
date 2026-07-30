import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'home_screen.dart';
import 'notification_screen.dart';
import 'robots_screen.dart';
import 'reports_screen.dart';
import 'login_screen.dart'; // Import LoginScreen
import '../utils/app_colors.dart';
import '../providers/auth_provider.dart'; // Import AuthProvider

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {

  bool _isLoggingOut = false;

  double _scale(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return (width / 375).clamp(0.85, 1.3);
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


  Future<void> _handleLogout() async {
    setState(() => _isLoggingOut = true);

    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            Icon(Icons.logout_outlined, color: Colors.red),
            SizedBox(width: 10),
            Text("Logout"),
          ],
        ),
        content: const Text("Are you sure you want to logout?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Logout"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        // Clear session using AuthProvider
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        await authProvider.logout();

        // Verify session is cleared
        final isLoggedIn = await authProvider.checkSession();
        print('After logout - isLoggedIn: $isLoggedIn'); // Debug log

        setState(() => _isLoggingOut = false);

        if (mounted) {
          // Navigate to login screen and clear all routes
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false, // Remove all previous routes
          );

          _showFeedback("Logged out successfully", AppColors.green);
        }
      } catch (e) {
        setState(() => _isLoggingOut = false);
        _showFeedback("Error during logout", AppColors.red);
        print('Logout error: $e');
      }
    } else {
      setState(() => _isLoggingOut = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scale = _scale(context);
    final horizontalPadding = (20 * scale).clamp(16, 30).toDouble();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                18 * scale,
                horizontalPadding,
                20 * scale,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(scale),
                    SizedBox(height: 20 * scale),
                    _buildWelcomeCard(scale),
                    SizedBox(height: 24 * scale),
                    _buildSupportOptions(scale),
                    SizedBox(height: 24 * scale),
                    _buildQuickHelpSection(scale),
                    SizedBox(height: 24 * scale),
                    _buildLogoutButton(scale),
                    SizedBox(height: 10 * scale),
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
            "How can we help you?",
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 24 * scale,
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

  //---------------- Welcome Card ----------------
  Widget _buildWelcomeCard(double scale) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20 * scale),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.orange, AppColors.orangeDark],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.orange.withOpacity(.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            flex: 6,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "👋 We're here to help!",
                  style: TextStyle(
                    fontSize: 18 * scale,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 8 * scale),
                Text(
                  "We're here to help you with your robot anytime.",
                  style: TextStyle(
                    fontSize: 14 * scale,
                    color: Colors.white.withOpacity(.9),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 4,
            child: Container(
              height: 80 * scale,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.support_agent,
                size: 40 * scale,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  //---------------- Support Options ----------------
  Widget _buildSupportOptions(double scale) {
    final options = [
      {
        "icon": Icons.confirmation_number_outlined,
        "label": "Raise a Ticket",
        "color": AppColors.blue,
        "bgColor": const Color(0xFFE3F0FF),
      },
      {
        "icon": Icons.chat_bubble_outline,
        "label": "Chat with Support",
        "color": AppColors.orange,
        "bgColor": const Color(0xFFFFF0E5),
      },
      {
        "icon": Icons.call_outlined,
        "label": "Call Support",
        "color": AppColors.green,
        "bgColor": const Color(0xFFE5F5E8),
      },
      {
        "icon": Icons.help_outline,
        "label": "FAQ",
        "color": AppColors.navy,
        "bgColor": const Color(0xFFE8E9ED),
      },
      {
        "icon": Icons.description_outlined,
        "label": "My Tickets",
        "color": const Color(0xFF9B59B6),
        "bgColor": const Color(0xFFF3E8F7),
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Support Options",
          style: TextStyle(
            fontSize: 18 * scale,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        SizedBox(height: 14 * scale),
        LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 360;

            if (isNarrow) {
              return Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: _supportCard(scale, options[0])),
                      SizedBox(width: 12 * scale),
                      Expanded(child: _supportCard(scale, options[1])),
                    ],
                  ),
                  SizedBox(height: 12 * scale),
                  Row(
                    children: [
                      Expanded(child: _supportCard(scale, options[2])),
                      SizedBox(width: 12 * scale),
                      Expanded(child: _supportCard(scale, options[3])),
                    ],
                  ),
                  SizedBox(height: 12 * scale),
                  Row(
                    children: [
                      Expanded(child: _supportCard(scale, options[4])),
                      const Expanded(child: SizedBox()),
                    ],
                  ),
                ],
              );
            }

            return Wrap(
              spacing: 12 * scale,
              runSpacing: 12 * scale,
              children: options.map((option) {
                return SizedBox(
                  width: (constraints.maxWidth - 24 * scale) / 3,
                  child: _supportCard(scale, option),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _supportCard(double scale, Map<String, dynamic> option) {
    return InkWell(
      onTap: () {
        _showFeedback("Opening ${option["label"]}", AppColors.navy);
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: EdgeInsets.all(16 * scale),
        decoration: BoxDecoration(
          color: option["bgColor"],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: option["color"].withOpacity(.2), width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(12 * scale),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                option["icon"] as IconData,
                color: option["color"],
                size: 24 * scale,
              ),
            ),
            SizedBox(height: 10 * scale),
            Text(
              option["label"] as String,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13 * scale,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  //---------------- Quick Help Section ----------------
  Widget _buildQuickHelpSection(double scale) {
    final helpItems = [
      {"icon": Icons.wifi_off_outlined, "label": "Robot won't connect"},
      {"icon": Icons.pause_circle_outline, "label": "Cleaning stopped"},
      {"icon": Icons.battery_alert_outlined, "label": "Battery problem"},
      {"icon": Icons.signal_wifi_off, "label": "WiFi issue"},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Quick Help",
          style: TextStyle(
            fontSize: 18 * scale,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        SizedBox(height: 14 * scale),
        LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 340;

            if (isNarrow) {
              return Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: _quickHelpCard(scale, helpItems[0])),
                      SizedBox(width: 10 * scale),
                      Expanded(child: _quickHelpCard(scale, helpItems[1])),
                    ],
                  ),
                  SizedBox(height: 10 * scale),
                  Row(
                    children: [
                      Expanded(child: _quickHelpCard(scale, helpItems[2])),
                      SizedBox(width: 10 * scale),
                      Expanded(child: _quickHelpCard(scale, helpItems[3])),
                    ],
                  ),
                ],
              );
            }

            return Wrap(
              spacing: 10 * scale,
              runSpacing: 10 * scale,
              children: helpItems.map((item) {
                return SizedBox(
                  width: (constraints.maxWidth - 30 * scale) / 2,
                  child: _quickHelpCard(scale, item),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _quickHelpCard(double scale, Map<String, dynamic> item) {
    return InkWell(
      onTap: () {
        _showFeedback("Opening: ${item["label"]}", AppColors.navy);
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: 14 * scale,
          vertical: 16 * scale,
        ),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(
              item["icon"] as IconData,
              color: AppColors.orange,
              size: 20 * scale,
            ),
            SizedBox(width: 10 * scale),
            Expanded(
              child: Text(
                item["label"] as String,
                style: TextStyle(
                  fontSize: 13 * scale,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Colors.grey.shade400,
              size: 18 * scale,
            ),
          ],
        ),
      ),
    );
  }

  //---------------- Logout Button ----------------
  Widget _buildLogoutButton(double scale) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: _isLoggingOut ? null : _handleLogout,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: Colors.red.withOpacity(.3)),
          padding: EdgeInsets.symmetric(vertical: 16 * scale),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: _isLoggingOut
            ? SizedBox(
                width: 24 * scale,
                height: 24 * scale,
                child: const CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.logout_outlined,
                    size: 20 * scale,
                    color: Colors.red,
                  ),
                  SizedBox(width: 10 * scale),
                  Text(
                    "Log Out",
                    style: TextStyle(
                      fontSize: 16 * scale,
                      fontWeight: FontWeight.w500,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
