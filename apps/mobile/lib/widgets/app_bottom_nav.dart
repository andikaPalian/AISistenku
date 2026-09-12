import 'package:flutter/material.dart';
import '../core/widgets/bouncing_press.dart';

/// Premium Neo-Clean Bottom Navigation Bar matching our official Design System:
/// - Straight flat edge (no border radius) grounded seamlessly to the bottom edge.
/// - Deep obsidian black background (#111111) for maximum contrast against light surfaces.
/// - Comfortably sized icons and center hero AI button ("agak besar dan pas").
/// - High-contrast white active icons with signature vibrant green (#22C55E) indicator dot.
/// - Large 58px vibrant green center hero button with authentic logo, border, and ambient glow.
/// - Full-bleed SafeArea integration so Android/iOS gesture indicators float cleanly on solid black.
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
      decoration: BoxDecoration(
        color: const Color(0xFF111111), // Solid Black matching our official Design System
        border: const Border(
          top: BorderSide(
            color: Color(0xFF1F1F1F), // Subtle crisp hairline divider
            width: 1.0,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 68,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildNavItem(Icons.home_filled, 0),
              _buildNavItem(Icons.storefront_rounded, 1),
              _buildCenterHeroItem(),
              _buildNavItem(Icons.inventory_2_rounded, 3),
              _buildNavItem(Icons.account_balance_wallet_rounded, 4),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, int index) {
    final isSelected = currentIndex == index;
    return BouncingPress(
      scaleFactor: 0.90,
      onTap: () => onTap(index),
      child: SizedBox(
        width: 60,
        height: 60,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              width: 50,
              height: 44,
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.14)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Center(
                child: AnimatedScale(
                  scale: isSelected ? 1.08 : 1.0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    icon,
                    color: isSelected ? Colors.white : const Color(0xFF788292),
                    size: 27,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 3),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              width: isSelected ? 5 : 0,
              height: isSelected ? 5 : 0,
              decoration: const BoxDecoration(
                color: Color(0xFF22C55E), // Signature vibrant green active dot
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCenterHeroItem() {
    return BouncingPress(
      scaleFactor: 0.90,
      onTap: () => onTap(2),
      child: Transform.translate(
        offset: const Offset(0, -8),
        child: Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            color: const Color(0xFF22C55E), // Signature vibrant green
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color(0xFF111111),
              width: 3.5,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF22C55E).withValues(alpha: 0.45),
                blurRadius: 16,
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
                  size: 27,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
