import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'notification_screen.dart';
import 'login_screen.dart';
import '../utils/app_colors.dart';
import '../providers/auth_provider.dart';

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

  Future<void> _makePhoneCall(String phoneNumber) async {
    final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^0-9+]'), '');
    
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: cleanNumber,
    );
    
    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri, mode: LaunchMode.externalApplication);
      } else {
        _showFeedback("Unable to make call", AppColors.red);
      }
    } catch (e) {
      debugPrint('Call error: $e');
      _showFeedback("Error making call", AppColors.red);
    }
  }

  void _showQuickHelpDialog(String title, String description, List<String> steps) {
    final scale = _scale(context);
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.92,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          padding: EdgeInsets.all(20 * scale),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.all(10 * scale),
                    decoration: BoxDecoration(
                      color: AppColors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.help_outline,
                      color: AppColors.orange,
                      size: 24 * scale,
                    ),
                  ),
                  SizedBox(width: 14 * scale),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 20 * scale,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Icons.close,
                      color: Colors.grey.shade600,
                      size: 26 * scale,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              SizedBox(height: 16 * scale),
              // Description
              Container(
                padding: EdgeInsets.all(16 * scale),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  description,
                  style: TextStyle(
                    fontSize: 16 * scale,
                    color: Colors.black87,
                    height: 1.6,
                  ),
                ),
              ),
              SizedBox(height: 18 * scale),
              // Steps
              Text(
                "How to fix:",
                style: TextStyle(
                  fontSize: 18 * scale,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 12 * scale),
              Expanded(
                child: ListView.separated(
                  padding: EdgeInsets.zero,
                  itemCount: steps.length,
                  separatorBuilder: (context, index) => SizedBox(height: 10 * scale),
                  itemBuilder: (context, index) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 26 * scale,
                          height: 26 * scale,
                          decoration: BoxDecoration(
                            color: AppColors.orange.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(13),
                          ),
                          child: Center(
                            child: Text(
                              "${index + 1}",
                              style: TextStyle(
                                fontSize: 14 * scale,
                                fontWeight: FontWeight.bold,
                                color: AppColors.orange,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 12 * scale),
                        Expanded(
                          child: Text(
                            steps[index],
                            style: TextStyle(
                              fontSize: 15 * scale,
                              color: Colors.grey.shade700,
                              height: 1.6,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              SizedBox(height: 16 * scale),
              // Close Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.orange,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 14 * scale),
                    minimumSize: Size(double.infinity, 48 * scale),
                  ),
                  child: Text(
                    "Got it!",
                    style: TextStyle(
                      fontSize: 16 * scale,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFaqDialog() {
    final scale = _scale(context);
    
    final faqs = [
      {
        "question": "How often should I clean my solar panels?",
        "answer": "We recommend cleaning your solar panels every 2-3 months, or more frequently if you live in a dusty area. Regular cleaning ensures maximum energy efficiency."
      },
      {
        "question": "How does the SunVibee robot work?",
        "answer": "SunVibee robot uses advanced sensors and AI to navigate your solar panels, removing dust, dirt, and debris. It's completely autonomous and can be controlled via the app."
      },
      {
        "question": "Is the robot safe for my solar panels?",
        "answer": "Yes! SunVibee robots are designed with soft, non-abrasive brushes and gentle cleaning mechanisms. They're tested to ensure they don't scratch or damage your panels."
      },
      {
        "question": "What happens if the robot gets stuck?",
        "answer": "The robot has built-in sensors to detect obstacles. If it gets stuck, it will stop and notify you through the app so you can assist it."
      },
      {
        "question": "How do I maintain my SunVibee robot?",
        "answer": "Regular maintenance includes cleaning the brushes, checking for debris, and keeping the sensors clean. Refer to the user manual for detailed maintenance instructions."
      },
    ];

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.92,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          padding: EdgeInsets.all(20 * scale),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      "Frequently Asked Questions",
                      style: TextStyle(
                        fontSize: 20 * scale,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Icons.close,
                      color: Colors.grey.shade600,
                      size: 26 * scale,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              SizedBox(height: 16 * scale),
              // FAQ List
              Expanded(
                child: ListView.separated(
                  padding: EdgeInsets.zero,
                  itemCount: faqs.length,
                  separatorBuilder: (context, index) => Divider(
                    height: 1,
                    color: Colors.grey.shade200,
                  ),
                  itemBuilder: (context, index) {
                    final faq = faqs[index];
                    return _buildFaqItem(
                      question: faq["question"] as String,
                      answer: faq["answer"] as String,
                      scale: scale,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFaqItem({
    required String question,
    required String answer,
    required double scale,
  }) {
    bool isExpanded = false;

    return StatefulBuilder(
      builder: (context, setState) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: () {
                setState(() {
                  isExpanded = !isExpanded;
                });
              },
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 14 * scale),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        question,
                        style: TextStyle(
                          fontSize: 16 * scale,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    Icon(
                      isExpanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: AppColors.orange,
                      size: 24 * scale,
                    ),
                  ],
                ),
              ),
            ),
            if (isExpanded)
              Padding(
                padding: EdgeInsets.only(bottom: 14 * scale),
                child: Text(
                  answer,
                  style: TextStyle(
                    fontSize: 15 * scale,
                    color: Colors.grey.shade700,
                    height: 1.6,
                  ),
                ),
              ),
          ],
        );
      },
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
      if (!mounted) return;
      try {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        await authProvider.logout();

        setState(() => _isLoggingOut = false);

        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
          );

          _showFeedback("Logged out successfully", AppColors.green);
        }
      } catch (e) {
        setState(() => _isLoggingOut = false);
        _showFeedback("Error during logout", AppColors.red);
        debugPrint('Logout error: $e');
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
              physics: const BouncingScrollPhysics(),
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
        Flexible(
          child: Text(
            "How can we help you?",
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 26 * scale,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),
        SizedBox(width: 10 * scale),
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
      padding: EdgeInsets.all(18 * scale),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.orange, AppColors.orangeDark],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.orange.withValues(alpha: .25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            flex: 7,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Ã°Å¸â€˜â€¹ We're here to help!",
                  style: TextStyle(
                    fontSize: 18 * scale,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 6 * scale),
                Text(
                  "We're here to help you with your robot anytime.",
                  style: TextStyle(
                    fontSize: 15 * scale,
                    color: Colors.white.withValues(alpha: .9),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 12 * scale),
          Container(
            width: 60 * scale,
            height: 60 * scale,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.support_agent,
              size: 32 * scale,
              color: Colors.white,
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
        "icon": Icons.phone_in_talk_outlined,
        "label": "Call Support",
        "color": AppColors.green,
        "bgColor": const Color(0xFFE5F5E8),
        "phone": "+91 8899778600",
      },
      {
        "icon": Icons.help_outline,
        "label": "FAQ",
        "color": AppColors.navy,
        "bgColor": const Color(0xFFE8E9ED),
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Support Options",
          style: TextStyle(
            fontSize: 20 * scale,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        SizedBox(height: 16 * scale),
        Row(
          children: [
            Expanded(
              child: _supportCard(scale, options[0]),
            ),
            SizedBox(width: 12 * scale),
            Expanded(
              child: _supportCard(scale, options[1]),
            ),
          ],
        ),
      ],
    );
  }

  Widget _supportCard(double scale, Map<String, dynamic> option) {
    return InkWell(
      onTap: () {
        if (option["label"] == "Call Support") {
          _makePhoneCall(option["phone"] as String);
        } else if (option["label"] == "FAQ") {
          _showFaqDialog();
        } else {
          _showFeedback("Opening ${option["label"]}", AppColors.navy);
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: EdgeInsets.all(16 * scale),
        decoration: BoxDecoration(
          color: option["bgColor"],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: option["color"].withValues(alpha: .2), width: 1.5),
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
                    color: Colors.grey.withValues(alpha: .1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                option["icon"] as IconData,
                color: option["color"],
                size: 28 * scale,
              ),
            ),
            SizedBox(height: 10 * scale),
            Text(
              option["label"] as String,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15 * scale,
                fontWeight: FontWeight.w600,
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
      {
        "icon": Icons.wifi_off_outlined,
        "label": "Robot won't connect",
        "description": "If your SunVibee robot is not connecting to the app or network, follow these troubleshooting steps.",
        "steps": [
          "Make sure your robot is powered ON and charged.",
          "Check if your smartphone's Bluetooth and WiFi are turned ON.",
          "Restart the robot by turning it OFF and ON again.",
          "Reset the robot's network settings by pressing the reset button for 5 seconds.",
          "If the issue persists, contact support for further assistance."
        ]
      },
      {
        "icon": Icons.pause_circle_outline,
        "label": "Cleaning stopped",
        "description": "If your robot stops cleaning unexpectedly during a session, here's what you can do.",
        "steps": [
          "Check if the robot has run out of battery. If so, place it on the charging dock.",
          "Check for any physical obstructions like debris or objects blocking the robot.",
          "Ensure the water tank is not empty (if using water-based cleaning).",
          "Check if the robot is stuck on a rough surface or edge.",
          "Restart the cleaning session from the app.",
          "If the problem continues, perform a soft reset by holding the power button."
        ]
      },
      {
        "icon": Icons.battery_alert_outlined,
        "label": "Battery problem",
        "description": "If your robot is experiencing battery issues, follow these steps to diagnose and resolve the problem.",
        "steps": [
          "Check if the robot is properly connected to the charging dock.",
          "Ensure the charging dock is plugged into a working power outlet.",
          "Clean the charging contacts on both the robot and the dock.",
          "Allow the robot to charge for at least 3-4 hours without interruption.",
          "If the battery drains quickly, check if the robot is in power-saving mode.",
          "If the issue persists, the battery may need replacement. Contact support."
        ]
      },
      {
        "icon": Icons.signal_wifi_off,
        "label": "WiFi issue",
        "description": "If your robot is having WiFi connectivity problems, follow these troubleshooting steps.",
        "steps": [
          "Check if your home WiFi network is working properly.",
          "Ensure the robot is within range of your WiFi router.",
          "Restart your WiFi router and modem.",
          "Check if there are too many devices connected to your network.",
          "Try connecting the robot to a 2.4GHz WiFi network (5GHz may not work).",
          "Reset the robot's WiFi settings and reconnect from the app.",
          "If the problem persists, try forgetting the network and reconnecting."
        ]
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Quick Help",
          style: TextStyle(
            fontSize: 20 * scale,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        SizedBox(height: 16 * scale),
        Wrap(
          spacing: 12 * scale,
          runSpacing: 12 * scale,
          children: helpItems.map((item) {
            final screenWidth = MediaQuery.of(context).size.width;
            final padding = 20 * scale;
            final spacing = 12 * scale;
            final cardWidth = (screenWidth - padding * 2 - spacing) / 2;
            
            return SizedBox(
              width: cardWidth.clamp(140, 220),
              child: _quickHelpCard(scale, item),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _quickHelpCard(double scale, Map<String, dynamic> item) {
    return InkWell(
      onTap: () {
        _showQuickHelpDialog(
          item["label"] as String,
          item["description"] as String,
          item["steps"] as List<String>,
        );
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
              size: 22 * scale,
            ),
            SizedBox(width: 10 * scale),
            Expanded(
              child: Text(
                item["label"] as String,
                style: TextStyle(
                  fontSize: 14 * scale,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
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
          side: BorderSide(color: Colors.red.withValues(alpha: .3), width: 1.5),
          padding: EdgeInsets.symmetric(vertical: 16 * scale),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          minimumSize: Size(double.infinity, 48 * scale),
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
                    size: 22 * scale,
                    color: Colors.red,
                  ),
                  SizedBox(width: 10 * scale),
                  Text(
                    "Log Out",
                    style: TextStyle(
                      fontSize: 18 * scale,
                      fontWeight: FontWeight.w600,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}