import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/finance_model.dart';

/// Interactive chart displaying sales revenue trend and cashflow breakdown.
///
/// Gives UMKM business owners clear insights to make data-driven decisions.
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
  int? _selectedIndex;

  @override
  Widget build(BuildContext context) {
    if (widget.dataPoints.isEmpty) {
      return const SizedBox.shrink();
    }

    final maxVal = widget.dataPoints.fold<double>(
      0.0,
      (max, p) => math.max(max, math.max(p.income, p.expense)),
    );
    final safeMax = maxVal == 0 ? 1000000.0 : maxVal * 1.15;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.analytics_rounded,
                        color: AppColors.primaryTeal,
                        size: 20,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Grafik Penjualan & Arus Kas',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.darkText,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Tren performa finansial bisnis Anda',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.mutedText,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.successBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.arrow_upward_rounded,
                      size: 12,
                      color: AppColors.successText,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      '+18.4%',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.successText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // ── Chart Mode Toggle (Line vs Bar) ─────────────────────────
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedChartMode = 0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        color: _selectedChartMode == 0
                            ? Colors.white
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: _selectedChartMode == 0
                            ? [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.06),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Tren Omzet (Line)',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: _selectedChartMode == 0
                              ? FontWeight.w600
                              : FontWeight.w500,
                          color: _selectedChartMode == 0
                              ? AppColors.primaryTeal
                              : AppColors.mutedText,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedChartMode = 1),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        color: _selectedChartMode == 1
                            ? Colors.white
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: _selectedChartMode == 1
                            ? [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.06),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Masuk vs Keluar (Bar)',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: _selectedChartMode == 1
                              ? FontWeight.w600
                              : FontWeight.w500,
                          color: _selectedChartMode == 1
                              ? AppColors.primaryTeal
                              : AppColors.mutedText,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── Selected Data Point Tooltip (if tapped) ───────────────
          if (_selectedIndex != null &&
              _selectedIndex! < widget.dataPoints.length) ...[
            Builder(builder: (context) {
              final p = widget.dataPoints[_selectedIndex!];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.darkText,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Periode: ${p.label}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          'Pemasukan: ${FinanceRepository.formatRupiah(p.income)}',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF34D399),
                          ),
                        ),
                        if (p.expense > 0) ...[
                          const SizedBox(width: 8),
                          Text(
                            'Pengeluaran: ${FinanceRepository.formatRupiah(p.expense)}',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFFF87171),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              );
            }),
          ],

          // ── Chart Canvas / Visualizer ──────────────────────────────
          SizedBox(
            height: 160,
            child: _selectedChartMode == 0
                ? _buildLineChart(safeMax)
                : _buildBarChart(safeMax),
          ),

          const SizedBox(height: 12),

          // ── Legend Indicators ─────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendDot(
                color: AppColors.primaryTeal,
                label: 'Pemasukan (Sales)',
              ),
              const SizedBox(width: 20),
              _buildLegendDot(
                color: const Color(0xFFEF4444),
                label: 'Pengeluaran (Cost)',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLineChart(double maxVal) {
    return LayoutBuilder(builder: (context, constraints) {
      return GestureDetector(
        onTapDown: (details) {
          final renderBox = context.findRenderObject() as RenderBox?;
          if (renderBox == null) return;
          final localPos = details.localPosition;
          final pointWidth =
              constraints.maxWidth / (widget.dataPoints.length - 1);
          final index = (localPos.dx / pointWidth)
              .round()
              .clamp(0, widget.dataPoints.length - 1);
          setState(() {
            _selectedIndex = index;
          });
        },
        child: CustomPaint(
          size: Size(constraints.maxWidth, 160),
          painter: _LineChartPainter(
            points: widget.dataPoints,
            maxVal: maxVal,
            selectedIndex: _selectedIndex,
          ),
        ),
      );
    });
  }

  Widget _buildBarChart(double maxVal) {
    return LayoutBuilder(builder: (context, constraints) {
      final barGroupWidth = constraints.maxWidth / widget.dataPoints.length;

      return Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: widget.dataPoints.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final isSelected = _selectedIndex == index;

          final incomeHeight =
              (item.income / maxVal) * 120.0;
          final expenseHeight =
              (item.expense / maxVal) * 120.0;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedIndex = index;
              });
            },
            child: Container(
              width: barGroupWidth,
              color: Colors.transparent,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Income Bar
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: barGroupWidth * 0.3,
                        height: math.max(incomeHeight, 4.0),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.accent
                              : AppColors.primaryTeal,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4),
                          ),
                        ),
                      ),
                      const SizedBox(width: 3),
                      // Expense Bar
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: barGroupWidth * 0.3,
                        height: math.max(expenseHeight, 2.0),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFFB91C1C)
                              : const Color(0xFFEF4444).withOpacity(0.85),
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item.label,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected
                          ? AppColors.primaryTeal
                          : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      );
    });
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
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }
}

