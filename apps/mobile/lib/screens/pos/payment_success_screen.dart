import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/services/offline_sync_service.dart';
import '../../core/services/thermal_printer_service.dart';
import '../../core/theme/app_colors.dart';
import '../../models/product.dart';
import '../../models/profile_model.dart';
import '../shell_screen.dart';
import 'widgets/printer_selection_modal.dart';
import 'widgets/offline_sync_modal.dart';

/// Screen displayed after a successful transaction payment.
///
/// Shows receipt summary, change calculation, and options to print directly to Bluetooth thermal printer or share receipt.
class PaymentSuccessScreen extends StatefulWidget {
  final OrderRecord order;
  final VoidCallback onNewTransaction;

  const PaymentSuccessScreen({
    super.key,
    required this.order,
    required this.onNewTransaction,
  });

  @override
  State<PaymentSuccessScreen> createState() => _PaymentSuccessScreenState();
}

class _PaymentSuccessScreenState extends State<PaymentSuccessScreen> {
  final ThermalPrinterService _printerService = ThermalPrinterService.instance;
  bool _isPrinting = false;
  bool _hasPrinted = false;
  Timer? _autoPrintTimer;

  OrderRecord get order => widget.order;

  @override
  void initState() {
    super.initState();
    _printerService.addListener(_onPrinterChanged);
    _checkAutoPrint();
  }

  void _onPrinterChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _autoPrintTimer?.cancel();
    _printerService.removeListener(_onPrinterChanged);
    super.dispose();
  }

  void _checkAutoPrint() {
    final prefs = ProfileRepository.instance.preferences;
    if (prefs.autoPrintReceipt && !_hasPrinted) {
      _autoPrintTimer = Timer(const Duration(milliseconds: 600), () {
        if (mounted) {
          _handlePrintReceipt();
        }
      });
    }
  }

  Future<void> _handlePrintReceipt() async {
    // If not connected to any thermal printer, show modal to connect
    if (!_printerService.isConnected) {
      PrinterSelectionModal.show(
        context,
        order: widget.order,
        onPrinted: () {
          if (mounted) setState(() => _hasPrinted = true);
        },
      );
      return;
    }

    setState(() => _isPrinting = true);
    final business = ProfileRepository.instance.business;
    final success = await _printerService.printReceipt(
      order: widget.order,
      business: business,
    );

    if (mounted) {
      setState(() {
        _isPrinting = false;
        if (success) _hasPrinted = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                success ? Icons.check_circle_rounded : Icons.error_outline_rounded,
                color: Colors.white,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  success
                      ? 'Struk transaksi #${widget.order.orderCode} berhasil dicetak ke ${_printerService.selectedDevice?.name ?? "Printer"} (${_printerService.paperSize.label})!'
                      : 'Gagal mengirim ke printer thermal. Periksa koneksi Bluetooth.',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          action: SnackBarAction(
            label: 'Atur Printer',
            textColor: Colors.amber,
            onPressed: () => PrinterSelectionModal.show(context, order: widget.order),
          ),
          backgroundColor: success ? AppColors.secondary : AppColors.destructive,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _handleShareReceipt() {
    final order = widget.order;
    final business = ProfileRepository.instance.business;
    final receiptText = _printerService.formatReceiptText(
      order: order,
      business: business,
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Kirim & Bagikan Struk Digital',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 17, color: AppColors.darkText),
              ),
              const SizedBox(height: 4),
              Text(
                'Kirimkan rincian pembayaran ke pelanggan via teks / WhatsApp',
                style: GoogleFonts.inter(fontSize: 12, color: AppColors.mutedText),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF25D366).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.chat_rounded, color: Color(0xFF25D366)),
                ),
                title: Text('Salin Format WhatsApp', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                subtitle: Text('Salin teks terformat siap kirim ke nomor WA pelanggan', style: GoogleFonts.inter(fontSize: 11)),
                onTap: () {
                  Clipboard.setData(ClipboardData(text: receiptText));
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Format struk WhatsApp berhasil disalin!'),
                      backgroundColor: AppColors.secondary,
                    ),
                  );
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF111111).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.copy_rounded, color: Color(0xFF111111)),
                ),
                title: Text('Salin Teks Lengkap', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                subtitle: Text('Simpan teks struk untuk arsip atau aplikasi lain', style: GoogleFonts.inter(fontSize: 11)),
                onTap: () {
                  Clipboard.setData(ClipboardData(text: receiptText));
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Teks struk disalin ke clipboard')),
                  );
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primaryTeal.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.print_rounded, color: AppColors.primaryTeal),
                ),
                title: Text('Cetak via Printer Thermal Bluetooth', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                subtitle: Text('Gunakan printer thermal fisik (58mm / 80mm)', style: GoogleFonts.inter(fontSize: 11)),
                onTap: () {
                  Navigator.pop(ctx);
                  _handlePrintReceipt();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToHome(BuildContext context) {
    try {
      widget.onNewTransaction();
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
          // Offline Cache Notification Banner
          ListenableBuilder(
            listenable: OfflineSyncService.instance,
            builder: (context, _) {
              final isPending = OfflineSyncService.instance.isOrderPending(order.orderId);
              if (!isPending) return const SizedBox.shrink();

              return GestureDetector(
                onTap: () => OfflineSyncModal.show(context),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF9C3),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFFDE047), width: 1.2),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.cloud_off_rounded, color: Color(0xFF854D0E), size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tersimpan di Cache Offline Kasir',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF713F12),
                              ),
                            ),
                            Text(
                              'Pesanan aman di memori Hive & otomatis dikirim saat Wi-Fi kafe pulih.',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: const Color(0xFF854D0E),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded, color: Color(0xFF854D0E), size: 18),
                    ],
                  ),
                ),
              );
            },
          ),

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
          _buildInfoRow('No. Transaksi', order.orderCode.isNotEmpty ? order.orderCode : order.orderId),
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
          // Bluetooth Printer Status & Quick Switch
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: _printerService.isConnected
                  ? AppColors.secondary.withValues(alpha: 0.1)
                  : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _printerService.isConnected
                    ? AppColors.secondary.withValues(alpha: 0.3)
                    : const Color(0xFFE2E8F0),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _printerService.isConnected ? AppColors.secondary : const Color(0xFF94A3B8),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _printerService.isConnected
                        ? 'Printer: ${_printerService.selectedDevice?.name ?? "Thermal"} (${_printerService.paperSize.label})'
                        : 'Printer Thermal belum terhubung',
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: _printerService.isConnected ? const Color(0xFF15803D) : AppColors.mutedText,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                InkWell(
                  onTap: () => PrinterSelectionModal.show(context, order: widget.order),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    child: Text(
                      _printerService.isConnected ? 'Ganti' : 'Hubungkan',
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryTeal,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isPrinting ? null : _handlePrintReceipt,
                  icon: _isPrinting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF111111)),
                        )
                      : Icon(
                          _hasPrinted ? Icons.check_circle_outline_rounded : Icons.print_rounded,
                          size: 18,
                        ),
                  label: Text(
                    _hasPrinted ? 'Cetak Ulang' : 'Cetak Struk',
                    style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF111111),
                    side: const BorderSide(color: Color(0xFF111111), width: 1.5),
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
                  onPressed: _handleShareReceipt,
                  icon: const Icon(Icons.share_outlined, size: 18),
                  label: Text(
                    'Kirim Struk',
                    style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF111111),
                    side: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
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
