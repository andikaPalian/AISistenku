import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/product.dart';

/// POS screen header with title, subtitle, and history button.
class PosHeader extends StatelessWidget {
  const PosHeader({super.key});

  void _showOrderHistory(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.65,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (_, scrollController) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Column(
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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Riwayat Transaksi Hari Ini',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.darkText,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      physics: const BouncingScrollPhysics(),
                      children: [
                        _buildHistoryItem(
                          trxId: '#TRX-20260901-0031',
                          time: '14:15 WIB',
                          items: '2x Iced Latte, 1x Beef Pie',
                          total: 'Rp60.000',
                          payment: 'QRIS',
                          isSuccess: true,
                        ),
                        _buildHistoryItem(
                          trxId: '#TRX-20260901-0030',
                          time: '13:48 WIB',
                          items: '1x Americano, 1x Blueberry Muffin',
                          total: 'Rp36.000',
                          payment: 'Cash',
                          isSuccess: true,
                        ),
                        _buildHistoryItem(
                          trxId: '#TRX-20260901-0029',
                          time: '13:10 WIB',
                          items: '3x Matcha Latte, 2x Croissant',
                          total: 'Rp90.000',
                          payment: 'Debit Card',
                          isSuccess: true,
                        ),
                        _buildHistoryItem(
                          trxId: '#TRX-20260901-0028',
                          time: '12:25 WIB',
                          items: '1x Avocado Toast',
                          total: 'Rp25.000',
                          payment: 'QRIS',
                          isSuccess: true,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildHistoryItem({
    required String trxId,
    required String time,
    required String items,
    required String total,
    required String payment,
    required bool isSuccess,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.lightTealBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                trxId,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryTeal,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.successGreen.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Selesai',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.successGreen,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            items,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.darkText,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$time • $payment',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.mutedText,
                ),
              ),
              Text(
                total,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.darkText,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

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
          // History button with interactive bottom sheet
          GestureDetector(
            onTap: () => _showOrderHistory(context),
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
