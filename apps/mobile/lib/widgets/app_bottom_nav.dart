import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

/// Custom bottom navigation bar with a center elevated FAB for AIsisten.
///
/// Matches the reference design with 5 tabs: Home, POS, AIsisten (center),
/// Stock, and Finance. The center AIsisten button has a breathing glow
/// animation to emphasize it as the hero feature.
class AppBottomNav extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;

  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  State<AppBottomNav> createState() => _AppBottomNavState();
}

class _AppBottomNavState extends State<AppBottomNav>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.home_rounded, 'Home', 0),
              _buildNavItem(Icons.point_of_sale_rounded, 'POS', 1),
              _buildFabItem(),
              _buildNavItem(Icons.inventory_2_rounded, 'Stock', 3),
              _buildNavItem(
                  Icons.account_balance_wallet_rounded, 'Finance', 4),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = widget.currentIndex == index;
    return GestureDetector(
      onTap: () => widget.onTap(index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 56,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withOpacity(0.1)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                icon,
                color: isSelected ? AppColors.primary : AppColors.mutedText,
                size: 24,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: isSelected ? AppColors.primary : AppColors.mutedText,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFabItem() {
    return GestureDetector(
      onTap: () => widget.onTap(2),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Transform.translate(
            offset: const Offset(0, -12),
            child: AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                final glowOpacity = 0.15 + (_pulseAnimation.value * 0.2);
                final glowSpread = 2.0 + (_pulseAnimation.value * 6.0);
                final glowBlur = 12.0 + (_pulseAnimation.value * 10.0);
                return Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(glowOpacity),
                        blurRadius: glowBlur,
                        spreadRadius: glowSpread,
                      ),
                    ],
                  ),
                  child: child,
                );
              },
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.accent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Image.asset(
                  'assets/icons/iconAisistenku.png',
                  width: 34,
                  height: 34,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          Transform.translate(
            offset: const Offset(0, -8),
            child: Text(
              'AIsisten',
              style: TextStyle(
                fontSize: 10,
                color: widget.currentIndex == 2
                    ? AppColors.primary
                    : AppColors.mutedText,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
