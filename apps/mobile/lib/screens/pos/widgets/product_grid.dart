import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/product.dart';
import 'product_card.dart';
import 'add_edit_product_modal.dart';

/// 3-column grid of product cards matching the POS reference design.
class ProductGrid extends StatelessWidget {
  final List<Product> products;
  final int Function(String productId) getQuantity;
  final ValueChanged<Product> onAdd;
  final ValueChanged<Product> onRemove;

  const ProductGrid({
    super.key,
    required this.products,
    required this.getQuantity,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.tealBackgrounds,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.restaurant_menu_rounded,
                  size: 36,
                  color: AppColors.primaryTeal,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Belum Ada Menu Produk',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.darkText,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Tambahkan produk pertama Anda dengan foto, harga, dan stok untuk mulai bertransaksi.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.mutedText,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 18),
              ElevatedButton.icon(
                onPressed: () => AddEditProductModal.show(context),
                icon: const Icon(Icons.add_photo_alternate_rounded, size: 18),
                label: Text(
                  'Tambah Menu Pertama',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryTeal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 220), // Increased to clear both floating bars
      physics: const BouncingScrollPhysics(),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        final qty = getQuantity(product.id);
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: ProductCard(
            product: product,
            quantity: qty,
            onTap: () => onAdd(product),
            onIncrement: () => onAdd(product),
            onDecrement: () => onRemove(product),
            onLongPress: qty > 0 ? () => onRemove(product) : null,
          ),
        );
      },
    );
  }
}
