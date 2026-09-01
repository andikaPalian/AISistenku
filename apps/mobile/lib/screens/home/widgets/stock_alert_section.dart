import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/stock_model.dart';
import '../../stock/stock_screen.dart';
import '../../stock/stock_detail_screen.dart';
import 'stock_alert_item.dart';

/// Section showing items that need attention (low stock alerts).
class StockAlertSection extends StatelessWidget {
  const StockAlertSection({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: StockRepository.instance,
      builder: (context, _) {
        final alertItems = StockRepository.instance.items
            .where((i) => i.status != StockStatus.baik)
            .toList();

        if (alertItems.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Perlu Diperhatikan',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
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
                  child: Text(
                    'Lihat Stok',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppColors.primaryTeal,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ...alertItems.take(3).map((item) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: StockAlertItem(
                  itemName: item.name,
                  quantity: '${item.formattedCurrentStock} tersisa (${item.status.label})',
                  icon: item.icon,
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
            }),
          ],
        );
      },
    );
  }
}
