import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../models/product.dart';
import 'checkout_screen.dart';

/// Screen for reviewing items in the cart before proceeding to checkout.
///
/// Implemented using the clean "Shopping Cart" design requested by the user.
class OrderReviewScreen extends StatefulWidget {
  final Map<String, CartItem> initialCart;
  final Function(Map<String, CartItem>) onCartUpdated;

  const OrderReviewScreen({
    super.key,
    required this.initialCart,
    required this.onCartUpdated,
  });

  @override
  State<OrderReviewScreen> createState() => _OrderReviewScreenState();
}

class _OrderReviewScreenState extends State<OrderReviewScreen> {
  late Map<String, CartItem> _cart;
  final TextEditingController _promoController = TextEditingController();
  OrderType _orderType = OrderType.dineIn; // Default: Makan di Tempat
  String _tableNumber = 'Meja 01';

  @override
  void initState() {
    super.initState();
    _cart = Map<String, CartItem>.from(widget.initialCart);
  }

  @override
  void dispose() {
    _promoController.dispose();
    super.dispose();
  }

  int get _subtotal => _cart.values.fold(0, (sum, item) => sum + item.subtotal);

  void _notifyCartChanged() {
    widget.onCartUpdated(_cart);
  }

  void _incrementItem(String productId) {
    if (_cart.containsKey(productId)) {
      setState(() {
        _cart[productId]!.quantity++;
      });
      _notifyCartChanged();
    }
  }

  void _decrementItem(String productId) {
    if (_cart.containsKey(productId)) {
      setState(() {
        if (_cart[productId]!.quantity > 1) {
          _cart[productId]!.quantity--;
        } else {
          _cart.remove(productId);
        }
      });
      _notifyCartChanged();
      if (_cart.isEmpty) {
        Navigator.pop(context);
      }
    }
  }

