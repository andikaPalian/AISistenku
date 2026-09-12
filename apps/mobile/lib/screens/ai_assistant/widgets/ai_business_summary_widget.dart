import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/finance_model.dart';

/// Clean business metric breakdown widget embedded seamlessly inside AI responses.
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
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          _buildMetricRow(
            label: 'Pendapatan Kotor',
            value: FinanceRepository.formatRupiah(revenue),
            isBold: true,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Divider(height: 1, color: Color(0xFFE2E8F0)),
          ),
          _buildMetricRow(
            label: 'Estimasi Laba',
            value: '+ ${FinanceRepository.formatRupiah(profit)}',
            isPositive: true,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Divider(height: 1, color: Color(0xFFE2E8F0)),
          ),
          _buildMetricRow(
            label: 'Menu Terlaris',
            value: bestSeller,
            isHighlight: true,
          ),
        ],
      ),
    );
  }

  Widget _buildMetricRow({
    required String label,
    required String value,
    bool isBold = false,
    bool isPositive = false,
    bool isHighlight = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF64748B),
          ),
        ),
        if (isPositive)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFF22C55E).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF16A34A),
              ),
            ),
          )
        else
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 13.5,
              fontWeight: isBold || isHighlight ? FontWeight.w700 : FontWeight.w500,
              color: AppColors.darkText,
            ),
          ),
      ],
    );
  }
}
