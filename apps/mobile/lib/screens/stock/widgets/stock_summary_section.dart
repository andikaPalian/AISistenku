import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/stock_model.dart';

/// Ultra-clean Segmented Status Filter Bar.
///
/// Replaces chunky box templates with a sleek, native-grade segmented pill control (44px height).
class StockSummarySection extends StatelessWidget {
  final int totalCount;
  final int lowCount;
  final int criticalCount;
  final int totalValue;
  final StockStatus? activeFilter;
  final ValueChanged<StockStatus?> onFilterChanged;

  const StockSummarySection({
    super.key,
    required this.totalCount,
    required this.lowCount,
    required this.criticalCount,
    this.totalValue = 0,
    required this.activeFilter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
      ),
      child: Row(
        children: [
          // 1. Total Bahan (Semua)
          Expanded(
            child: _buildSegmentItem(
              title: 'Total Bahan',
              count: totalCount,
              isSelected: activeFilter == null,
              activeTextColor: const Color(0xFF0F172A),
              activeBadgeBg: const Color(0xFF111111),
              activeBadgeTextColor: Colors.white,
              inactiveBadgeBg: const Color(0xFFE2E8F0),
              inactiveBadgeTextColor: const Color(0xFF475569),
              onTap: () => onFilterChanged(null),
            ),
          ),

          // 2. Rendah
          Expanded(
            child: _buildSegmentItem(
              title: 'Rendah',
              count: lowCount,
              isSelected: activeFilter == StockStatus.rendah,
              activeTextColor: const Color(0xFFB45309),
              activeBadgeBg: const Color(0xFFF59E0B),
              activeBadgeTextColor: Colors.white,
              inactiveBadgeBg: const Color(0xFFFEF3C7),
              inactiveBadgeTextColor: const Color(0xFFB45309),
              onTap: () {
                if (activeFilter == StockStatus.rendah) {
                  onFilterChanged(null);
                } else {
                  onFilterChanged(StockStatus.rendah);
                }
              },
            ),
          ),

          // 3. Kritis
          Expanded(
            child: _buildSegmentItem(
              title: 'Kritis',
              count: criticalCount,
              isSelected: activeFilter == StockStatus.kritis,
              activeTextColor: const Color(0xFFB91C1C),
              activeBadgeBg: const Color(0xFFEF4444),
              activeBadgeTextColor: Colors.white,
              inactiveBadgeBg: const Color(0xFFFEE2E2),
              inactiveBadgeTextColor: const Color(0xFFB91C1C),
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
      ),
    );
  }

  Widget _buildSegmentItem({
    required String title,
    required int count,
    required bool isSelected,
    required Color activeTextColor,
    required Color activeBadgeBg,
    required Color activeBadgeTextColor,
    required Color inactiveBadgeBg,
    required Color inactiveBadgeTextColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(11),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 4,
                      offset: const Offset(0, 1.5),
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? activeTextColor : const Color(0xFF64748B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 5),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                decoration: BoxDecoration(
                  color: isSelected ? activeBadgeBg : inactiveBadgeBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  count.toString(),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: isSelected ? activeBadgeTextColor : inactiveBadgeTextColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
