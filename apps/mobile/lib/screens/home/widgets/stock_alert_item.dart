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
    final badgeBg = isCritical ? const Color(0xFFFEF2F2) : const Color(0xFFFFFBEB);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
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
                        color: const Color(0xFFF1F5F9), // Neutral light slate
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Icon(
                          icon,
                          color: const Color(0xFF64748B), // Neutral icon color
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
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            minThresholdText,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: const Color(0xFF64748B),
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
                        border: Border.all(color: themeColor.withValues(alpha: 0.2)),
                      ),
                      child: Text(
                        isCritical ? 'Kritis' : 'Rendah',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: themeColor,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // ── Middle Row: Remaining text & Capacity percentage ───────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      remainingText,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: themeColor,
                      ),
                    ),
                    Text(
                      capacityText,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // ── Progress Bar ──────────────────────────────────────────
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progressFraction.clamp(0.0, 1.0),
                    minHeight: 6,
                    backgroundColor: const Color(0xFFF1F5F9),
                    valueColor: AlwaysStoppedAnimation<Color>(themeColor),
                  ),
                ),

                const SizedBox(height: 16),

                // ── Bottom Action: [Restock Cepat] Button ─────────────────
                SizedBox(
                  width: double.infinity,
                  height: 38,
                  child: OutlinedButton.icon(
                    onPressed: onRestock ?? onTap,
                    icon: const Icon(
                      Icons.shopping_cart_outlined,
                      size: 16,
                      color: Color(0xFF0F172A),
                    ),
                    label: Text(
                      'Restock Cepat',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF0F172A),
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
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
