import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/offline_sync_service.dart';
import '../../models/product.dart';
import '../../models/finance_model.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'payment_success_screen.dart';

/// Checkout and Payment method selection screen.
///
/// Matches the reference design with expandable Order Summary,
/// payment method selection cards (Cash, QRIS, Card), and cash change calculator.
class CheckoutScreen extends StatefulWidget {
  final List<CartItem> items;
  final OrderType orderType;
  final String? tableNumber;
  final VoidCallback onPaymentSuccess;

  const CheckoutScreen({
    super.key,
    required this.items,
    required this.orderType,
    this.tableNumber,
    required this.onPaymentSuccess,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  PaymentMethodType _selectedMethod = PaymentMethodType.cash;
  bool _isProcessing = false;

  // Cash payment variables
  int _cashGiven = 0;
  final TextEditingController _cashInputController = TextEditingController();

  int get _subtotal =>
      widget.items.fold(0, (sum, item) => sum + item.subtotal);

  // PB1 Tax (0% or 10% - for demo we keep it 0 for exact match with Rp35k/55k total)
  int get _tax => 0;

  int get _total => _subtotal + _tax;

  int get _change => (_cashGiven > _total) ? (_cashGiven - _total) : 0;

  @override
  void initState() {
    super.initState();
    // Default cash given to exact total
    _cashGiven = _total;
    _cashInputController.text = _total.toString();
  }

  @override
  void dispose() {
    _cashInputController.dispose();
    super.dispose();
  }

  void _selectQuickCash(int amount) {
    setState(() {
      _cashGiven = amount;
      _cashInputController.text = amount.toString();
    });
  }

  void _processPayment() async {
    setState(() => _isProcessing = true);

    // Simulate payment processing delay
    await Future.delayed(const Duration(milliseconds: 700));

    if (!mounted) return;

    final orderRecord = OrderRecord(
      orderId: '#TRX-${DateTime.now().year}${DateTime.now().month.toString().padLeft(2, '0')}${DateTime.now().day.toString().padLeft(2, '0')}-${(1000 + (DateTime.now().millisecond % 900)).toString()}',
      items: widget.items,
      orderType: widget.orderType,
      tableNumber: widget.tableNumber,
      paymentMethod: _selectedMethod,
      subtotal: _subtotal,
      tax: _tax,
      total: _total,
      cashGiven: _selectedMethod == PaymentMethodType.cash ? _cashGiven : _total,
      change: _selectedMethod == PaymentMethodType.cash ? _change : 0,
      createdAt: DateTime.now(),
    );

    // Auto-record POS sale to Finance
    final cleanTableStr = widget.tableNumber != null
        ? ' • Meja ${widget.tableNumber!.replaceAll(RegExp(r'^Meja\s*', caseSensitive: false), '').trim()}'
        : '';

    FinanceRepository.instance.addTransaction(
      title: 'Penjualan Kasir (${widget.items.length} item)',
      type: TransactionType.income,
      category: FinanceCategory.sales,
      amount: _total.toDouble(),
      source: TransactionSource.posAutomatic,
      notes: '${widget.orderType.label}$cleanTableStr • ${_selectedMethod.label}',
      timestamp: DateTime.now(),
    );

    // Auto-deduct sold product stock immediately
    for (final it in widget.items) {
      ProductRepository.instance.deductStock(it.product.id, it.quantity);
    }

    String backendOrderType = widget.orderType == OrderType.takeAway ? 'TakeAway' : 'DineIn';
    String backendPaymentMethod = 'Cash';
    if (_selectedMethod == PaymentMethodType.qris) {
      backendPaymentMethod = 'QRIS_EWallet';
    } else if (_selectedMethod == PaymentMethodType.card) {
      backendPaymentMethod = 'DebitCreditCard';
    }

    // Prepare Backend Order payload
    final orderPayload = {
      'orderCode': orderRecord.orderCode,
      'order_code': orderRecord.orderCode,
      'orderType': backendOrderType,
      'order_type': backendOrderType,
      'tableNumber': widget.tableNumber,
      'table_number': widget.tableNumber,
      'customerName': 'Pelanggan POS',
      'customer_name': 'Pelanggan POS',
      'paymentMethod': backendPaymentMethod,
      'payment_method': backendPaymentMethod,
      'subtotal': _subtotal,
      'tax': _tax,
      'totalAmount': _total,
      'total_amount': _total,
      'cashGiven': _selectedMethod == PaymentMethodType.cash ? _cashGiven : _total,
      'cash_given': _selectedMethod == PaymentMethodType.cash ? _cashGiven : _total,
      'changeAmount': _selectedMethod == PaymentMethodType.cash ? _change : 0,
      'change': _selectedMethod == PaymentMethodType.cash ? _change : 0,
      'items': widget.items.map((it) {
        return {
          'productId': it.product.id,
          'product_id': it.product.id,
          'productName': it.product.name,
          'product_name': it.product.name,
          'name': it.product.name,
          'quantity': it.quantity,
          'price': it.product.price,
          'unit_price': it.product.price,
          'subtotal': it.subtotal,
          'variant': it.variant,
        };
      }).toList(),
    };

    // Save to Local Database Cache (Hive) immediately & flush to server if Wi-Fi active
    unawaited(OfflineSyncService.instance.processAndQueueOrder(
      order: orderRecord,
      backendPayload: orderPayload,
    ));

    setState(() => _isProcessing = false);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentSuccessScreen(
          order: orderRecord,
          onNewTransaction: () {
            try {
              widget.onPaymentSuccess();
            } catch (_) {}
          },
        ),
      ),
    );
  }

