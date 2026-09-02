import 'package:flutter/material.dart';
import '../../../models/product.dart';
import 'product_card.dart';

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
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.search_off_rounded,
                size: 48,
                color: Colors.grey.shade300,
              ),
              const SizedBox(height: 12),
              Text(
                'Menu tidak ditemukan',
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      physics: const BouncingScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: 0.72,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        final qty = getQuantity(product.id);
        return ProductCard(
          product: product,
          quantity: qty,
          onTap: () => onAdd(product),
          onIncrement: () => onAdd(product),
          onDecrement: () => onRemove(product),
          onLongPress: qty > 0 ? () => onRemove(product) : null,
        );
      },
    );
  }
}
