import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/product.dart';
import 'add_edit_product_modal.dart';

/// Individual product card in the POS grid.
///
/// Features:
/// - High-resolution network product image with fallback icon
/// - Category pill badge & item code
/// - Sisa stock indicator (with low stock warning)
/// - Product name & formatted price
/// - Quick Add / Stepper counter button
class ProductCard extends StatelessWidget {
  final Product product;
  final int quantity;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onIncrement;
  final VoidCallback? onDecrement;

  const ProductCard({
    super.key,
    required this.product,
    required this.quantity,
    required this.onTap,
    this.onLongPress,
    this.onIncrement,
    this.onDecrement,
  });

  bool get _isInCart => quantity > 0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _isInCart ? AppColors.primaryTeal : Colors.transparent,
            width: _isInCart ? 2 : 0,
          ),
          boxShadow: [
            BoxShadow(
              color: _isInCart
                  ? AppColors.primaryTeal.withValues(alpha: 0.15)
                  : Colors.black.withValues(alpha: 0.04),
              blurRadius: _isInCart ? 12 : 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── 1. Product Image Banner ─────────────────────
              Expanded(
                flex: 11,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Network / Base64 / Fallback Image
                    _buildProductImage(),

                    // Category Pill Tag (Top-Left)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          product.category.label,
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),

                    // Edit Pencil Button (Top-Right when not in cart)
                    if (!_isInCart)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: GestureDetector(
                          onTap: () => AddEditProductModal.show(context, product: product),
                          child: Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.9),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.15),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.edit_outlined,
                              size: 13,
                              color: AppColors.primaryTeal,
                            ),
                          ),
                        ),
                      ),

                    // Quantity Badge (Top-Right when in cart)
                    if (_isInCart)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            color: AppColors.primaryTeal,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primaryTeal.withValues(alpha: 0.4),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              quantity.toString(),
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // ── 2. Product Details Body ─────────────────────
              Expanded(
                flex: 10,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Product Name & Stock
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.name,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.darkText,
                              height: 1.25,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          // Stock count badge
                          Row(
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: product.isLowStock
                                      ? AppColors.destructive
                                      : AppColors.successGreen,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Sisa: ${product.stock} ${product.unit}',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color: product.isLowStock
                                      ? AppColors.destructive
                                      : AppColors.mutedText,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      // Price & Action Button
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Price
                          Expanded(
                            child: Text(
                              product.formattedPrice,
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF0F172A),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),

                          // Add / Quantity Stepper
                          if (_isInCart)
                            Container(
                              height: 28,
                              decoration: BoxDecoration(
                                color: AppColors.primaryTeal.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: AppColors.primaryTeal.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  InkWell(
                                    onTap: onDecrement ?? onTap,
                                    borderRadius: const BorderRadius.horizontal(
                                      left: Radius.circular(7),
                                    ),
                                    child: const Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 4,
                                      ),
                                      child: Icon(
                                        Icons.remove_rounded,
                                        size: 14,
                                        color: AppColors.primaryTeal,
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                    ),
                                    child: Text(
                                      quantity.toString(),
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.primaryTeal,
                                      ),
                                    ),
                                  ),
                                  InkWell(
                                    onTap: onIncrement ?? onTap,
                                    borderRadius: const BorderRadius.horizontal(
                                      right: Radius.circular(7),
                                    ),
                                    child: const Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 4,
                                      ),
                                      child: Icon(
                                        Icons.add_rounded,
                                        size: 14,
                                        color: AppColors.primaryTeal,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            InkWell(
                              onTap: onTap,
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.transparent,
                                  border: Border.all(color: const Color(0xFFE2E8F0)),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.add_rounded,
                                      size: 14,
                                      color: Color(0xFF0F172A),
                                    ),
                                    const SizedBox(width: 2),
                                    Text(
                                      'Tambah',
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF0F172A),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductImage() {
    final imgUrl = product.imageUrl;
    if (imgUrl == null || imgUrl.isEmpty) {
      return _buildFallbackImage();
    }

    if (imgUrl.startsWith('data:image')) {
      try {
        final commaIdx = imgUrl.indexOf(',');
        final base64Data = commaIdx != -1 ? imgUrl.substring(commaIdx + 1) : imgUrl;
        final bytes = base64Decode(base64Data);
        return Image.memory(
          bytes,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildFallbackImage(),
        );
      } catch (_) {
        return _buildFallbackImage();
      }
    }

    return Image.network(
      imgUrl,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          color: AppColors.surface,
          child: const Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppColors.primaryTeal,
                ),
              ),
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) => _buildFallbackImage(),
    );
  }

  Widget _buildFallbackImage() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFE2E8F0), Color(0xFFCBD5E1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(
          product.placeholderIcon ?? Icons.coffee_rounded,
          size: 36,
          color: AppColors.mutedText.withValues(alpha: 0.5),
        ),
      ),
    );
  }
}