  void _removeItem(String productId) {
    setState(() {
      _cart.remove(productId);
    });
    _notifyCartChanged();
    
    if (_cart.isEmpty) {
      Navigator.pop(context); // Go back if empty
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), // Very light grey/off-white background matching the design
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.darkText, size: 24),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Shopping Cart',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.darkText,
          ),
        ),
      ),
      body: _cart.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.shopping_cart_outlined,
                          size: 56,
                          color: AppColors.secondary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Keranjang Masih Kosong',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.darkText,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Yuk, lihat-lihat menu dan tambahkan produk yang pelanggan pesan.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppColors.mutedText,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      height: 56,
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF111111), // Solid Black Pill
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 4,
                          shadowColor: const Color(0xFF111111).withValues(alpha: 0.3),
                        ),
                        child: Text(
                          'Kembali ke Menu',
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
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Order Type Selector (Makan di Tempat / Bawa Pulang) ──
                        _buildOrderTypeSelector(),
                        const SizedBox(height: 12),

                        // Table Selector (if Dine In)
                        if (_orderType == OrderType.dineIn) ...[
                          _buildTableSelector(),
                          const SizedBox(height: 16),
                        ],

                        const SizedBox(height: 8),

                        // ── Order Summary Title ─────────────────────────────
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Ringkasan Pesanan',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.darkText,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${_cart.values.fold(0, (s, i) => s + i.quantity)} Item',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF0F172A),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // ── Item Cards List ────────────────────────────
                        ..._cart.values.map((item) => _buildOrderItemCard(item)),

                        const SizedBox(height: 8),

                        // ── Add More Items Button ──────────────────────
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primary, // Black
                              side: const BorderSide(color: AppColors.primary, width: 1.5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30), // Pill shape
                              ),
                            ),
                            child: Text(
                              'Tambahkan Item Lain',
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),

                        // ── Discount Coupon Section ────────────────────
                        Text(
                          'Kupon Diskon',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.darkText,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 50,
                                child: TextField(
                                  controller: _promoController,
                                  decoration: InputDecoration(
                                    hintText: 'Kode Promo',
                                    hintStyle: GoogleFonts.inter(
                                      color: AppColors.mutedText,
                                      fontSize: 14,
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(25), // Pill shape
                                      borderSide: const BorderSide(color: AppColors.border, width: 1.5),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(25),
                                      borderSide: const BorderSide(color: AppColors.primary, width: 2),
                                    ),
                                    filled: true,
                                    fillColor: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            SizedBox(
                              height: 50,
                              child: ElevatedButton(
                                onPressed: () {
                                  // Apply promo code logic
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.secondary, // Vibrant Green
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(25), // Pill shape
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 24),
                                ),
                                child: Text(
                                  'Pakai',
                                  style: GoogleFonts.inter(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),

                        // ── Calculation Summary ────────────────────────
                        _buildSummaryRow('Sub total', Product.formatRupiah(_subtotal)),
                        const SizedBox(height: 12),
                        _buildSummaryRow('Biaya layanan', Product.formatRupiah(2000)), 
                        const SizedBox(height: 12),
                        _buildSummaryRow('Total', Product.formatRupiah(_subtotal + 2000), isTotal: true),
                        
                        const SizedBox(height: 100), // padding for bottom button
                      ],
                    ),
                  ),
                ),
              ],
            ),
      
      // ── Fixed Bottom Checkout Button ──────────────────────────────
      bottomSheet: _cart.isEmpty ? null : Container(
        color: const Color(0xFFF8F9FA),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CheckoutScreen(
                    items: _cart.values.toList(),
                    orderType: _orderType,
                    tableNumber: _orderType == OrderType.dineIn ? _tableNumber : null,
                    onPaymentSuccess: () {
                      widget.onCartUpdated({});
                      Navigator.pop(context); // close order review
                    },
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF111111), // Solid Black Pill
              elevation: 4,
              shadowColor: const Color(0xFF111111).withValues(alpha: 0.3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30), // Pill shape
              ),
            ),
            child: Text(
              'Lanjutkan ke Pembayaran',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOrderTypeSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9), // Subtle light slate pill background
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          // 1. Makan di Tempat (Dine In)
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _orderType = OrderType.dineIn),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _orderType == OrderType.dineIn ? const Color(0xFF111111) : Colors.transparent,
                  borderRadius: BorderRadius.circular(26),
                  boxShadow: _orderType == OrderType.dineIn
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.table_restaurant_rounded,
                      size: 18,
                      color: _orderType == OrderType.dineIn ? Colors.white : AppColors.mutedText,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Makan di Tempat',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _orderType == OrderType.dineIn ? Colors.white : AppColors.mutedText,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 2. Bawa Pulang (Take Away)
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _orderType = OrderType.takeAway),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _orderType == OrderType.takeAway ? const Color(0xFF111111) : Colors.transparent,
                  borderRadius: BorderRadius.circular(26),
                  boxShadow: _orderType == OrderType.takeAway
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.shopping_bag_outlined,
                      size: 18,
                      color: _orderType == OrderType.takeAway ? Colors.white : AppColors.mutedText,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Bawa Pulang',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _orderType == OrderType.takeAway ? Colors.white : AppColors.mutedText,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.table_bar_rounded, color: Color(0xFF22C55E), size: 20),
              const SizedBox(width: 10),
              Text(
                'Nomor Meja:',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.darkText,
                ),
              ),
            ],
          ),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _tableNumber,
              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF111111), size: 18),
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF111111),
              ),
              items: List.generate(15, (i) => 'Meja ${(i + 1).toString().padLeft(2, '0')}')
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: (val) {
                if (val != null) setState(() => _tableNumber = val);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderItemCard(CartItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24), // Neo-brutalism/soft rounded
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // ── Product Image ─────────────────
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9), // Soft grey background for product image
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.all(8),
            child: item.product.imageUrl != null && item.product.imageUrl!.isNotEmpty
                ? Image.network(
                    item.product.imageUrl!,
                    fit: BoxFit.contain,
                    errorBuilder: (ctx, err, stack) => Icon(
                      item.product.placeholderIcon ?? Icons.fastfood_rounded,
                      color: AppColors.mutedText,
                    ),
                  )
                : Icon(
                    item.product.placeholderIcon ?? Icons.local_cafe_rounded,
                    size: 32,
                    color: AppColors.mutedText,
                  ),
          ),
          const SizedBox(width: 16),

          // ── Details ───────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        item.product.name,
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.darkText,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => _removeItem(item.product.id),
                      child: const Icon(
                        Icons.close_rounded,
                        color: AppColors.mutedText,
                        size: 18,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Price
                    Text(
                      Product.formatRupiah(item.subtotal),
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF111111),
                      ),
                    ),

                    // Interactive Quantity Counter (-) [Qty] (+)
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GestureDetector(
                            onTap: () => _decrementItem(item.product.id),
                            behavior: HitTestBehavior.opaque,
                            child: Container(
                              width: 26,
                              height: 26,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 4,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: const Icon(Icons.remove_rounded, size: 14, color: Color(0xFF111111)),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Text(
                              '${item.quantity}',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.darkText,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => _incrementItem(item.product.id),
                            behavior: HitTestBehavior.opaque,
                            child: Container(
                              width: 26,
                              height: 26,
                              decoration: BoxDecoration(
                                color: AppColors.secondary, // Vibrant Green #22C55E
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.secondary.withValues(alpha: 0.3),
                                    blurRadius: 4,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: const Icon(Icons.add_rounded, size: 14, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.w700 : FontWeight.w500,
            color: isTotal ? AppColors.darkText : AppColors.mutedText,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.w700 : FontWeight.w600,
            color: AppColors.darkText,
          ),
        ),
      ],
    );
  }
}
