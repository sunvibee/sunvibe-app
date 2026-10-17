import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  double _getScale(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return (width / 375).clamp(0.85, 1.30);
  }

  @override
  Widget build(BuildContext context) {
    final scale = _getScale(context);
    final bottomInset = MediaQuery.of(context).padding.bottom;

    final items = const [
      {
        "icon": Icons.home_outlined,
        "activeIcon": Icons.home_rounded,
        "label": "Home",
      },
      {
        "icon": Icons.smart_toy_outlined,
        "activeIcon": Icons.smart_toy_rounded,
        "label": "Robot",
      },
      {
        "icon": Icons.headset_mic_outlined,
        "activeIcon": Icons.headset_mic_rounded,
        "label": "Support",
      },
    ];

    // Pop offset for the magnetic dock active tab (rises up above dock)
    final double popOffset = 12.0 * scale;
    final double dockHeight = 66.0 * scale;

    // Bottom margin that sits nicely on gesture-bar and button-nav devices
    final double bottomMargin = bottomInset > 0
        ? (bottomInset * 0.35).clamp(6.0, 14.0) * scale
        : 12.0 * scale;

    return SafeArea(
      top: false,
      child: Align(
        alignment: Alignment.bottomCenter,
        heightFactor: 1.0,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 290 * scale,
          ),
          child: Container(
            margin: EdgeInsets.only(
              left: 12 * scale,
              right: 12 * scale,
              bottom: bottomMargin,
              top: popOffset + (2 * scale),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.bottomCenter,
              children: [
                // 1. Base Magnetic Dock Bar
                Container(
                  height: dockHeight,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28 * scale),
                    border: Border.all(
                      color: Colors.grey.withValues(alpha: 0.16),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 20,
                        spreadRadius: 0,
                        offset: const Offset(0, 6),
                      ),
                      BoxShadow(
                        color: AppColors.orange.withValues(alpha: 0.05),
                        blurRadius: 10,
                        spreadRadius: 0,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),

                // 2. Interactive Navigation Items with Magnetic Pop-up
                SizedBox(
                  height: dockHeight,
                  child: Row(
                    children: List.generate(items.length, (index) {
                      final selected = currentIndex == index;
                      final iconData = (selected
                          ? items[index]["activeIcon"]
                          : items[index]["icon"]) as IconData;
                      final label = items[index]["label"] as String;

                      return Expanded(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => onTap(index),
                          child: Center(
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 260),
                              curve: Curves.easeOutBack,
                              transform: Matrix4.translationValues(
                                0,
                                selected ? -popOffset : 0,
                                0,
                              ),
                              padding: EdgeInsets.symmetric(
                                horizontal: (selected ? 14 : 6) * scale,
                                vertical: (selected ? 6 : 4) * scale,
                              ),
                              decoration: BoxDecoration(
                                color: selected ? Colors.white : Colors.transparent,
                                borderRadius: BorderRadius.circular(20 * scale),
                                border: selected
                                    ? Border.all(
                                        color: Colors.grey.withValues(alpha: 0.16),
                                        width: 1.2,
                                      )
                                    : null,
                                boxShadow: selected
                                    ? [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.12),
                                          blurRadius: 14,
                                          spreadRadius: 1,
                                          offset: const Offset(0, 4),
                                        ),
                                        BoxShadow(
                                          color: AppColors.orange.withValues(alpha: 0.12),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    iconData,
                                    color: selected
                                        ? AppColors.orange
                                        : Colors.grey.shade600,
                                    size: (selected ? 24 : 22) * scale,
                                  ),
                                  SizedBox(height: 2 * scale),
                                  Text(
                                    label,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: (selected ? 11.5 : 11) * scale,
                                      color: selected
                                          ? AppColors.orange
                                          : Colors.grey.shade600,
                                      fontWeight: selected
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                      letterSpacing: selected ? 0.3 : 0.1,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}