class _LineChartPainter extends CustomPainter {
  final List<ChartDataPoint> points;
  final double maxVal;
  final int? selectedIndex;

  _LineChartPainter({
    required this.points,
    required this.maxVal,
    this.selectedIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final chartHeight = size.height - 24; // room for x-axis labels
    final pointSpacing = size.width / (points.length - 1);

    // Draw horizontal grid lines
    final gridPaint = Paint()
      ..color = const Color(0xFFF1F5F9)
      ..strokeWidth = 1;

    for (int i = 0; i <= 3; i++) {
      final y = chartHeight * (i / 3);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final incomeOffsets = <Offset>[];
    for (int i = 0; i < points.length; i++) {
      final x = i * pointSpacing;
      final y = chartHeight - ((points[i].income / maxVal) * chartHeight);
      incomeOffsets.add(Offset(x, y.clamp(10.0, chartHeight)));
    }

    // Draw Smooth Area Gradient
    final areaPath = Path();
    areaPath.moveTo(0, chartHeight);
    areaPath.lineTo(incomeOffsets[0].dx, incomeOffsets[0].dy);

    for (int i = 0; i < incomeOffsets.length - 1; i++) {
      final current = incomeOffsets[i];
      final next = incomeOffsets[i + 1];
      final controlX = (current.dx + next.dx) / 2;
      areaPath.cubicTo(
        controlX,
        current.dy,
        controlX,
        next.dy,
        next.dx,
        next.dy,
      );
    }
    areaPath.lineTo(size.width, chartHeight);
    areaPath.close();

    final gradientPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppColors.primaryTeal.withOpacity(0.35),
          AppColors.primaryTeal.withOpacity(0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, chartHeight))
      ..style = PaintingStyle.fill;

    canvas.drawPath(areaPath, gradientPaint);

    // Draw Curved Stroke Line
    final linePath = Path();
    linePath.moveTo(incomeOffsets[0].dx, incomeOffsets[0].dy);
    for (int i = 0; i < incomeOffsets.length - 1; i++) {
      final current = incomeOffsets[i];
      final next = incomeOffsets[i + 1];
      final controlX = (current.dx + next.dx) / 2;
      linePath.cubicTo(
        controlX,
        current.dy,
        controlX,
        next.dy,
        next.dx,
        next.dy,
      );
    }

    final strokePaint = Paint()
      ..color = AppColors.primaryTeal
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(linePath, strokePaint);

    // Draw Point Dots & Labels
    for (int i = 0; i < points.length; i++) {
      final offset = incomeOffsets[i];
      final isSelected = selectedIndex == i;

      // Circle Point
      final dotPaint = Paint()
        ..color = isSelected ? AppColors.accent : Colors.white
        ..style = PaintingStyle.fill;
      final borderDotPaint = Paint()
        ..color = AppColors.primaryTeal
        ..strokeWidth = isSelected ? 3 : 2
        ..style = PaintingStyle.stroke;

      canvas.drawCircle(offset, isSelected ? 6 : 4, dotPaint);
      canvas.drawCircle(offset, isSelected ? 6 : 4, borderDotPaint);

      // X-Axis Text Label
      final textPainter = TextPainter(
        text: TextSpan(
          text: points[i].label,
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected
                ? AppColors.primaryTeal
                : const Color(0xFF64748B),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      textPainter.paint(
        canvas,
        Offset(offset.dx - (textPainter.width / 2), size.height - 14),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.maxVal != maxVal ||
        oldDelegate.selectedIndex != selectedIndex;
  }
}
