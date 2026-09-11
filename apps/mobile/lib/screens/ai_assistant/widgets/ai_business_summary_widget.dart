import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/finance_model.dart';

/// Mini KPI card rendered inside AI chat messages for quick financial overview.
class AiBusinessSummaryWidget extends StatelessWidget {
  final num revenue;
  final num profit;
  final String bestSeller;

  const AiBusinessSummaryWidget({
    super.key,
    required this.revenue,
    required this.profit,
    required this.bestSeller,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildRow('PENDAPATAN KOTOR', FinanceRepository.formatRupiah(revenue),
              isBold: true, color: AppColors.darkText),
          const Divider(height: 16, color: Color(0xFFF1F5F9)), // Clean slate divider
          _buildRow(
            'ESTIMASI LABA',
            '+ ${FinanceRepository.formatRupiah(profit)}',
            isBold: true,
            color: AppColors.successGreen,
          ),
          const Divider(height: 16, color: Color(0xFFF1F5F9)),
          _buildRow(
            'MENU TERLARIS',
            bestSeller,
            isBold: true,
            color: AppColors.darkText,
          ),
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value,
      {bool isBold = false, Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF64748B),
            letterSpacing: 1.1,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
            color: color ?? AppColors.darkText,
          ),
        ),
      ],
    );
  }
}