  void _showQrisModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0), // Clean slate handle
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Scan QRIS untuk Membayar',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.darkText,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Mendukung GoPay, OVO, Dana, ShopeePay, BCA, Mandiri dll',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.mutedText,
                ),
              ),
              const SizedBox(height: 20),
              // QR Code Card Container
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08), // Increased shadow to pop
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.qr_code_2_rounded, color: AppColors.darkText, size: 24),
                        const SizedBox(width: 8),
                        Text(
                          'QRIS STATIS / DINAMIS',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.1,
                            color: AppColors.darkText,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Real QR Box
                    Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: QrImageView(
                        data: 'https://qris.id/tiga-angkatan-coffee/$_total',
                        version: QrVersions.auto,
                        size: 200.0,
                        backgroundColor: Colors.white,
                        eyeStyle: const QrEyeStyle(
                          eyeShape: QrEyeShape.square,
                          color: Color(0xFF0F172A),
                        ),
                        dataModuleStyle: const QrDataModuleStyle(
                          dataModuleShape: QrDataModuleShape.square,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      Product.formatRupiah(_total),
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: AppColors.darkText, // Dark text for premium look
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 56, // Slightly taller
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _processPayment();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF111111), // Solid Black Pill
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 4,
                    shadowColor: const Color(0xFF111111).withValues(alpha: 0.3),
                  ),
                  child: Text(
                    'Konfirmasi QRIS Diterima',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111111), // Dark top background matching reference
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // ── Dark Top Navigation Bar (Header) ─────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white, size: 22),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Text(
                    'Tiga Angkatan - Kartasura',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.menu_rounded, color: Colors.white, size: 22),
                    onPressed: () {},
                  ),
                ],
              ),
            ),

            const SizedBox(height: 6),

            // ── White Curved Sheet Overlay (Radius 32) ───────────
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                  child: Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 1. Heading "Checkout"
                              Text(
                                'Checkout',
                                style: GoogleFonts.poppins(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.darkText,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 16),

                              // 2. Delivery / Order Route Preview Snippet
                              _buildRouteTrackerCard(),
                              const SizedBox(height: 18),

                              // 3. Delivery Time / Estimasi Saji
                              _buildDeliveryTimeRow(),
                              const SizedBox(height: 16),

                              // 4. Promotion Applied Banner (Vibrant Green)
                              _buildPromotionBanner(),
                              const SizedBox(height: 20),

                              // 5. Payment Selector Row
                              _buildPaymentMethodSelector(),
                              const SizedBox(height: 16),

                              // Cash Helper if Cash selected
                              if (_selectedMethod == PaymentMethodType.cash) ...[
                                _buildCashHelperCard(),
                                const SizedBox(height: 16),
                              ],

                              // QRIS Helper if QRIS selected
                              if (_selectedMethod == PaymentMethodType.qris) ...[
                                _buildQrisActionBanner(),
                                const SizedBox(height: 16),
                              ],

                              // Card Helper if Card selected
                              if (_selectedMethod == PaymentMethodType.card) ...[
                                _buildCardActionBanner(),
                                const SizedBox(height: 16),
                              ],

                              const SizedBox(height: 8),

                              // 6. Your Items Section with Green Price Pills
                              _buildYourItemsSection(),
                              const SizedBox(height: 24),

                              // 7. Summary Breakdown
                              _buildOrderBreakdown(),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),

      // ── Fixed Bottom Checkout Button (Black Pill: Order : Rp...) ──
      bottomSheet: Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
        child: SafeArea(
          top: false,
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _isProcessing ? null : _processPayment,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF111111), // Solid Black Pill
                foregroundColor: Colors.white,
                elevation: 4,
                shadowColor: const Color(0xFF111111).withValues(alpha: 0.3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30), // Full Pill
                ),
              ),
              child: _isProcessing
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : Text(
                      'Order : ${Product.formatRupiah(_total)}',
                      style: GoogleFonts.poppins(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  /// Map / Route Tracker snippet card matching Screen 3
  Widget _buildRouteTrackerCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9), // Light map background slate
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          // Store Pin Icon
          Container(
            width: 38,
            height: 38,
            decoration: const BoxDecoration(
              color: Color(0xFFFEF3C7), // Light amber circle
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(Icons.coffee_rounded, color: Color(0xFFD97706), size: 20),
            ),
          ),

          // Connecting Green Route Line
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 3,
                      decoration: BoxDecoration(
                        color: const Color(0xFF22C55E), // Vibrant Green line
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Destination / Table Pin Icon
          Container(
            width: 38,
            height: 38,
            decoration: const BoxDecoration(
              color: Color(0xFFDCFCE7), // Light green circle
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(
                widget.orderType == OrderType.dineIn
                    ? Icons.table_restaurant_rounded
                    : Icons.shopping_bag_outlined,
                color: const Color(0xFF16A34A),
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Order Type & Table row with green pill badge matching Screen 3
  Widget _buildDeliveryTimeRow() {
    final isDineIn = widget.orderType == OrderType.dineIn;
    final orderText = isDineIn
        ? (widget.tableNumber != null ? 'Makan di Tempat • ${widget.tableNumber}' : 'Makan di Tempat')
        : 'Bawa Pulang (Take Away)';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Tipe Pesanan',
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.darkText,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFDCFCE7), // Light Green Pill
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isDineIn ? Icons.check_circle_rounded : Icons.shopping_bag_rounded,
                color: const Color(0xFF16A34A),
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                orderText,
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF16A34A),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Vibrant Green Promotion Applied banner matching Screen 3
  Widget _buildPromotionBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF22C55E), // Vibrant Green Banner
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF22C55E).withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.local_offer_rounded, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 12),

          // Promotion text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Promotion applied',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                Text(
                  '-Rp 5.000 (10%)',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),

          // "View all >" pill button
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'View all',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF111111),
                  ),
                ),
                const SizedBox(width: 2),
                const Icon(Icons.chevron_right_rounded, size: 16, color: Color(0xFF111111)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Payment selector row with pill dropdown matching Screen 3
  Widget _buildPaymentMethodSelector() {
    String methodLabel = 'Cash';
    IconData methodIcon = Icons.payments_rounded;
    if (_selectedMethod == PaymentMethodType.qris) {
      methodLabel = 'QRIS';
      methodIcon = Icons.qr_code_2_rounded;
    } else if (_selectedMethod == PaymentMethodType.card) {
      methodLabel = 'Debit Card';
      methodIcon = Icons.credit_card_rounded;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Payment',
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.darkText,
          ),
        ),
        GestureDetector(
          onTap: _showPaymentPickerModal,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(methodIcon, color: const Color(0xFF111111), size: 18),
                const SizedBox(width: 8),
                Text(
                  methodLabel,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF111111),
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: Color(0xFF111111)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showPaymentPickerModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
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
              const SizedBox(height: 18),
              Text(
                'Pilih Metode Pembayaran',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.darkText,
                ),
              ),
              const SizedBox(height: 16),
              _buildPaymentOptionTile(PaymentMethodType.cash, 'Cash / Tunai', Icons.payments_rounded),
              const SizedBox(height: 10),
              _buildPaymentOptionTile(PaymentMethodType.qris, 'QRIS / E-Wallet', Icons.qr_code_2_rounded),
              const SizedBox(height: 10),
              _buildPaymentOptionTile(PaymentMethodType.card, 'Debit / Credit Card', Icons.credit_card_rounded),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPaymentOptionTile(PaymentMethodType method, String title, IconData icon) {
    final isSelected = _selectedMethod == method;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedMethod = method);
        Navigator.pop(context);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF1F5F9) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFF111111) : const Color(0xFFE2E8F0),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF111111), size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.darkText,
                ),
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle_rounded, color: Color(0xFF22C55E), size: 20),
          ],
        ),
      ),
    );
  }

  /// "Your items" section with "+ Add Items" and Green Price Pills matching Screen 3
  Widget _buildYourItemsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Your items',
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.darkText,
              ),
            ),
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Text(
                '+ Add Items',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF111111),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // List of items
        ...widget.items.map((item) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    '${item.quantity > 1 ? "${item.quantity}x " : ""}${item.product.name}',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.darkText,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 12),
                // Green Price Pill matching Screen 3
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF22C55E), // Vibrant Green Pill
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    Product.formatRupiah(item.subtotal),
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildOrderBreakdown() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Subtotal', style: GoogleFonts.inter(fontSize: 13, color: AppColors.mutedText)),
              Text(Product.formatRupiah(_subtotal), style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.darkText)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Diskon Promo', style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF22C55E), fontWeight: FontWeight.w600)),
              Text('-Rp 0', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF22C55E))),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total Tagihan', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.darkText)),
              Text(Product.formatRupiah(_total), style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.darkText)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCashHelperCard() {
    // Generate helpful quick cash suggestions: exact, 50k, 100k, 200k
    final quickNominals = <int>[
      _total,
      if (_total < 50000) 50000,
      if (_total < 100000) 100000,
      if (_total < 200000) 200000,
    ].toSet().toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 6),
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
                'Nominal Uang Tunai',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
              if (_change > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    'Kembalian: ${Product.formatRupiah(_change)}',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.secondary,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          // Manual input
          TextField(
            controller: _cashInputController,
            keyboardType: TextInputType.number,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.darkText,
            ),
            decoration: InputDecoration(
              prefixText: 'Rp ',
              prefixStyle: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.darkText,
              ),
              filled: true,
              fillColor: const Color(0xFFF1F5F9),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(25), // Pill shape
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            ),
            onChanged: (val) {
              final parsed = int.tryParse(val.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
              setState(() => _cashGiven = parsed);
            },
          ),
          const SizedBox(height: 16),
          // Quick nominal suggestion chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: quickNominals.map((amount) {
              final isExact = amount == _total;
              final isSelected = _cashGiven == amount;
              return ChoiceChip(
                label: Text(
                  isExact ? 'Uang Pas (${Product.formatRupiah(amount)})' : Product.formatRupiah(amount),
                ),
                selected: isSelected,
                selectedColor: AppColors.primary, // Black selected state
                backgroundColor: const Color(0xFFF1F5F9),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20), // Pill chip
                ),
                side: const BorderSide(
                  color: Colors.transparent,
                  width: 0,
                ),
                showCheckmark: false, // Cleaner without checkmark
                labelStyle: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : AppColors.darkText,
                ),
                onSelected: (selected) {
                  if (selected) _selectQuickCash(amount);
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildQrisActionBanner() {
    return GestureDetector(
      onTap: _showQrisModal,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.qr_code_rounded, color: AppColors.primary, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tampilkan Kode QRIS',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.darkText,
                    ),
                  ),
                  Text(
                    'QR statis & dinamis untuk pelanggan',
                    style: GoogleFonts.inter(fontSize: 12, color: AppColors.mutedText),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppColors.mutedText),
          ],
        ),
      ),
    );
  }

  Widget _buildCardActionBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.credit_card_rounded, color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Siapkan Mesin EDC',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.darkText,
                  ),
                ),
                Text(
                  'Mendukung Debit & Credit Card',
                  style: GoogleFonts.inter(fontSize: 12, color: AppColors.mutedText),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
