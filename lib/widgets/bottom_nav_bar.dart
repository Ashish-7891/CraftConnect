import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class BottomNavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int badgeCount;

  const BottomNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    this.badgeCount = 0,
  });
}

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<BottomNavItem> items;

  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(
          top: BorderSide(color: AppTheme.border, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (index) {
              final item = items[index];
              final isSelected = index == currentIndex;

              return InkWell(
                onTap: () => onTap(index),
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Icon(
                            isSelected ? item.activeIcon : item.icon,
                            color: isSelected ? AppTheme.primary : AppTheme.textMuted,
                            size: 24,
                          ),
                          if (item.badgeCount > 0)
                            Positioned(
                              top: -4,
                              right: -8,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: AppTheme.error,
                                  shape: BoxShape.circle,
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 16,
                                  minHeight: 16,
                                ),
                                child: Text(
                                  item.badgeCount > 9 ? '9+' : '${item.badgeCount}',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.label,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected ? AppTheme.primary : AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
