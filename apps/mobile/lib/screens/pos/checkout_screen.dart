import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../models/product.dart';
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
  bool _isSummaryExpanded = false;
  bool _isProcessing = false;

  // Cash payment variables
  int _cashGiven = 0;
  final TextEditingController _cashInputController = TextEditingController();

  int get _totalItems =>
      widget.items.fold(0, (sum, item) => sum + item.quantity);

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

    setState(() => _isProcessing = false);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentSuccessScreen(
          order: orderRecord,
          onNewTransaction: () {
            widget.onPaymentSuccess();
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
                  color: AppColors.border,
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
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.lightTealBorder, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryTeal.withOpacity(0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.qr_code_2_rounded, color: AppColors.primaryTeal, size: 24),
                        const SizedBox(width: 8),
                        Text(
                          'QRIS STATIS / DINAMIS',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.1,
                            color: AppColors.primaryTeal,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Mock QR Box
                    Container(
                      width: 180,
                      height: 180,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.qr_code_rounded,
                          size: 140,
                          color: AppColors.darkText,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      Product.formatRupiah(_total),
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryTeal,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _processPayment();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryTeal,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    'Konfirmasi QRIS Diterima',
                    style: GoogleFonts.inter(
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
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(
        backgroundColor: AppColors.pageBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.darkText, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Checkout',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.darkText,
          ),
        ),
        centerTitle: true,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppColors.border),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Hero Total Amount ────────────────────────────
                  Center(
                    child: Column(
                      children: [
                        Text(
                          'Total Amount',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: AppColors.mutedText,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          Product.formatRupiah(_total),
                          style: GoogleFonts.poppins(
                            fontSize: 34,
                            fontWeight: FontWeight.w800,
                            color: AppColors.darkText,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Expandable Order Summary Card ────────────────
                  _buildOrderSummaryCard(),

                  const SizedBox(height: 28),

                  // ── Payment Method Section ───────────────────────
                  Text(
                    'Payment Method',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.darkText,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 1. Cash Card
                  _buildPaymentOptionCard(
                    method: PaymentMethodType.cash,
                    icon: Icons.payments_outlined,
                    title: 'Cash',
                  ),
                  const SizedBox(height: 12),

                  // 2. QRIS Card
                  _buildPaymentOptionCard(
                    method: PaymentMethodType.qris,
                    icon: Icons.qr_code_scanner_rounded,
                    title: 'QRIS / E-Wallet',
                  ),
                  const SizedBox(height: 12),

                  // 3. Card Option
                  _buildPaymentOptionCard(
                    method: PaymentMethodType.card,
                    icon: Icons.credit_card_rounded,
                    title: 'Debit / Credit Card',
                  ),

                  // ── Cash Calculations Helper (when Cash selected) ─
                  if (_selectedMethod == PaymentMethodType.cash) ...[
                    const SizedBox(height: 16),
                    _buildCashHelperCard(),
                  ],

                  // ── QRIS Helper (when QRIS selected) ──────────────
                  if (_selectedMethod == PaymentMethodType.qris) ...[
                    const SizedBox(height: 16),
                    _buildQrisActionBanner(),
                  ],

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // ── Bottom Action Button ─────────────────────────────────
          _buildBottomAction(),
        ],
      ),
    );
  }

  Widget _buildOrderSummaryCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.lightTealBorder, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _isSummaryExpanded = !_isSummaryExpanded),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primaryTeal,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.shopping_bag_outlined,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Order Summary',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.darkText,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$_totalItems Items ${widget.tableNumber != null ? "• ${widget.tableNumber}" : ""}',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppColors.mutedText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: _isSummaryExpanded ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: AppColors.darkText,
                      size: 26,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Collapsible Items List
          if (_isSummaryExpanded) ...[
            const Divider(height: 1, color: AppColors.border),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                children: [
                  ...widget.items.map((item) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.tealBackgrounds,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '${item.quantity}x',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primaryTeal,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                item.product.name,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.darkText,
                                ),
                              ),
                            ],
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
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPaymentOptionCard({
    required PaymentMethodType method,
    required IconData icon,
    required String title,
  }) {
    final isSelected = _selectedMethod == method;

    return GestureDetector(
      onTap: () => setState(() => _selectedMethod = method),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primaryTeal : AppColors.lightTealBorder,
            width: isSelected ? 2 : 1.2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primaryTeal.withOpacity(0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Row(
          children: [
            // Icon container
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.tealBackgrounds : AppColors.surface,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isSelected ? AppColors.primaryTeal : AppColors.darkText,
                size: 22,
              ),
            ),
            const SizedBox(width: 16),
            // Title
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.darkText,
                ),
              ),
            ),
            // Radio button circle
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppColors.primaryTeal : Colors.grey.shade400,
                  width: isSelected ? 6 : 2,
                ),
              ),
            ),
          ],
        ),
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
        color: AppColors.tealBackgrounds,
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
                'Nominal Uang Tunai',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryTeal,
                ),
              ),
              if (_change > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.successGreen.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Kembalian: ${Product.formatRupiah(_change)}',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.successGreen,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
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
                selectedColor: AppColors.primaryTeal,
                backgroundColor: Colors.white,
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
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.tealBackgrounds,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.lightTealBorder),
        ),
        child: Row(
          children: [
            const Icon(Icons.qr_code_rounded, color: AppColors.primaryTeal, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tampilkan Kode QRIS',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryTeal,
                    ),
                  ),
                  Text(
                    'Tekan untuk menampilkan QR dinamis ke pelanggan',
                    style: GoogleFonts.inter(fontSize: 11, color: AppColors.mutedText),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.primaryTeal),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomAction() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: _isProcessing ? null : _processPayment,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryTeal,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
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
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Selesaikan Pembayaran',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward_rounded, size: 20),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
