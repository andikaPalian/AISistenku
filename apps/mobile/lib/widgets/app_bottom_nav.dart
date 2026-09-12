import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/widgets/bouncing_press.dart';

/// Custom bottom navigation bar matching the reference design:
/// - 5 destinations: Beranda, POS, AIsistenku (center hero FAB), Stok, Keuangan.
/// - Center hero button with tactile spring feedback and ambient glow aura.
class AppBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.transparent, // Background transparent so it floats
      padding: const EdgeInsets.only(left: 24, right: 24, bottom: 32), // Floating margin
      child: Container(
        height: 72,
        decoration: BoxDecoration(
          color: const Color(0xFF111111), // Solid Black Pill
          borderRadius: BorderRadius.circular(36), // Fully rounded pill
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF111111).withValues(alpha: 0.3),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildNavItem(Icons.home_filled, 0),
            _buildNavItem(Icons.storefront_rounded, 1),
            _buildCenterFabItem(),
            _buildNavItem(Icons.inventory_2_rounded, 3),
            _buildNavItem(Icons.account_balance_wallet_rounded, 4),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, int index) {
    final isSelected = currentIndex == index;
    return BouncingPress(
      scaleFactor: 0.85,
      onTap: () => onTap(index),
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: isSelected ? Colors.white.withValues(alpha: 0.1) : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: AnimatedScale(
            scale: isSelected ? 1.1 : 1.0,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            child: Icon(
              icon,
              color: isSelected ? Colors.white : const Color(0xFF6B7280),
              size: 26,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCenterFabItem() {
    return BouncingPress(
      scaleFactor: 0.85,
      onTap: () => onTap(2),
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: AppColors.secondary, // Vibrant Green
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.secondary.withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Image.asset(
              'assets/icons/logoAisitenku.png',
              color: Colors.white,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.auto_awesome_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

