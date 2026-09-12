import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../models/finance_model.dart';

/// Interactive chart displaying sales revenue trend and cashflow breakdown.
///
/// Overhauled with Neo-Clean aesthetics, smooth glowing emerald splines,
/// interactive pulse points, and clean axes.
class SalesAnalyticsChart extends StatefulWidget {
  final List<ChartDataPoint> dataPoints;
  final FinancePeriod period;

  const SalesAnalyticsChart({
    super.key,
    required this.dataPoints,
    required this.period,
  });

  @override
  State<SalesAnalyticsChart> createState() => _SalesAnalyticsChartState();
}

class _SalesAnalyticsChartState extends State<SalesAnalyticsChart> {
  int _selectedChartMode = 0; // 0 = Line Trend, 1 = Bar Comparison

  @override
  Widget build(BuildContext context) {
    if (widget.dataPoints.isEmpty) {
      return const SizedBox.shrink();
    }

    final maxVal = widget.dataPoints.fold<double>(
      0.0,
      (max, p) => math.max(max, math.max(p.income, p.expense)),
    );
    final safeMax = maxVal == 0 ? 100000.0 : maxVal * 1.25;

    final totalIncome = widget.dataPoints.fold<double>(0, (sum, p) => sum + p.income);
    final avgIncome = totalIncome / widget.dataPoints.length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.03),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header & Growth Badge ─────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(
                  Icons.insights_rounded,
                  color: Color(0xFF16A34A),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Grafik Penjualan & Arus Kas',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Tren performa finansial bisnis Anda',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4.5),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.arrow_upward_rounded,
                      size: 13,
                      color: Color(0xFF16A34A),
                    ),
                    const SizedBox(width: 3),
                    Text(
                      '+18.4%',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF16A34A),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // ── Chart Mode Toggle (Pill Style) ────────────────────────
          Container(
            padding: const EdgeInsets.all(3.5),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _selectedChartMode = 0),
                    borderRadius: BorderRadius.circular(11),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: _selectedChartMode == 0
                            ? const Color(0xFF111111)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(11),
                        boxShadow: _selectedChartMode == 0
                            ? [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.12),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1.5),
                                ),
                              ]
                            : null,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Tren Omzet',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12.5,
                          fontWeight: _selectedChartMode == 0
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: _selectedChartMode == 0
                              ? Colors.white
                              : const Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _selectedChartMode = 1),
                    borderRadius: BorderRadius.circular(11),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: _selectedChartMode == 1
                            ? const Color(0xFF111111)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(11),
                        boxShadow: _selectedChartMode == 1
                            ? [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.12),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1.5),
                                ),
                              ]
                            : null,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Arus Kas',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12.5,
                          fontWeight: _selectedChartMode == 1
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: _selectedChartMode == 1
                              ? Colors.white
                              : const Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // ── Quick Summary Stat Bar ────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0), width: 0.8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _selectedChartMode == 0 ? 'Rata-rata Penjualan' : 'Total Masuk / Periode',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF64748B),
                  ),
                ),
                Text(
                  _selectedChartMode == 0
                      ? FinanceRepository.formatRupiah(avgIncome)
                      : FinanceRepository.formatRupiah(totalIncome),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── Chart Canvas / Visualizer ──────────────────────────────
          SizedBox(
            height: 210,
            child: _selectedChartMode == 0
                ? _buildFlLineChart(safeMax)
                : _buildFlBarChart(safeMax),
          ),

          const SizedBox(height: 16),

          // ── Legend Indicators ─────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendDot(
                color: const Color(0xFF22C55E),
                label: 'Pemasukan (Omzet)',
              ),
              if (_selectedChartMode == 1) ...[
                const SizedBox(width: 20),
                _buildLegendDot(
                  color: const Color(0xFFEF4444),
                  label: 'Pengeluaran',
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFlLineChart(double maxVal) {
    final interval = maxVal <= 0 ? 10000.0 : maxVal / 3;

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: interval,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: const Color(0xFFF1F5F9),
              strokeWidth: 1,
              dashArray: [5, 5],
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 26,
              interval: 1,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= widget.dataPoints.length) {
                  return const SizedBox();
                }
                return SideTitleWidget(
                  meta: meta,
                  space: 6,
                  child: Text(
                    widget.dataPoints[index].label,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: interval,
              reservedSize: 42,
              getTitlesWidget: (value, meta) {
                if (value == maxVal) return const SizedBox();
                return SideTitleWidget(
                  meta: meta,
                  child: Text(
                    _compactFormat(value),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: widget.dataPoints.length.toDouble() - 1,
        minY: 0,
        maxY: maxVal,
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (touchedSpot) => const Color(0xFF111111),
            tooltipPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((LineBarSpot touchedSpot) {
                final pt = widget.dataPoints[touchedSpot.x.toInt()];
                return LineTooltipItem(
                  '${pt.label}\n',
                  GoogleFonts.plusJakartaSans(
                    color: const Color(0xFF94A3B8),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                  children: [
                    TextSpan(
                      text: FinanceRepository.formatRupiah(pt.income),
                      style: GoogleFonts.plusJakartaSans(
                        color: const Color(0xFF22C55E),
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                );
              }).toList();
            },
          ),
          handleBuiltInTouches: true,
        ),
        lineBarsData: [
          LineChartBarData(
            spots: widget.dataPoints
                .asMap()
                .entries
                .map((e) => FlSpot(e.key.toDouble(), e.value.income))
                .toList(),
            isCurved: true,
            curveSmoothness: 0.35,
            color: const Color(0xFF22C55E),
            barWidth: 3.2,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 3,
                  color: Colors.white,
                  strokeWidth: 2,
                  strokeColor: const Color(0xFF22C55E),
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF22C55E).withValues(alpha: 0.24),
                  const Color(0xFF22C55E).withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFlBarChart(double maxVal) {
    final interval = maxVal <= 0 ? 10000.0 : maxVal / 3;

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxVal,
        minY: 0,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: interval,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: const Color(0xFFF1F5F9),
              strokeWidth: 1,
              dashArray: [5, 5],
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 26,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= widget.dataPoints.length) {
                  return const SizedBox();
                }
                return SideTitleWidget(
                  meta: meta,
                  space: 6,
                  child: Text(
                    widget.dataPoints[index].label,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: interval,
              reservedSize: 42,
              getTitlesWidget: (value, meta) {
                if (value == maxVal) return const SizedBox();
                return SideTitleWidget(
                  meta: meta,
                  child: Text(
                    _compactFormat(value),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (group) => const Color(0xFF111111),
            tooltipPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final pt = widget.dataPoints[groupIndex];
              final isIncome = rodIndex == 0;
              return BarTooltipItem(
                '${pt.label}\n',
                GoogleFonts.plusJakartaSans(
                  color: const Color(0xFF94A3B8),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
                children: [
                  TextSpan(
                    text: isIncome ? 'Masuk: ' : 'Keluar: ',
                    style: TextStyle(
                      color: isIncome ? const Color(0xFF22C55E) : const Color(0xFFF87171),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextSpan(
                    text: FinanceRepository.formatRupiah(rod.toY),
                    style: GoogleFonts.plusJakartaSans(
                      color: isIncome ? const Color(0xFF22C55E) : const Color(0xFFF87171),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        barGroups: widget.dataPoints.asMap().entries.map((e) {
          final i = e.key;
          final pt = e.value;
          return BarChartGroupData(
            x: i,
            barsSpace: 4,
            barRods: [
              BarChartRodData(
                toY: pt.income,
                color: const Color(0xFF22C55E),
                width: 10,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(5)),
              ),
              BarChartRodData(
                toY: pt.expense,
                color: const Color(0xFFEF4444),
                width: 10,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(5)),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLegendDot({required Color color, required String label}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  String _compactFormat(double val) {
    if (val >= 1000000) {
      return '${(val / 1000000).toStringAsFixed(1)}Jt';
    } else if (val >= 1000) {
      return '${(val / 1000).toStringAsFixed(0)}k';
    }
    return val.toStringAsFixed(0);
  }
}
