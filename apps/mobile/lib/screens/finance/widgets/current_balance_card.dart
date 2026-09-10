import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/finance_model.dart';

/// Hero card showing the current balance, last updated indicator,
/// and quick cashflow health badge.
class CurrentBalanceCard extends StatelessWidget {
  final double balance;
  final double netProfit;
  final VoidCallback? onTap;

  const CurrentBalanceCard({
    super.key,
    required this.balance,
    required this.netProfit,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isProfitable = netProfit >= 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFF0FDFA),
            Color(0xFFE6FFFA),
            Color(0xFFF8FFFE),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppColors.lightTealBorder,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryTeal.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SALDO KAS UTAMA',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.mutedText,
                  letterSpacing: 1.2,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isProfitable
                      ? AppColors.successBg
                      : AppColors.dangerBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isProfitable
                        ? AppColors.successGreen.withValues(alpha: 0.3)
                        : AppColors.destructive.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isProfitable
                          ? Icons.trending_up_rounded
                          : Icons.trending_down_rounded,
                      size: 14,
                      color: isProfitable
                          ? AppColors.successText
                          : AppColors.dangerText,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isProfitable ? 'Surplus' : 'Defisit',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isProfitable
                            ? AppColors.successText
                            : AppColors.dangerText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // ── Big Formatted Balance ─────────────────────────────────
          Text(
            FinanceRepository.formatRupiah(balance),
            style: GoogleFonts.poppins(
              fontSize: 30,
              fontWeight: FontWeight.w700,
              color: AppColors.darkText,
              letterSpacing: -0.5,
              height: 1.15,
            ),
          ),

          const SizedBox(height: 12),

          // ── Update Time & Subtitle ────────────────────────────────
          Row(
            children: [
              const Icon(
                Icons.update_rounded,
                size: 15,
                color: AppColors.mutedText,
              ),
              const SizedBox(width: 5),
              Text(
                'Diperbarui hari ini',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: AppColors.mutedText,
                ),
              ),
              const Spacer(),
              Text(
                'Laba Bersih: ${FinanceRepository.formatRupiah(netProfit)}',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isProfitable
                      ? AppColors.successText
                      : AppColors.dangerText,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
