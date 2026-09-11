import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/stock_model.dart';
import '../../stock/stock_screen.dart';
import '../../stock/stock_detail_screen.dart';
import 'stock_alert_item.dart';

/// Section showing low-stock items that need urgent attention.
///
/// Matches the reference UI with warning icon, "Kelola Semua" link,
/// and interactive [Restock Cepat] action dialog.
class StockAlertSection extends StatelessWidget {
  const StockAlertSection({super.key});

  void _showQuickRestockDialog(BuildContext context, StockItem item) {
    final qtyController = TextEditingController(text: '5');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.shopping_cart_outlined, color: AppColors.primaryTeal),
                  const SizedBox(width: 8),
                  Text(
                    'Restock Cepat: ${item.name}',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.darkText,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Stok saat ini: ${item.formattedCurrentStock} (Batas minimum: ${item.formattedMinStock})',
                style: GoogleFonts.inter(fontSize: 13, color: AppColors.mutedText),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: qtyController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Jumlah Tambah (${item.unit})',
                  hintText: 'Contoh: 5',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    final qty = double.tryParse(qtyController.text) ?? 0;
                    if (qty > 0) {
                      StockRepository.instance.restockItem(
                        stockId: item.id,
                        quantity: qty,
                        note: 'Restock Cepat via Beranda',
                      );
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Berhasil menambah $qty ${item.unit} ${item.name}'),
                          backgroundColor: AppColors.successGreen,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryTeal,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    'Konfirmasi Restock',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

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
                Text(
                  'Perlu Diperhatikan',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.darkText,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const StockScreen()),
                    );
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Text(
                    'Kelola',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.primaryTeal,
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
                    onRestock: () => _showQuickRestockDialog(context, item),
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
                  onRestock: () {
                    final item = StockRepository.instance.getItemById('sugar');
                    if (item != null) {
                      _showQuickRestockDialog(context, item);
                    }
                  },
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const StockScreen()),
                    );
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
                onRestock: () {
                  final item = StockRepository.instance.getItemById('fresh_milk');
                  if (item != null) {
                    _showQuickRestockDialog(context, item);
                  }
                },
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const StockScreen()),
                  );
                },
              ),
            ],
          ],
        );
      },
    );
  }
}
