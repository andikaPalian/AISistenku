import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';

/// Stock alert card matching the reference UI:
/// - Categorized styling: Kritis (Red) and Rendah (Amber).
/// - Shows item name, minimum threshold, badge, progress bar with capacity percentage.
/// - Includes a prominent [Restock Cepat] button with high-contrast tactile feedback.
class StockAlertItem extends StatelessWidget {
  final String itemName;
  final String minThresholdText;
  final String remainingText;
  final String capacityText;
  final double progressFraction; // e.g. 0.3 for 30%
  final bool isCritical; // true = Kritis, false = Rendah
  final IconData icon;
  final VoidCallback? onRestock;
  final VoidCallback? onTap;

  const StockAlertItem({
    super.key,
    required this.itemName,
    required this.minThresholdText,
    required this.remainingText,
    required this.capacityText,
    required this.progressFraction,
    required this.isCritical,
    required this.icon,
    this.onRestock,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final themeColor = isCritical ? const Color(0xFFDC2626) : const Color(0xFFD97706);
    final badgeBg = isCritical ? const Color(0xFFFEE2E2) : const Color(0xFFFEF3C7);
    final borderColor = isCritical ? const Color(0xFFFECACA) : const Color(0xFFFDE68A);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Top Row: Icon + Title/Threshold + Status Badge ────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icon Box
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: badgeBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Icon(
                          icon,
                          color: themeColor,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Title & Minimum
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            itemName,
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.darkText,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            minThresholdText,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppColors.mutedText,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Status Pill Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: badgeBg,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        isCritical ? 'Kritis' : 'Rendah',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: themeColor,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // ── Middle Row: Remaining text & Capacity percentage ───────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      remainingText,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: themeColor,
                      ),
                    ),
                    Text(
                      capacityText,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.mutedText,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 6),

                // ── Progress Bar ──────────────────────────────────────────
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: progressFraction.clamp(0.0, 1.0),
                    minHeight: 5,
                    backgroundColor: const Color(0xFFF1F5F9),
                    valueColor: AlwaysStoppedAnimation<Color>(themeColor),
                  ),
                ),

                const SizedBox(height: 12),

                // ── Bottom Action: [Restock Cepat] Button ─────────────────
                Align(
                  alignment: Alignment.centerRight,
                  child: SizedBox(
                    height: 36, // Comfortable hit target
                    child: ElevatedButton.icon(
                      onPressed: onRestock ?? onTap,
                      icon: Icon(
                        Icons.shopping_cart_outlined,
                        size: 14,
                        color: themeColor,
                      ),
                      label: Text(
                        'Restock Cepat',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: themeColor,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: badgeBg,
                        foregroundColor: themeColor,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
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
