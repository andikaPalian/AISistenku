import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';

/// POS screen header with title, subtitle, and history button.
class PosHeader extends StatelessWidget {
  const PosHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.tealBackgrounds,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.point_of_sale_rounded,
              color: AppColors.primaryTeal,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'POS',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.darkText,
                    height: 1.2,
                  ),
                ),
                Text(
                  'Pesanan Baru',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.mutedText,
                  ),
                ),
              ],
            ),
          ),
          // History button
          GestureDetector(
            onTap: () {
              // TODO: Navigate to order history
            },
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.tealBackgrounds,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.lightTealBorder,
                  width: 1,
                ),
              ),
              child: const Icon(
                Icons.history_rounded,
                color: AppColors.darkText,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
