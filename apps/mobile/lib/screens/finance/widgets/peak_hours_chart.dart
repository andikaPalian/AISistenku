import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/finance_model.dart';

/// Peak Hours chart widget showing busiest operational hours for barista scheduling
/// and stock readiness.
class PeakHoursChart extends StatelessWidget {
  final List<PeakHourData> peakHours;

  const PeakHoursChart({
    super.key,
    required this.peakHours,
  });

  @override
  Widget build(BuildContext context) {
    final maxOrders = peakHours.fold<int>(
      0,
      (max, p) => p.orderCount > max ? p.orderCount : max,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.local_fire_department_rounded,
                      color: Color(0xFFD97706),
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Jam Sibuk Penjualan (Peak Hours)',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.darkText,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primaryTeal.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Shift Insight',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryTeal,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // ── Horizontal distribution bars ──────────────────────────
          Column(
            children: peakHours.map((item) {
              final ratio = maxOrders > 0 ? (item.orderCount / maxOrders) : 0.0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    SizedBox(
                      width: 52,
                      child: Text(
                        '${item.timeRange} WIB',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight:
                              item.isPeak ? FontWeight.w700 : FontWeight.w500,
                          color: item.isPeak
                              ? AppColors.primaryTeal
                              : const Color(0xFF64748B),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Stack(
                        children: [
                          Container(
                            height: 18,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          FractionallySizedBox(
                            widthFactor: ratio.clamp(0.05, 1.0),
                            child: Container(
                              height: 18,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: item.isPeak
                                      ? [
                                          AppColors.primaryTeal,
                                          AppColors.secondary
                                        ]
                                      : [
                                          const Color(0xFF94A3B8),
                                          const Color(0xFFCBD5E1)
                                        ],
                                ),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 6),
                              child: Text(
                                '${item.orderCount} pesanan',
                                style: GoogleFonts.inter(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 70,
                      child: Text(
                        FinanceRepository.formatRupiah(item.revenue),
                        textAlign: TextAlign.end,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight:
                              item.isPeak ? FontWeight.w700 : FontWeight.w500,
                          color: item.isPeak
                              ? AppColors.darkText
                              : const Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),

          const Divider(height: 16, color: Color(0xFFF1F5F9)),

          // ── Actionable Recommendation Tip ────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.lightbulb_outline_rounded,
                size: 15,
                color: Color(0xFFD97706),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Jam 12:00-14:00 & 18:00-21:00 merupakan puncak keramaian. Pastikan 2 barista aktif dan stok cup/susu siap.',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF64748B),
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
