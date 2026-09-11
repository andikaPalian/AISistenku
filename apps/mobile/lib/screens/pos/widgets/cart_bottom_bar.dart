import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';

/// Bottom bar showing cart summary and "Lihat Pesanan" action button.
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
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 14),
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        // No hard border
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08), // Soft black shadow instead of tinted teal
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Cart summary (item count + total price)
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9), // Clean light slate
                        borderRadius: BorderRadius.circular(6),
                        // No border
                      ),
                      child: Text(
                        '$itemCount Item',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: const Color(0xFF0F172A),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Total Belanja',
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        color: AppColors.mutedText,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  totalFormatted,
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.darkText,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
          // View order action button
          SizedBox(
            height: 46,
            child: ElevatedButton(
              onPressed: onViewOrder,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryTeal,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Lihat Pesanan',
                    style: GoogleFonts.inter(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.arrow_forward_rounded, size: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
