import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/finance_model.dart';

/// Peak Hours chart widget showing busiest operational hours for barista scheduling
/// and stock readiness in Neo-Clean design.
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
        boxShadow: const [
          BoxShadow(
            color: Color(0x060F172A),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header: Title & Shift Insight Badge ───────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.local_fire_department_rounded,
                  color: Color(0xFFD97706),
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Jam Sibuk Penjualan (Peak Hours)',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A),
                        letterSpacing: -0.2,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Kesiapan shift & stok bahan operasional',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFFE2E8F0),
                    width: 1,
                  ),
                ),
                child: Text(
                  'Shift Insight',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // ── Clean Horizontal Distribution Bars ────────────────────
          Column(
            children: peakHours.map((item) {
              final ratio = maxOrders > 0 ? (item.orderCount / maxOrders) : 0.0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Label line: Time slot, Peak badge, Orders, and Revenue
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Text(
                              '${item.timeRange} WIB',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: item.isPeak
                                    ? FontWeight.w800
                                    : FontWeight.w600,
                                color: item.isPeak
                                    ? const Color(0xFF0F172A)
                                    : const Color(0xFF475569),
                              ),
                            ),
                            if (item.isPeak) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFDCFCE7),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '🔥 Puncak',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF16A34A),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        Row(
                          children: [
                            Text(
                              '${item.orderCount} pesanan',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '•',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                color: const Color(0xFFCBD5E1),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              FinanceRepository.formatRupiah(item.revenue),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: item.isPeak
                                    ? FontWeight.w800
                                    : FontWeight.w700,
                                color: item.isPeak
                                    ? const Color(0xFF0F172A)
                                    : const Color(0xFF334155),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Progress capsule track
                    Stack(
                      children: [
                        Container(
                          height: 7,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        FractionallySizedBox(
                          widthFactor: ratio.clamp(0.04, 1.0),
                          child: Container(
                            height: 7,
                            decoration: BoxDecoration(
                              color: item.isPeak
                                  ? const Color(0xFF22C55E)
                                  : const Color(0xFFCBD5E1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
          ),

          const Divider(
            height: 18,
            color: Color(0xFFF1F5F9),
          ),

          // ── Actionable Recommendation Tip ────────────────────────
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFE2E8F0),
                width: 1,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.lightbulb_outline_rounded,
                  size: 17,
                  color: Color(0xFFD97706),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Jam 12:00-14:00 & 18:00-21:00 merupakan puncak keramaian. Pastikan barista aktif dan stok cup/susu siap sedia.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF334155),
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
