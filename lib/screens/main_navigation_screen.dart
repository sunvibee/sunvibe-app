import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'home_screen.dart';
import 'robots_screen.dart';
import 'support_screen.dart';
import '../widgets/bottom_nav_bar.dart';
import '../services/mqtt_service.dart';
import '../utils/app_colors.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  /// Programmatically switch the active navigation tab from any child widget/screen.
  /// 0 = Home, 1 = Robot, 2 = Support
  static void switchTab(BuildContext context, int index) {
    final state = context.findAncestorStateOfType<_MainNavigationScreenState>();
    state?.changeTab(index);
  }

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int currentIndex = 0;
  bool _isExiting = false;

  void changeTab(int index) {
    if (index >= 0 && index < pages.length && index != currentIndex) {
      setState(() {
        currentIndex = index;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    MQTTService.instance.connect();
  }

  @override
  void dispose() {
    MQTTService.instance.disconnect();
    super.dispose();
  }

  final List<Widget> pages = const [
    HomeScreen(),
    RobotsScreen(),
    SupportScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        if (didPop) return;

        if (_isExiting) return;

        if (currentIndex == 0) {
          _isExiting = true;

          final shouldExit = await showDialog<bool>(
            context: context,
            barrierDismissible: false,
            builder: (context) {
              return _buildExitDialog(context);
            },
          );

          _isExiting = false;

          if (shouldExit == true) {
            SystemNavigator.pop();
          }
        } else {
          setState(() {
            currentIndex = 0;
          });
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: IndexedStack(
          index: currentIndex.clamp(0, pages.length - 1),
          children: pages,
        ),
        bottomNavigationBar: BottomNavBar(
          currentIndex: currentIndex,
          onTap: (index) {
            setState(() {
              currentIndex = index;
            });
          },
        ),
      ),
    );
  }

  Widget _buildExitDialog(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      elevation: 0,
      backgroundColor: Colors.white,
      child: Container(
        padding: EdgeInsets.all(24 * scale),
        constraints: BoxConstraints(maxWidth: 340 * scale),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon Circle
            Container(
              width: 72 * scale,
              height: 72 * scale,
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.exit_to_app_rounded,
                color: Colors.red,
                size: 36 * scale,
              ),
            ),
            SizedBox(height: 20 * scale),

            // Title
            Text(
              "Exit SunVibee?",
              style: TextStyle(
                fontSize: 22 * scale,
                fontWeight: FontWeight.bold,
                color: Colors.black,
                letterSpacing: 0.5,
              ),
            ),
            SizedBox(height: 10 * scale),

            // Description
            Text(
              "Are you sure you want to close the app?\nYour robot will continue cleaning.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15 * scale,
                color: Colors.grey.shade600,
                height: 1.5,
              ),
            ),
            SizedBox(height: 24 * scale),

            // Divider
            Divider(height: 1, color: Colors.grey.shade200),
            SizedBox(height: 16 * scale),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 14 * scale),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      backgroundColor: Colors.grey.shade50,
                    ),
                    child: Text(
                      "Cancel",
                      style: TextStyle(
                        fontSize: 16 * scale,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12 * scale),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 14 * scale),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      elevation: 0,
                    ),
                    child: Text(
                      "Exit",
                      style: TextStyle(
                        fontSize: 16 * scale,
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
  }
}
