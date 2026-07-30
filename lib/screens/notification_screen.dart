import 'package:flutter/material.dart';

// Reuses the same AppColors defined in home_screen.dart so all
// screens stay visually consistent.
// import 'home_screen.dart';
import '../utils/app_colors.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  double _scale(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return (width / 375).clamp(0.85, 1.3);
  }

  @override
  Widget build(BuildContext context) {
    final scale = _scale(context);
    final horizontalPadding = (20 * scale).clamp(16, 30).toDouble();

    // Swap this for real data — when the list is non-empty, show a
    // ListView of notification tiles instead of the empty state below.
    final bool hasNotifications = false;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(context, scale, hasNotifications),
            Expanded(
              child: hasNotifications
                  ? const SizedBox.shrink() // TODO: notification list
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        return SingleChildScrollView(
                          padding: EdgeInsets.symmetric(
                            horizontal: horizontalPadding,
                          ),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: constraints.maxHeight,
                            ),
                            child: Center(
                              child: _buildEmptyState(scale),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  //---------------- Top Bar ----------------
  Widget _buildTopBar(BuildContext context, double scale, bool hasNotifications) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14 * scale, vertical: 10 * scale),
      child: Row(
        children: [
          Material(
            color: Colors.white,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => Navigator.of(context).maybePop(),
              child: Padding(
                padding: EdgeInsets.all(8 * scale),
                child: Icon(Icons.arrow_back_ios_new, size: 18 * scale, color: Colors.black87),
              ),
            ),
          ),
          Expanded(
            child: Text(
              "Notifications",
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 18 * scale,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
          _markAllReadButton(context, scale, hasNotifications),
        ],
      ),
    );
  }

  Widget _markAllReadButton(BuildContext context, double scale, bool enabled) {
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: IgnorePointer(
        ignoring: !enabled,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12 * scale, vertical: 8 * scale),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(20),
          ),
          child: InkWell(
            onTap: () {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  const SnackBar(content: Text("All notifications marked as read")),
                );
            },
            child: Text(
              "Mark All Read",
              style: TextStyle(fontSize: 12 * scale, color: Colors.grey.shade600),
            ),
          ),
        ),
      ),
    );
  }

  //---------------- Empty State ----------------
  Widget _buildEmptyState(double scale) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 24 * scale),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _bellIllustration(scale),
          SizedBox(height: 28 * scale),
          Text(
            "No Notifications",
            style: TextStyle(
              fontSize: 22 * scale,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          SizedBox(height: 8 * scale),
          Text(
            "You're all caught up!",
            style: TextStyle(fontSize: 15 * scale, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _bellIllustration(double scale) {
    final size = 190 * scale;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.orange.withOpacity(.14),
                  AppColors.orange.withOpacity(.02),
                ],
              ),
            ),
          ),
          // Faint decorative sparkles to echo the reference art.
          Positioned(
            top: size * 0.14,
            left: size * 0.12,
            child: Icon(Icons.add, size: 12 * scale, color: AppColors.orange.withOpacity(.35)),
          ),
          Positioned(
            top: size * 0.18,
            right: size * 0.14,
            child: Icon(Icons.add, size: 10 * scale, color: AppColors.orange.withOpacity(.3)),
          ),
          Positioned(
            bottom: size * 0.18,
            left: size * 0.16,
            child: Icon(Icons.circle, size: 5 * scale, color: AppColors.orange.withOpacity(.3)),
          ),
          Positioned(
            bottom: size * 0.20,
            right: size * 0.12,
            child: Icon(Icons.circle, size: 5 * scale, color: AppColors.orange.withOpacity(.3)),
          ),
          Icon(
            Icons.notifications_none_rounded,
            size: size * 0.42,
            color: AppColors.orange,
          ),
        ],
      ),
    );
  }
}