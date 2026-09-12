import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../models/product.dart';
import '../shell_screen.dart';

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

  void _navigateToHome(BuildContext context) {
    try {
      onNewTransaction();
    } catch (_) {}
    Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const ShellScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _navigateToHome(context);
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
              onPressed: () => _navigateToHome(context),
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
                          color: AppColors.secondary.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.check_circle_rounded,
                            color: AppColors.secondary,
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
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
          const Divider(color: Color(0xFFE2E8F0), thickness: 1),
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
          const Divider(color: Color(0xFFE2E8F0), thickness: 1),
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
          const Divider(color: Color(0xFFE2E8F0), thickness: 1),
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
            const Divider(color: Color(0xFFE2E8F0), thickness: 1),
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
      color: const Color(0xFFF8F9FA),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
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
                        backgroundColor: AppColors.primary,
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  icon: const Icon(Icons.print_outlined, size: 18),
                  label: Text(
                    'Cetak Struk',
                    style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.border, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
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
                        backgroundColor: AppColors.primary,
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  icon: const Icon(Icons.share_outlined, size: 18),
                  label: Text(
                    'Kirim Struk',
                    style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.border, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () => _navigateToHome(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF111111),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 4,
                shadowColor: const Color(0xFF111111).withValues(alpha: 0.3),
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
