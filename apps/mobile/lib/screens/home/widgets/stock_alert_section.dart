import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import 'stock_alert_item.dart';

/// Section showing items that need attention (low stock alerts).
class StockAlertSection extends StatelessWidget {
  const StockAlertSection({super.key});

  @override
  Widget build(BuildContext context) {
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
              onTap: () {},
              child: Text(
                'Lihat Stok',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppColors.mutedText,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        const StockAlertItem(
          itemName: 'Gula',
          quantity: '3 kg tersisa',
          icon: Icons.inventory_2_outlined,
        ),
        const SizedBox(height: 10),
        const StockAlertItem(
          itemName: 'Susu Segar',
          quantity: '5 L tersisa',
          icon: Icons.water_drop_outlined,
        ),
      ],
    );
  }
}
