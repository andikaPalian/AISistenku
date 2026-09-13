import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Modern Unified Action & Success Dialog Modal popup for critical operations
/// (Refund/Batal Transaksi, Restock, Tambah Stok, Stock Opname, Tambah/Edit Menu, Kas Keuangan, Sync, etc.).
///
/// Follows the Neo-Clean design system:
/// - Centered modal with bouncy scale & fade entrance animation
/// - Layered glowing hero badge (Emerald for success, Coral for deletion/error, Amber for alert)
/// - Receipt-style structured summary card with item details & financial impact
/// - Solid obsidian / slate primary button in the thumb zone
/// - Haptic feedback for tactile satisfaction
class ActionSuccessModal extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? itemName;
  final String itemCategory;
  final String? quantityChange;
  final String? financialImpact;
  final String? statusBadge;
  final String primaryButtonText;
  final VoidCallback? onPrimaryTap;
  final String? secondaryButtonText;
  final VoidCallback? onSecondaryTap;
  final IconData itemIcon;
  final IconData heroIcon;
  final Color heroColor;
  final Color heroHaloColor;
  final bool isError;

  const ActionSuccessModal({
    super.key,
    required this.title,
    required this.subtitle,
    this.itemName,
    this.itemCategory = 'Bahan Baku',
    this.quantityChange,
    this.financialImpact,
    this.statusBadge,
    this.primaryButtonText = 'Selesai',
    this.onPrimaryTap,
    this.secondaryButtonText,
    this.onSecondaryTap,
    this.itemIcon = Icons.inventory_2_rounded,
    this.heroIcon = Icons.check_rounded,
    this.heroColor = const Color(0xFF10B981),
    this.heroHaloColor = const Color(0xFFDCFCE7),
    this.isError = false,
  });

  /// Show the modern success modal with smooth overlay transition.
  static Future<void> show(
    BuildContext context, {
    required String title,
    required String subtitle,
    String? itemName,
    String itemCategory = 'Bahan Baku',
    String? quantityChange,
    String? financialImpact,
    String? statusBadge,
    String primaryButtonText = 'Selesai',
    VoidCallback? onPrimaryTap,
    String? secondaryButtonText,
    VoidCallback? onSecondaryTap,
    IconData itemIcon = Icons.inventory_2_rounded,
    IconData heroIcon = Icons.check_rounded,
    Color heroColor = const Color(0xFF10B981),
    Color heroHaloColor = const Color(0xFFDCFCE7),
    bool isError = false,
  }) {
    HapticFeedback.mediumImpact();

    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'SuccessModal',
      barrierColor: Colors.black.withValues(alpha: 0.5),
      transitionDuration: const Duration(milliseconds: 280),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curve = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutBack,
          reverseCurve: Curves.easeInCubic,
        );
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
          child: FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.88, end: 1.0).animate(curve),
              child: child,
            ),
          ),
        );
      },
      pageBuilder: (context, animation, secondaryAnimation) {
        return Center(
          child: ActionSuccessModal(
            title: title,
            subtitle: subtitle,
            itemName: itemName,
            itemCategory: itemCategory,
            quantityChange: quantityChange,
            financialImpact: financialImpact,
            statusBadge: statusBadge,
            primaryButtonText: primaryButtonText,
            onPrimaryTap: onPrimaryTap,
            secondaryButtonText: secondaryButtonText,
            onSecondaryTap: onSecondaryTap,
            itemIcon: itemIcon,
            heroIcon: heroIcon,
            heroColor: isError ? const Color(0xFFEF4444) : heroColor,
            heroHaloColor: isError ? const Color(0xFFFEE2E2) : heroHaloColor,
            isError: isError,
          ),
        );
      },
    );
  }

  /// Convenience helper to show notice, warning, or error modal popup.
  static Future<void> showNotice(
    BuildContext context, {
    required String title,
    required String subtitle,
    String? itemName,
    String itemCategory = 'Perhatian',
    String? detailText,
    String primaryButtonText = 'Mengerti',
    VoidCallback? onPrimaryTap,
    bool isError = true,
    IconData? heroIcon,
  }) {
    HapticFeedback.heavyImpact();

    final Color color = isError ? const Color(0xFFDC2626) : const Color(0xFFF59E0B);
    final Color halo = isError ? const Color(0xFFFEE2E2) : const Color(0xFFFEF3C7);
    final IconData icon = heroIcon ?? (isError ? Icons.error_outline_rounded : Icons.info_outline_rounded);

    return show(
      context,
      title: title,
      subtitle: subtitle,
      itemName: itemName,
      itemCategory: itemCategory,
      quantityChange: detailText,
      primaryButtonText: primaryButtonText,
      onPrimaryTap: onPrimaryTap,
      heroIcon: icon,
      heroColor: color,
      heroHaloColor: halo,
      isError: isError,
      itemIcon: isError ? Icons.warning_amber_rounded : Icons.info_outline_rounded,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.88,
        constraints: const BoxConstraints(maxWidth: 380),
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        padding: const EdgeInsets.fromLTRB(22, 28, 22, 22),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.16),
              blurRadius: 36,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ── Glowing Hero Badge ─────────────────────────────────────
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: heroHaloColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: heroColor.withValues(alpha: 0.25),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Center(
                child: Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        heroColor,
                        heroColor.withValues(alpha: 0.85),
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    heroIcon,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),

            // ── Title & Subtitle ─────────────────────────────────────────
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0F172A),
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.5,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF64748B),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),

            // ── Receipt Summary Card (Optional) ──────────────────────────
            if (itemName != null || quantityChange != null || financialImpact != null || statusBadge != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    if (itemName != null)
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Icon(itemIcon, size: 18, color: const Color(0xFF0F172A)),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  itemCategory,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    color: const Color(0xFF94A3B8),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  itemName!,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF0F172A),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          if (quantityChange != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: isError ? const Color(0xFFFEE2E2) : const Color(0xFFDCFCE7),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isError ? const Color(0xFFFECACA) : const Color(0xFFA7F3D0),
                                ),
                              ),
                              child: Text(
                                quantityChange!,
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: isError ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
                                ),
                              ),
                            ),
                        ],
                      ),

                    // Financial / Status Impact
                    if (financialImpact != null || statusBadge != null) ...[
                      if (itemName != null)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 10),
                          child: Divider(height: 1, color: Color(0xFFE2E8F0)),
                        ),
                      if (statusBadge != null)
                        Padding(
                          padding: EdgeInsets.only(bottom: financialImpact != null ? 8 : 0),
                          child: Row(
                            children: [
                              Container(
                                width: 7,
                                height: 7,
                                decoration: BoxDecoration(
                                  color: isError ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                statusBadge!,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: isError ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (financialImpact != null)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: isError
                                ? const Color(0xFFFEF2F2)
                                : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isError
                                  ? const Color(0xFFFECACA)
                                  : const Color(0xFFE2E8F0),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.receipt_long_rounded,
                                size: 15,
                                color: isError ? const Color(0xFFDC2626) : const Color(0xFF64748B),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  financialImpact!,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: isError ? const Color(0xFF991B1B) : const Color(0xFF334155),
                                    height: 1.3,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ],
                ),
              ),
            const SizedBox(height: 20),

            // ── Primary Action Button ────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  HapticFeedback.selectionClick();
                  Navigator.of(context, rootNavigator: true).pop();
                  onPrimaryTap?.call();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F172A),
                  foregroundColor: Colors.white,
                  elevation: 2,
                  shadowColor: Colors.black.withValues(alpha: 0.2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isError ? Icons.close_rounded : Icons.check_rounded,
                      size: 18,
                      color: isError ? const Color(0xFFF87171) : const Color(0xFF10B981),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      primaryButtonText,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Secondary Action Button (Optional) ───────────────────────
            if (secondaryButtonText != null) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: 40,
                child: TextButton(
                  onPressed: () {
                    Navigator.of(context, rootNavigator: true).pop();
                    onSecondaryTap?.call();
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF64748B),
                  ),
                  child: Text(
                    secondaryButtonText!,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
