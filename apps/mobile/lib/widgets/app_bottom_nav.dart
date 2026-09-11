import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/app_colors.dart';
import '../core/widgets/bouncing_press.dart';

/// Custom bottom navigation bar matching the reference design:
/// - 5 destinations: Beranda, POS, AIsistenku (center hero FAB), Stok, Keuangan.
/// - Center hero button with tactile spring feedback and ambient glow aura.
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
      duration: const Duration(milliseconds: 2400),
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
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        border: const Border(
          top: BorderSide(color: AppColors.lightTealBorder, width: 1),
        ),
      ),
      child: SafeArea(
        child: SizedBox(
          height: 64, // Fixed height to allow overflow
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildNavItem(Icons.grid_view_rounded, 'Beranda', 0),
                  _buildNavItem(Icons.storefront_outlined, 'POS', 1),
                  const SizedBox(width: 70), // Space for center FAB
                  _buildNavItem(Icons.archive_outlined, 'Stok', 3),
                  _buildNavItem(Icons.account_balance_wallet_outlined, 'Keuangan', 4),
                ],
              ),
              // Center FAB overlapping
              Positioned(
                top: -20,
                left: 0,
                right: 0,
                child: Center(
                  child: _buildCenterFabItem(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = widget.currentIndex == index;
    return BouncingPress(
      scaleFactor: 0.93,
      onTap: () => widget.onTap(index),
      child: SizedBox(
        width: 58,
        height: 52,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedScale(
              scale: isSelected ? 1.08 : 1.0,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              child: Icon(
                icon,
                color: isSelected ? AppColors.primaryTeal : const Color(0xFF64748B),
                size: 23,
              ),
            ),
            const SizedBox(height: 4),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              style: GoogleFonts.inter(
                fontSize: 10.5,
                color: isSelected ? AppColors.primaryTeal : const Color(0xFF64748B),
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCenterFabItem() {
    return BouncingPress(
      scaleFactor: 0.9,
      onTap: () => widget.onTap(2),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFF1E676A), // Solid dark teal, no gradient
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1E676A).withValues(alpha: 0.3),
                  blurRadius: 8,
                  spreadRadius: 2,
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
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'AISisten',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: const Color(0xFF4B3B36),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

