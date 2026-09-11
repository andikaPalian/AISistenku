import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import 'add_edit_product_modal.dart';

/// POS screen header with title, subtitle, "+ Menu Baru" button, and transaction history button.
/// Strictly uses authentic brand colors (#0D9488, #CCFBF1, #F8FFFE, #0F172A).
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
          initialChildSize: 0.7,
          minChildSize: 0.4,
          maxChildSize: 0.92,
          expand: false,
          builder: (_, scrollController) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2E8F0), // Clean slate handle
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primaryTeal.withValues(alpha: 0.1), // Elegant tinted teal
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.receipt_long_rounded,
                              color: AppColors.primaryTeal,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Riwayat Transaksi Hari Ini',
                            style: GoogleFonts.poppins(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: AppColors.darkText,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: AppColors.mutedText),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      physics: const BouncingScrollPhysics(),
                      children: [
                        _buildHistoryItem(
                          trxId: '#TRX-20260901-0032',
                          time: '14:35 WIB',
                          items: '2x Kopi Susu Aren (Regular)',
                          total: 'Rp36.000',
                          payment: 'Cash',
                          isSuccess: true,
                        ),
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
                          items: '3x Matcha Latte, 2x Croissant Butter',
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06), // Pop out instead of border
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
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
                  color: AppColors.darkText, // More premium than everything being teal
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.successBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Selesai',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.successText,
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
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9), // Clean light slate
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.point_of_sale_rounded,
              color: Color(0xFF0F172A),
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Kasir POS',
                  style: GoogleFonts.poppins(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    color: AppColors.darkText,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Layanan Cepat & Transaksi',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.mutedText,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          // Add Menu Button (+ Menu)
          GestureDetector(
            onTap: () => AddEditProductModal.show(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: AppColors.primaryTeal,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryTeal.withValues(alpha: 0.25),
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
                    color: Colors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Menu Baru',
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // History button with interactive bottom sheet
          GestureDetector(
            onTap: () => _showOrderHistory(context),
            behavior: HitTestBehavior.opaque,
            child: Container(
              padding: const EdgeInsets.all(9),
              decoration: const BoxDecoration(
                color: Color(0xFFF1F5F9), // Clean light slate
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.receipt_long_rounded,
                color: Color(0xFF0F172A),
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
