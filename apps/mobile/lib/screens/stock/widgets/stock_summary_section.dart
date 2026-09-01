import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/stock_model.dart';

/// Interactive KPI summary metrics at the top of Stock screen.
class StockSummarySection extends StatelessWidget {
  final int totalCount;
  final int lowCount;
  final int criticalCount;
  final StockStatus? activeFilter;
  final ValueChanged<StockStatus?> onFilterChanged;

  const StockSummarySection({
    super.key,
    required this.totalCount,
    required this.lowCount,
    required this.criticalCount,
    required this.activeFilter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // 1. Total Bahan
        Expanded(
          child: _buildMetricCard(
            title: 'Total Bahan',
            count: totalCount,
            isSelected: activeFilter == null,
            countColor: AppColors.darkText,
            borderColor: activeFilter == null
                ? AppColors.primaryTeal
                : AppColors.border,
            bgColor: activeFilter == null
                ? AppColors.cardBackground
                : AppColors.cardBackground,
            icon: Icons.inventory_2_outlined,
            iconColor: AppColors.primaryTeal,
            onTap: () => onFilterChanged(null),
          ),
        ),
        const SizedBox(width: 10),

        // 2. Rendah
        Expanded(
          child: _buildMetricCard(
            title: 'Rendah',
            count: lowCount,
            isSelected: activeFilter == StockStatus.rendah,
            countColor: AppColors.warningOrange,
            borderColor: activeFilter == StockStatus.rendah
                ? AppColors.warningOrange
                : const Color(0xFFFDE68A),
            bgColor: activeFilter == StockStatus.rendah
                ? AppColors.warningBg.withOpacity(0.6)
                : AppColors.cardBackground,
            icon: Icons.warning_amber_rounded,
            iconColor: AppColors.warningOrange,
            badgeDot: lowCount > 0,
            onTap: () {
              if (activeFilter == StockStatus.rendah) {
                onFilterChanged(null);
              } else {
                onFilterChanged(StockStatus.rendah);
              }
            },
          ),
        ),
        const SizedBox(width: 10),

        // 3. Kritis
        Expanded(
          child: _buildMetricCard(
            title: 'Kritis',
            count: criticalCount,
            isSelected: activeFilter == StockStatus.kritis,
            countColor: AppColors.destructive,
            borderColor: activeFilter == StockStatus.kritis
                ? AppColors.destructive
                : const Color(0xFFFECACA),
            bgColor: activeFilter == StockStatus.kritis
                ? AppColors.dangerBg.withOpacity(0.6)
                : AppColors.cardBackground,
            icon: Icons.error_outline_rounded,
            iconColor: AppColors.destructive,
            badgeDot: criticalCount > 0,
            onTap: () {
              if (activeFilter == StockStatus.kritis) {
                onFilterChanged(null);
              } else {
                onFilterChanged(StockStatus.kritis);
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String title,
    required int count,
    required bool isSelected,
    required Color countColor,
    required Color borderColor,
    required Color bgColor,
    required IconData icon,
    required Color iconColor,
    bool badgeDot = false,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: borderColor,
            width: isSelected ? 2.0 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: borderColor.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              count.toString(),
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: countColor,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (badgeDot) ...[
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: countColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                ],
                Flexible(
                  child: Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected ? AppColors.darkText : AppColors.mutedText,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
