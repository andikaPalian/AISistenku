import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/finance_model.dart';

/// Top header section for the Finance Screen.
///
/// Features the profile avatar, store branding ("AIsistenku"),
/// notification bell, page title ("Keuangan"), and period filter chips.
class FinanceHeader extends StatelessWidget {
  final FinancePeriod selectedPeriod;
  final ValueChanged<FinancePeriod> onPeriodChanged;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onProfileTap;

  const FinanceHeader({
    super.key,
    required this.selectedPeriod,
    required this.onPeriodChanged,
    this.onNotificationTap,
    this.onProfileTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Top Brand Bar ─────────────────────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GestureDetector(
              onTap: onProfileTap,
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.tealBackgrounds,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.lightTealBorder),
                    ),
                    padding: const EdgeInsets.all(6),
                    child: Image.asset(
                      'assets/icons/logoAisitenku.png',
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.auto_awesome,
                        color: AppColors.primaryTeal,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'AIsistenku',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.darkText,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: onNotificationTap ??
                  () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Tidak ada notifikasi baru'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
              icon: Stack(
                children: [
                  const Icon(
                    Icons.notifications_none_rounded,
                    color: AppColors.darkText,
                    size: 24,
                  ),
                  Positioned(
                    right: 2,
                    top: 2,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.destructive,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // ── Main Page Title ───────────────────────────────────────────
        Text(
          'Keuangan',
          style: GoogleFonts.poppins(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: AppColors.darkText,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Pantau Uang Bisnis Anda',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: AppColors.mutedText,
          ),
        ),

        const SizedBox(height: 16),

        // ── Period Filter Pills ───────────────────────────────────────
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: FinancePeriod.values.map((period) {
              final isSelected = selectedPeriod == period;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => onPeriodChanged(period),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primaryTeal
                          : AppColors.cardBackground,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primaryTeal
                            : AppColors.lightTealBorder,
                        width: 1.2,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: AppColors.primaryTeal.withValues(alpha: 0.25),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ]
                          : [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.02),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                    ),
                    child: Text(
                      period.label,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w500,
                        color: isSelected ? Colors.white : AppColors.darkText,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
