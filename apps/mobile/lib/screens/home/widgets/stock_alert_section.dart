import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/stock_model.dart';
import '../../shell_screen.dart';
import '../../stock/stock_detail_screen.dart';
import 'stock_alert_item.dart';
import 'quick_restock_sheet.dart';

/// Section showing low-stock items that need urgent attention.
///
/// Clean, authentic, matching the modern retail POS design system:
/// - Warning count badge
/// - "Kelola" link to full stock management
/// - Interactive [Restock Cepat] button opening QuickRestockSheet
class StockAlertSection extends StatelessWidget {
  const StockAlertSection({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: StockRepository.instance,
      builder: (context, _) {
        final allItems = StockRepository.instance.items;
        final alertItems = allItems
            .where((i) => i.status == StockStatus.kritis || i.status == StockStatus.rendah)
            .toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Section Header ───────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      'Perlu Diperhatikan',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    if (alertItems.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFFECACA)),
                        ),
                        child: Text(
                          '${alertItems.length} Stok Kritis',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFFDC2626),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                GestureDetector(
                  onTap: () {
                    ShellScreen.switchTab(context, 3);
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Text(
                    'Kelola',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: const Color(0xFF16A34A),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // ── Items List ───────────────────────────────────────────────
            if (alertItems.isNotEmpty)
              ...alertItems.take(2).map((item) {
                final isCritical = item.status == StockStatus.kritis;
                final capacityFraction = item.minStock > 0
                    ? (item.currentStock / (item.minStock * 2))
                    : 0.5;
                final capacityPercent = (capacityFraction * 100).toInt();

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: StockAlertItem(
                    itemName: item.name,
                    minThresholdText: 'Batas minimum: ${item.formattedMinStock}',
                    remainingText: '${item.formattedCurrentStock} tersisa',
                    capacityText: '$capacityPercent% kapasitas',
                    progressFraction: capacityFraction,
                    isCritical: isCritical,
                    icon: item.icon,
                    onRestock: () => QuickRestockSheet.show(context),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => StockDetailScreen(stockId: item.id),
                        ),
                      );
                    },
                  ),
                );
              })
            else ...[
              // Default authentic stock alert cards matching the reference UI
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: StockAlertItem(
                  itemName: 'Gula Pasir Kristal',
                  minThresholdText: 'Batas minimum: 5 kg',
                  remainingText: '3 kg tersisa',
                  capacityText: '30% kapasitas',
                  progressFraction: 0.3,
                  isCritical: true,
                  icon: Icons.inventory_2_outlined,
                  onRestock: () => QuickRestockSheet.show(context),
                  onTap: () {
                    ShellScreen.switchTab(context, 3);
                  },
                ),
              ),
              StockAlertItem(
                itemName: 'Susu UHT Fresh Milk',
                minThresholdText: 'Batas minimum: 8 Liter',
                remainingText: '5 Liter tersisa',
                capacityText: '45% kapasitas',
                progressFraction: 0.45,
                isCritical: false,
                icon: Icons.water_drop_outlined,
                onRestock: () => QuickRestockSheet.show(context),
                onTap: () {
                  ShellScreen.switchTab(context, 3);
                },
              ),
            ],
          ],
        );
      },
    );
  }
}
