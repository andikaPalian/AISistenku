import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';

/// Bottom bar showing cart summary and "Lihat Pesanan" action button.
///
/// Only visible when there are items in the cart.
class CartBottomBar extends StatelessWidget {
  final int itemCount;
  final String totalFormatted;
  final VoidCallback onViewOrder;

  const CartBottomBar({
    super.key,
    required this.itemCount,
    required this.totalFormatted,
    required this.onViewOrder,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.lightTealBorder, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryTeal.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Cart summary
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$itemCount Item',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.mutedText,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  totalFormatted,
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.darkText,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
          // Order button
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: onViewOrder,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryTeal,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 28),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                'Lihat Pesanan',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
