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

    // Compute comfortable bottom spacing that settles well on devices with/without gesture bar
    final double bottomMargin = bottomInset > 0
        ? (bottomInset * 0.4).clamp(6.0, 16.0) * scale
        : 14.0 * scale;

    return SafeArea(
      top: false,
      child: Align(
        alignment: Alignment.bottomCenter,
        heightFactor: 1.0,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 440 * scale,
          ),
          child: Container(
            margin: EdgeInsets.only(
              left: 18 * scale,
              right: 18 * scale,
              bottom: bottomMargin,
              top: 4 * scale,
            ),
            padding: EdgeInsets.symmetric(
              horizontal: 10 * scale,
              vertical: 8 * scale,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30 * scale),
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
                  color: AppColors.orange.withValues(alpha: 0.06),
                  blurRadius: 10,
                  spreadRadius: 0,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: List.generate(items.length, (index) {
                final selected = currentIndex == index;

                return Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(22 * scale),
                    onTap: () => onTap(index),
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 4 * scale),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 220),
                            curve: Curves.easeOutCubic,
                            padding: EdgeInsets.symmetric(
                              horizontal: (selected ? 16 : 8) * scale,
                              vertical: 5 * scale,
                            ),
                            decoration: BoxDecoration(
                              color: selected
                                  ? AppColors.orange.withValues(alpha: 0.12)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(16 * scale),
                            ),
                            child: Icon(
                              selected
                                  ? items[index]["activeIcon"] as IconData
                                  : items[index]["icon"] as IconData,
                              color: selected
                                  ? AppColors.orange
                                  : Colors.grey.shade500,
                              size: 24 * scale,
                            ),
                          ),
                          SizedBox(height: 3 * scale),
                          AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 220),
                            curve: Curves.easeOutCubic,
                            style: TextStyle(
                              fontSize: 12 * scale,
                              color: selected
                                  ? AppColors.orange
                                  : Colors.grey.shade600,
                              fontWeight: selected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              letterSpacing: selected ? 0.3 : 0.1,
                            ),
                            child: Text(
                              items[index]["label"] as String,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}