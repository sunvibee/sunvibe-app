import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

// class AppColors {
//   static const Color background = Color(0xFFF5F6F8);
//   static const Color card = Color(0xFFF1F1F4);
//   static const Color orange = Color(0xFFFF7A00);
//   static const Color orangeDark = Color(0xFFFF9A2E);
//   static const Color navy = Color(0xFF1E2430);
//   static const Color blue = Color(0xFF1D6FF2);
//   static const Color red = Color(0xFFE23B3B);
//   static const Color green = Color(0xFF23C16B);
// }

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

    final items = const [
      {
        "icon": Icons.home_outlined,
        "activeIcon": Icons.home,
        "label": "Home",
      },
      {
        "icon": Icons.smart_toy_outlined,
        "activeIcon": Icons.smart_toy,
        "label": "Robot",
      },
      {
        "icon": Icons.assessment_outlined,
        "activeIcon": Icons.assessment,
        "label": "Reports",
      },
      {
        "icon": Icons.headset_mic_outlined,
        "activeIcon": Icons.headset_mic,
        "label": "Support",
      },
    ];

    return SafeArea(
      top: false,
      child: Container(
        margin: EdgeInsets.fromLTRB(
          16 * scale,
          0,
          16 * scale,
          12 * scale,
        ),
        padding: EdgeInsets.symmetric(
          horizontal: 4 * scale,
          vertical: 12 * scale,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.18),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: List.generate(items.length, (index) {
            final selected = currentIndex == index;

            return Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => onTap(index),
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 4 * scale),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeInOut,
                        height: 3 * scale,
                        width: selected ? 24 * scale : 0,
                        margin: EdgeInsets.only(bottom: 6 * scale),
                        decoration: BoxDecoration(
                          color: AppColors.orange,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      Icon(
                        selected
                            ? items[index]["activeIcon"] as IconData
                            : items[index]["icon"] as IconData,
                        color: selected ? AppColors.orange : Colors.grey,
                        size: 24 * scale,
                      ),
                      SizedBox(height: 4 * scale),
                      Text(
                        items[index]["label"] as String,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12 * scale,
                          color: selected ? AppColors.orange : Colors.grey,
                          fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
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
    );
  }
}