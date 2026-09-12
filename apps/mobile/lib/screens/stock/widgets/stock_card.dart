import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/stock_model.dart';
import 'restock_modal.dart';

/// Clean, breathable stock item card without nested containers or AI slop.
class StockCard extends StatelessWidget {
  final StockItem item;
  final VoidCallback onTap;

  const StockCard({
    super.key,
    required this.item,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final status = item.status;

    Color progressColor;
    Color badgeBg;
    Color badgeText;
    String badgeLabel;
    IconData badgeIcon;

    switch (status) {
      case StockStatus.kritis:
        progressColor = const Color(0xFFEF4444);
        badgeBg = const Color(0xFFFEE2E2);
        badgeText = const Color(0xFFDC2626);
        badgeLabel = 'Kritis';
        badgeIcon = Icons.error_outline_rounded;
        break;
      case StockStatus.rendah:
        progressColor = const Color(0xFFF59E0B);
        badgeBg = const Color(0xFFFEF3C7);
        badgeText = const Color(0xFFD97706);
        badgeLabel = 'Rendah';
        badgeIcon = Icons.warning_amber_rounded;
        break;
      case StockStatus.baik:
        progressColor = const Color(0xFF22C55E);
        badgeBg = const Color(0xFFDCFCE7);
        badgeText = const Color(0xFF16A34A);
        badgeLabel = 'Aman';
        badgeIcon = Icons.check_circle_outline_rounded;
        break;
    }

    final subtitleText = item.supplier.isNotEmpty
        ? '${item.category.label} • ${item.supplier}'
        : item.category.label;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            splashColor: const Color(0xFF111111).withValues(alpha: 0.04),
            highlightColor: const Color(0xFF111111).withValues(alpha: 0.02),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── 1. Top Header: Icon, Name, Category & Status Badge ──────
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Squircle icon container
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFFE2E8F0),
                            width: 1,
                          ),
                        ),
                        child: Icon(
                          item.icon,
                          color: const Color(0xFF0F172A),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Name and Subtitle
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.name,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 15.5,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF0F172A),
                                letterSpacing: -0.3,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              subtitleText,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF64748B),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Status Pill
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                        decoration: BoxDecoration(
                          color: badgeBg,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              badgeIcon,
                              size: 12,
                              color: badgeText,
                            ),
                            const SizedBox(width: 3.5),
                            Text(
                              badgeLabel,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: badgeText,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // ── 2. Middle Stats (Direct Typography & Slim Progress Line) ─
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      // Stock Quantity
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            item.formattedCurrentStock,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF0F172A),
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            '/ Min ${item.formattedMinStock}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),

                      // Total Valuation
                      Text(
                        item.formattedTotalValue,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Slim modern progress line
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: item.healthRatio,
                      minHeight: 4,
                      backgroundColor: const Color(0xFFF1F5F9),
                      valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ── 3. Bottom Row: Context Info & Tactile Restock Pill ─────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Context tag
                      if (item.linkedProducts.isNotEmpty)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.coffee_rounded,
                              size: 13,
                              color: Color(0xFF64748B),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${item.linkedProducts.length} Menu Terkait',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        )
                      else
                        Text(
                          '@ ${StockItem.formatRupiah(item.costPerUnit)} / ${item.unit}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF64748B),
                          ),
                        ),

                      // Tactile Solid Black Pill Restock Button
                      InkWell(
                        onTap: () => RestockModal.show(context, initialItem: item),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFF111111),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.12),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.add_rounded,
                                size: 14,
                                color: Color(0xFF22C55E),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Restock',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
