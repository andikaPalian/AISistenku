import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../models/product.dart';
import 'order_review_screen.dart';
import 'widgets/pos_header.dart';
import 'widgets/pos_search_bar.dart';
import 'widgets/category_chips.dart';
import 'widgets/product_grid.dart';
import 'widgets/cart_bottom_bar.dart';

/// POS (Point of Sale) screen for taking new orders.
///
/// Displays a searchable, filterable product grid with cart functionality.
class PosScreen extends StatefulWidget {
  const PosScreen({super.key});

  @override
  State<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen> {
  ProductCategory _selectedCategory = ProductCategory.all;
  String _searchQuery = '';
  final Map<String, CartItem> _cart = {
    // Pre-populate with reference demo items for instant visual match
    '3': CartItem(
      product: ProductCatalog.items.firstWhere((p) => p.id == '3'), // Cappuccino 20k
      quantity: 1,
      variant: 'Regular',
    ),
    '6': CartItem(
      product: ProductCatalog.items.firstWhere((p) => p.id == '6'), // Croissant 15k
      quantity: 1,
      variant: 'Butter',
    ),
  };

  /// Products filtered by category and search query.
  List<Product> get _filteredProducts {
    return ProductCatalog.items.where((p) {
      final matchesCategory =
          _selectedCategory == ProductCategory.all ||
          p.category == _selectedCategory;
      final matchesSearch =
          _searchQuery.isEmpty ||
          p.name.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();
  }

  int get _totalItems =>
      _cart.values.fold(0, (sum, item) => sum + item.quantity);

  int get _totalPrice =>
      _cart.values.fold(0, (sum, item) => sum + item.subtotal);

  String get _formattedTotal => Product.formatRupiah(_totalPrice);

  void _onCategoryChanged(ProductCategory category) {
    setState(() => _selectedCategory = category);
  }

  void _onSearchChanged(String query) {
    setState(() => _searchQuery = query);
  }

  void _addToCart(Product product) {
    setState(() {
      if (_cart.containsKey(product.id)) {
        _cart[product.id]!.quantity++;
      } else {
        _cart[product.id] = CartItem(product: product);
      }
    });
  }

  void _removeFromCart(Product product) {
    setState(() {
      if (_cart.containsKey(product.id)) {
        if (_cart[product.id]!.quantity > 1) {
          _cart[product.id]!.quantity--;
        } else {
          _cart.remove(product.id);
        }
      }
    });
  }

  int _getQuantity(String productId) {
    return _cart[productId]?.quantity ?? 0;
  }

  void _navigateToOrderReview() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OrderReviewScreen(
          initialCart: _cart,
          onCartUpdated: (updatedCart) {
            setState(() {
              _cart.clear();
              _cart.addAll(updatedCart);
            });
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // ── Fixed header area ───────────────────────────
            const PosHeader(),
            const Divider(height: 1, color: AppColors.border),

            // ── Scrollable content ──────────────────────────
            Expanded(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: PosSearchBar(
                      onChanged: _onSearchChanged,
                    ),
                  ),
                  const SizedBox(height: 14),
                  CategoryChips(
                    selected: _selectedCategory,
                    onChanged: _onCategoryChanged,
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ProductGrid(
                      products: _filteredProducts,
                      getQuantity: _getQuantity,
                      onAdd: _addToCart,
                      onRemove: _removeFromCart,
                    ),
                  ),
                ],
              ),
            ),

            // ── Cart bar (only visible when items in cart) ──
            if (_totalItems > 0)
              CartBottomBar(
                itemCount: _totalItems,
                totalFormatted: _formattedTotal,
                onViewOrder: _navigateToOrderReview,
              ),
          ],
        ),
      ),
    );
  }
}
