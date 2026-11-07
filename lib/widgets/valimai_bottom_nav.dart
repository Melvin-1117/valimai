import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ValimaiBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const ValimaiBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: ValimaiColors.surfaceContainer,
        border: Border(
          top: BorderSide(color: ValimaiColors.cardBorder, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x59000000),
            offset: Offset(0, -4),
            blurRadius: 24,
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.home_outlined, Icons.home, 'Home'),
              _buildNavItem(1, Icons.fitness_center_outlined, Icons.fitness_center, 'Workouts'),
              _buildNavItem(2, Icons.calendar_today_outlined, Icons.calendar_today, 'Schedule'),
              _buildNavItem(3, Icons.history_outlined, Icons.history, 'History'),
              _buildNavItem(4, Icons.person_outline, Icons.person, 'Profile'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData outlineIcon, IconData filledIcon, String label) {
    final bool isSelected = currentIndex == index;
    final Color color = isSelected ? ValimaiColors.primaryContainer : ValimaiColors.secondary;

    return Expanded(
      child: InkWell(
        onTap: () => onTap(index),
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? filledIcon : outlineIcon,
              color: color,
              size: 22,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Manrope',
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: color,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

