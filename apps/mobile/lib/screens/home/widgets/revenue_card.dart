import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';

/// Card showing today's gross revenue, mini 7-day bar chart,
/// and key sub-metrics (Orders, Today's Expenses, Net Margin).
///
/// Designed to exactly match the reference UI card "BISNIS HARI INI".
class RevenueCard extends StatelessWidget {
  final String grossRevenue;
  final String percentChange;
  final String lastUpdatedTime;
  final int orderCount;
  final String orderPercentChange;
  final String todayExpenses;
  final String netMarginPercent;

  const RevenueCard({
    super.key,
    this.grossRevenue = 'Rp1.250.000',
    this.percentChange = '+12%',
    this.lastUpdatedTime = 'Pembaruan 10:42 WIB',
    this.orderCount = 32,
    this.orderPercentChange = '+18%',
    this.todayExpenses = 'Rp280rb',
    this.netMarginPercent = '68%',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.lightTealBorder, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header Row: Title & Last Updated ──────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.neutralSubCard,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.border, width: 1),
                    ),
                    child: const Icon(
                      Icons.bar_chart_rounded,
                      size: 15,
                      color: AppColors.mutedText,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'BISNIS HARI INI',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: AppColors.mutedText,
                    ),
                  ),
                ],
              ),
              Text(
                lastUpdatedTime,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: AppColors.mutedText,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ── Revenue Value & 7-Day Mini Chart ───────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Left: Gross Revenue & Badge
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pendapatan Kotor',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.mutedText,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    grossRevenue,
                    style: GoogleFonts.poppins(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: AppColors.darkText,
                      height: 1.1,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.trending_up_rounded,
                          color: Color(0xFF15803D),
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$percentChange dari kemarin',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF15803D),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Right: 7-Day Mini Bar Chart
              const _WeeklyMiniBarChart(),
            ],
          ),

          const SizedBox(height: 18),

          // ── Bottom Sub-Metrics Row ────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.neutralSubCard,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.neutralSubBorder, width: 1),
            ),
            child: Row(
              children: [
                // 1. Pesanan
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pesanan',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: AppColors.mutedText,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            '$orderCount',
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.darkText,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            orderPercentChange,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF16A34A),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                Container(
                  width: 1,
                  height: 28,
                  color: AppColors.border,
                ),
                const SizedBox(width: 12),

                // 2. Beban Hari Ini
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Beban Hari Ini',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: AppColors.mutedText,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        todayExpenses,
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.darkText,
                        ),
                      ),
                    ],
                  ),
                ),

                Container(
                  width: 1,
                  height: 28,
                  color: AppColors.border,
                ),
                const SizedBox(width: 12),

                // 3. Net Margin
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Net Margin',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: AppColors.mutedText,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            netMarginPercent,
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.darkText,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.check_circle_rounded,
                            size: 14,
                            color: Color(0xFF16A34A),
                          ),
                        ],
                      ),
                    ],
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

/// Mini 7-day bar chart showing days: M, S, S, R, K, J, S
/// with the current day (Sabtu) highlighted in dark teal/black.
class _WeeklyMiniBarChart extends StatelessWidget {
  const _WeeklyMiniBarChart();

  @override
  Widget build(BuildContext context) {
    const days = [
      {'label': 'M', 'height': 20.0, 'active': false},
      {'label': 'S', 'height': 25.0, 'active': false},
      {'label': 'S', 'height': 22.0, 'active': false},
      {'label': 'R', 'height': 30.0, 'active': false},
      {'label': 'K', 'height': 28.0, 'active': false},
      {'label': 'J', 'height': 36.0, 'active': false},
      {'label': 'S', 'height': 44.0, 'active': true},
    ];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: days.map((day) {
        final isActive = day['active'] as bool;
        final height = day['height'] as double;
        final label = day['label'] as String;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: height,
                decoration: BoxDecoration(
                  color: isActive
                      ? const Color(0xFF0F172A)
                      : const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  color: isActive
                      ? const Color(0xFF0F172A)
                      : AppColors.mutedText,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
