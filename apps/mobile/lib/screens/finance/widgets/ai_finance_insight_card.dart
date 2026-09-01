import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/finance_model.dart';

/// Card providing AI-driven business and financial advisory for UMKM owners.
class AiFinanceInsightCard extends StatelessWidget {
  final double grossMargin;
  final VoidCallback? onConsultTap;

  const AiFinanceInsightCard({
    super.key,
    required this.grossMargin,
    this.onConsultTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFF0FDFA),
            Color(0xFFE6FFFA),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF99F6E4),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryTeal.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primaryTeal.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: AppColors.primaryTeal,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'AIsisten Rekomendasi Bisnis',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.darkText,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.successBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Margin: ${grossMargin.toStringAsFixed(1)}%',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.successText,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Laba kotor operasional Anda stabil di ${grossMargin.toStringAsFixed(0)}%. Penjualan Iced Latte meningkat signifikan. Disarankan membuat paket bundling "Kopi + Snack" di jam 15:00-17:00 untuk menaikkan rata-rata transaksi (AOV).',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF334155),
              height: 1.45,
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: onConsultTap,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Konsultasikan dengan AIsisten',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryTeal,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.arrow_forward_rounded,
                  size: 14,
                  color: AppColors.primaryTeal,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
