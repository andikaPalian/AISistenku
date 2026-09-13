import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../models/product.dart';
import '../../models/stock_model.dart';
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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ProductRepository.instance.fetchProductsFromBackend();
    });
  }

  ProductCategory _selectedCategory = ProductCategory.all;
  String _searchQuery = '';
  final Map<String, CartItem> _cart = {};

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
        child: AnimatedBuilder(
          animation: Listenable.merge([
            ProductRepository.instance,
            StockRepository.instance,
          ]),
          builder: (context, _) {
            final products = _filteredProducts;
            return Column(
              children: [
                // ── Fixed header area ───────────────────────────
                const PosHeader(),
                const Divider(height: 1, color: AppColors.lightTealBorder),

                // ── Scrollable content & Floating Cart ──────────
                Expanded(
                  child: Stack(
                    children: [
                      Column(
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
                              products: products,
                              getQuantity: _getQuantity,
                              onAdd: _addToCart,
                              onRemove: _removeFromCart,
                            ),
                          ),
                        ],
                      ),

                      // ── Cart bar (floating neatly above bottom nav) ──
                      if (_totalItems > 0)
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: CartBottomBar(
                            itemCount: _totalItems,
                            totalFormatted: _formattedTotal,
                            onViewOrder: _navigateToOrderReview,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
