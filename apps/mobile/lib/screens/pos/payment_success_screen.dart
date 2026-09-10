import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../models/product.dart';

/// Screen displayed after a successful transaction payment.
///
/// Shows receipt summary, change calculation, and options to print or share receipt.
class PaymentSuccessScreen extends StatelessWidget {
  final OrderRecord order;
  final VoidCallback onNewTransaction;

  const PaymentSuccessScreen({
    super.key,
    required this.order,
    required this.onNewTransaction,
  });

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          onNewTransaction();
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.pageBackground,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              icon: const Icon(Icons.close_rounded, color: AppColors.darkText),
              onPressed: () {
                onNewTransaction();
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
                  child: Column(
                    children: [
                      // ── Success Animated Icon ─────────────────────────
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: AppColors.primaryTeal.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.check_circle_rounded,
                            color: AppColors.primaryTeal,
                            size: 52,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Pembayaran Berhasil!',
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: AppColors.darkText,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Pesanan telah diteruskan ke Barista & Dapur',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppColors.mutedText,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ── Digital Receipt Card ──────────────────────────
                      _buildReceiptCard(context),
                    ],
                  ),
                ),
              ),

              // ── Bottom Action Buttons ───────────────────────────
              _buildBottomActions(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReceiptCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.lightTealBorder, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryTeal.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Receipt Header
          Center(
            child: Column(
              children: [
                Text(
                  'TIGA ANGKATAN COFFEE',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    color: AppColors.darkText,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Jl. Kebon Sirih No. 42, Jakarta',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppColors.mutedText,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Divider(color: AppColors.lightTealBorder, thickness: 1),
          const SizedBox(height: 12),

          // Order Meta Info
          _buildInfoRow('No. Transaksi', order.orderId),
          const SizedBox(height: 6),
          _buildInfoRow(
            'Waktu',
            '${order.createdAt.day.toString().padLeft(2, '0')}/${order.createdAt.month.toString().padLeft(2, '0')}/${order.createdAt.year} ${order.createdAt.hour.toString().padLeft(2, '0')}:${order.createdAt.minute.toString().padLeft(2, '0')}',
          ),
          const SizedBox(height: 6),
          _buildInfoRow(
            'Tipe Pesanan',
            order.orderType == OrderType.dineIn
                ? 'Dine In (${order.tableNumber ?? "Meja"})'
                : 'Take Away',
          ),
          const SizedBox(height: 6),
          _buildInfoRow('Metode Bayar', order.paymentMethod.label),

          const SizedBox(height: 12),
          const Divider(color: AppColors.lightTealBorder, thickness: 1),
          const SizedBox(height: 12),

          // Items List
          ...order.items.map((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${item.quantity}x',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.darkText,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.product.name,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.darkText,
                          ),
                        ),
                        if (item.variant.isNotEmpty || item.note != null)
                          Text(
                            [
                              if (item.variant.isNotEmpty) item.variant,
                              if (item.note != null && item.note!.isNotEmpty) item.note!
                            ].join(' • '),
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: AppColors.mutedText,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Text(
                    item.formattedSubtotal,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.darkText,
                    ),
                  ),
                ],
              ),
            );
          }),

          const SizedBox(height: 8),
          const Divider(color: AppColors.lightTealBorder, thickness: 1),
          const SizedBox(height: 10),

          // Summary amounts
          _buildAmountRow('Subtotal', Product.formatRupiah(order.subtotal)),
          if (order.tax > 0) ...[
            const SizedBox(height: 4),
            _buildAmountRow('PB1 / Pajak (10%)', Product.formatRupiah(order.tax)),
          ],
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Bayar',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.darkText,
                ),
              ),
              Text(
                Product.formatRupiah(order.total),
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryTeal,
                ),
              ),
            ],
          ),

          if (order.paymentMethod == PaymentMethodType.cash && order.cashGiven > 0) ...[
            const SizedBox(height: 10),
            const Divider(color: AppColors.lightTealBorder, thickness: 1),
            const SizedBox(height: 8),
            _buildAmountRow('Tunai Diterima', Product.formatRupiah(order.cashGiven)),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Kembalian',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.successGreen,
                  ),
                ),
                Text(
                  Product.formatRupiah(order.change),
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.successGreen,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 12, color: AppColors.mutedText),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.darkText,
          ),
        ),
      ],
    );
  }

  Widget _buildAmountRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 13, color: AppColors.mutedText),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.darkText,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomActions(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Mengirim perintah cetak struk Bluetooth...'),
                        backgroundColor: AppColors.primaryTeal,
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  icon: const Icon(Icons.print_outlined, size: 18),
                  label: Text(
                    'Cetak Struk',
                    style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.darkText,
                    side: const BorderSide(color: AppColors.lightTealBorder, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Membuka format struk WhatsApp...'),
                        backgroundColor: AppColors.primaryTeal,
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  icon: const Icon(Icons.share_outlined, size: 18),
                  label: Text(
                    'Kirim Struk',
                    style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.darkText,
                    side: const BorderSide(color: AppColors.lightTealBorder, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: onNewTransaction,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryTeal,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
                elevation: 0,
              ),
              child: Text(
                'Transaksi Baru',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
