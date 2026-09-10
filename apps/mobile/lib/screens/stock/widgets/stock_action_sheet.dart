import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import 'restock_modal.dart';
import 'add_stock_modal.dart';

/// Action selector sheet for "+ Tambah Stok" button.
class StockActionSheet extends StatelessWidget {
  const StockActionSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => const StockActionSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.lightTealBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),

            Text(
              'Aksi Kelola Stok',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.darkText,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Pilih jenis pencatatan inventaris yang ingin dilakukan',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.mutedText,
              ),
            ),
            const SizedBox(height: 20),

            // Option 1: Restock Stok Masuk
            _buildActionItem(
              context: context,
              icon: Icons.add_shopping_cart_rounded,
              iconBg: AppColors.primaryTeal.withValues(alpha: 0.12),
              iconColor: AppColors.primaryTeal,
              title: 'Catat Stok Masuk (Restock)',
              subtitle: 'Tambah stok bahan yang sudah ada dari supplier',
              onTap: () {
                Navigator.pop(context);
                RestockModal.show(context);
              },
            ),
            const SizedBox(height: 12),

            // Option 2: Tambah Bahan Baku Baru
            _buildActionItem(
              context: context,
              icon: Icons.add_box_rounded,
              iconBg: AppColors.infoBg,
              iconColor: AppColors.infoBlue,
              title: 'Tambah Bahan Baku Baru',
              subtitle: 'Daftarkan varian bahan baku baru ke dalam katalog',
              onTap: () {
                Navigator.pop(context);
                AddStockModal.show(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionItem({
    required BuildContext context,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.lightTealBorder),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.darkText,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.mutedText,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.mutedText,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}
