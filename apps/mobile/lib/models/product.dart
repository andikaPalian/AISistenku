import 'package:flutter/material.dart';
import '../core/services/api_service.dart';
import 'stock_model.dart';

/// Product category for filtering.
enum ProductCategory {
  all('All'),
  kopi('Kopi'),
  nonKopi('Non-Kopi'),
  snack('Snack'),
  makanan('Makanan');

  final String label;
  const ProductCategory(this.label);
}

/// Order dining type.
enum OrderType {
  dineIn('Dine In', 'Makan di tempat'),
  takeAway('Take Away', 'Bawa pulang');

  final String label;
  final String description;
  const OrderType(this.label, this.description);
}

/// Payment method types.
enum PaymentMethodType {
  cash('Cash', 'Tunai', Icons.payments_outlined),
  qris('QRIS / E-Wallet', 'GoPay, OVO, Dana, ShopeePay', Icons.qr_code_scanner_rounded),
  card('Debit / Credit Card', 'BCA, Mandiri, BRI, Visa/Mastercard', Icons.credit_card_rounded);

  final String label;
  final String subtitle;
  final IconData icon;
  const PaymentMethodType(this.label, this.subtitle, this.icon);
}

/// Represents a menu item in the POS system.
class Product {
  final String id;
  final String? code;
  final String name;
  final int price;
  final ProductCategory category;
  final String defaultVariant;
  final String? imageUrl;
  final int stock;
  final int minStock;
  final String unit;
  final IconData? placeholderIcon;

  const Product({
    required this.id,
    this.code,
    required this.name,
    required this.price,
    required this.category,
    this.defaultVariant = 'Regular',
    this.imageUrl,
    this.stock = 20,
    this.minStock = 5,
    this.unit = 'cup',
    this.placeholderIcon,
  });

  bool get isLowStock => stock <= minStock;

  /// Format price as Indonesian Rupiah (e.g. "Rp15.000").
  String get formattedPrice => formatRupiah(price);

  static String formatRupiah(int amount) {
    final str = amount.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) buffer.write('.');
      buffer.write(str[i]);
    }
    return 'Rp$buffer';
  }

  Product copyWith({
    String? id,
    String? code,
    String? name,
    int? price,
    ProductCategory? category,
    String? defaultVariant,
    String? imageUrl,
    int? stock,
    int? minStock,
    String? unit,
    IconData? placeholderIcon,
  }) {
    return Product(
      id: id ?? this.id,
      code: code ?? this.code,
      name: name ?? this.name,
      price: price ?? this.price,
      category: category ?? this.category,
      defaultVariant: defaultVariant ?? this.defaultVariant,
      imageUrl: imageUrl ?? this.imageUrl,
      stock: stock ?? this.stock,
      minStock: minStock ?? this.minStock,
      unit: unit ?? this.unit,
      placeholderIcon: placeholderIcon ?? this.placeholderIcon,
    );
  }
}

/// Represents an item added to the cart with quantity and options.
class CartItem {
  final Product product;
  int quantity;
  String variant;
  String? note;

  CartItem({
    required this.product,
    this.quantity = 1,
    this.variant = 'Regular',
    this.note,
  });

  int get subtotal => product.price * quantity;
  String get formattedSubtotal => Product.formatRupiah(subtotal);
}

/// Order data model matching POS transactions.
class OrderRecord {
  final String orderId;
  final String orderCode;
  final OrderType orderType;
  final String? tableNumber;
  final String? customerName;
  final List<CartItem> items;
  final int subtotal;
  final int tax;
  final int total;
  final PaymentMethodType paymentMethod;
  final int cashGiven;
  final int change;
  final String status;
  final DateTime createdAt;

  const OrderRecord({
    required this.orderId,
    this.orderCode = '#3A-88895',
    required this.orderType,
    this.tableNumber,
    this.customerName,
    required this.items,
    required this.subtotal,
    required this.tax,
    required this.total,
    required this.paymentMethod,
    this.cashGiven = 0,
    this.change = 0,
    this.status = 'PAID',
    required this.createdAt,
  });
}

/// Repository & state manager for products in the POS catalog.
class ProductRepository extends ChangeNotifier {
  static final ProductRepository instance = ProductRepository._internal();
  ProductRepository._internal() {
    _products = List.from(ProductCatalog.defaultSeedItems);
  }

  List<Product> _products = [];
  List<Product> get products => List.unmodifiable(_products);

  void clearForNewUser() {
    _products = [];
    notifyListeners();
  }

  void loadDemoProducts() {
    _products = List.from(ProductCatalog.defaultSeedItems);
    notifyListeners();
  }

  void setProducts(List<Product> newProducts) {
    _products = List.from(newProducts);
    notifyListeners();
  }

  Future<void> fetchProductsFromBackend() async {
    try {
      final res = await ApiService.instance.get('/products');
      if (res != null && res['products'] is List) {
        final List list = res['products'];
        final List<Product> loaded = [];
        for (final item in list) {
          ProductCategory cat = ProductCategory.kopi;
          final catStr = (item['category'] ?? '').toString().toLowerCase();
          if (catStr.contains('non')) {
            cat = ProductCategory.nonKopi;
          } else if (catStr.contains('snack')) {
            cat = ProductCategory.snack;
          } else if (catStr.contains('makan')) {
            cat = ProductCategory.makanan;
          }

          loaded.add(Product(
            id: (item['product_id'] ?? item['id'] ?? 'prod-${DateTime.now().millisecondsSinceEpoch}').toString(),
            code: item['code'],
            name: (item['name'] ?? 'Menu').toString(),
            price: (item['price'] as num?)?.toInt() ?? 0,
            category: cat,
            stock: (item['current_stock'] as num?)?.toInt() ?? (item['stock'] as num?)?.toInt() ?? 20,
            minStock: (item['min_stock'] as num?)?.toInt() ?? 5,
            unit: (item['unit'] ?? 'cup').toString(),
            imageUrl: item['image_url'],
            defaultVariant: (item['default_variant'] ?? 'Regular').toString(),
            placeholderIcon: Icons.coffee_rounded,
          ));
        }
        _products = loaded;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('⚠️ fetchProductsFromBackend error: $e');
    }
  }

  void addProduct(Product product) {
    _products.insert(0, product);
    notifyListeners();
    // Sync to backend
    ApiService.instance.post('/products', {
      'name': product.name,
      'price': product.price,
      'code': product.code,
      'category': product.category.label,
      'stock': product.stock,
      'min_stock': product.minStock,
      'unit': product.unit,
      'default_variant': product.defaultVariant,
      'image_url': product.imageUrl,
    }).catchError((_) => null);

    // Auto-create matching stock item so it appears in inventory
    try {
      StockCategory stockCat = StockCategory.bahanBaku;
      if (product.category == ProductCategory.makanan || product.category == ProductCategory.snack) {
        stockCat = StockCategory.makanan;
      } else if (product.category == ProductCategory.kopi) {
        stockCat = StockCategory.kopi;
      }

      final stockItem = StockItem(
        id: 'stock-${product.id}',
        name: product.name,
        category: stockCat,
        currentStock: product.stock.toDouble(),
        minStock: product.minStock.toDouble(),
        unit: product.unit,
        costPerUnit: (product.price * 0.4).toInt(),
        sellingPrice: product.price,
        isPosProduct: true,
        lastUpdated: DateTime.now(),
        supplier: 'Internal',
        icon: product.placeholderIcon ?? Icons.inventory_2_rounded,
      );
      StockRepository.instance.addStockItem(stockItem);
    } catch (e) {
      debugPrint('Error auto-syncing product to stock: $e');
    }
  }

  void updateProduct(Product updated) {
    final idx = _products.indexWhere((p) => p.id == updated.id);
    if (idx != -1) {
      _products[idx] = updated;
      notifyListeners();
    }
    // Sync to backend
    ApiService.instance.put('/products/${updated.id}', {
      'name': updated.name,
      'price': updated.price,
      'code': updated.code,
      'category': updated.category.label,
      'stock': updated.stock,
      'min_stock': updated.minStock,
      'unit': updated.unit,
      'default_variant': updated.defaultVariant,
      'image_url': updated.imageUrl,
    }).catchError((_) => null);
  }

  void deleteProduct(String id) {
    _products.removeWhere((p) => p.id == id);
    notifyListeners();
    // Sync to backend
    ApiService.instance.delete('/products/$id').catchError((_) => null);

    // Also remove from stock if it was auto-created
    try {
      StockRepository.instance.deleteStockItem('stock-$id');
    } catch (e) {
      debugPrint('Error auto-removing stock: $e');
    }
  }
}

/// Product catalog for the POS screen.
class ProductCatalog {
  static List<Product> get items => ProductRepository.instance.products;

  static const List<Product> defaultSeedItems = [
    Product(
      id: '1',
      code: 'CF-001',
      name: 'Iced Latte',
      price: 15000,
      category: ProductCategory.kopi,
      stock: 42,
      minStock: 15,
      unit: 'cup',
      imageUrl: 'https://images.unsplash.com/photo-1517701550927-30cf4ba1dba5?w=500&auto=format&fit=crop&q=80',
      defaultVariant: 'Less Sugar, Ice',
      placeholderIcon: Icons.coffee_rounded,
    ),
    Product(
      id: '2',
      code: 'CF-002',
      name: 'Americano',
      price: 18000,
      category: ProductCategory.kopi,
      stock: 35,
      minStock: 12,
      unit: 'cup',
      imageUrl: 'https://images.unsplash.com/photo-1514432324607-a09d9b4aefdd?w=500&auto=format&fit=crop&q=80',
      defaultVariant: 'Hot / No Sugar',
      placeholderIcon: Icons.coffee_rounded,
    ),
    Product(
      id: '3',
      code: 'CF-003',
      name: 'Cappuccino',
      price: 20000,
      category: ProductCategory.kopi,
      stock: 25,
      minStock: 10,
      unit: 'cup',
      imageUrl: 'https://images.unsplash.com/photo-1572442388796-11668a67e53d?w=500&auto=format&fit=crop&q=80',
      defaultVariant: 'Regular',
      placeholderIcon: Icons.coffee_rounded,
    ),
    Product(
      id: '4',
      code: 'NK-001',
      name: 'Chocolate Ice',
      price: 17000,
      category: ProductCategory.nonKopi,
      stock: 20,
      minStock: 10,
      unit: 'cup',
      imageUrl: 'https://images.unsplash.com/photo-1544787219-7f47ccb76574?w=500&auto=format&fit=crop&q=80',
      defaultVariant: 'Ice',
      placeholderIcon: Icons.local_cafe_rounded,
    ),
    Product(
      id: '5',
      code: 'NK-002',
      name: 'Matcha Latte',
      price: 20000,
      category: ProductCategory.nonKopi,
      stock: 18,
      minStock: 8,
      unit: 'cup',
      imageUrl: 'https://images.unsplash.com/photo-1536256263959-770b48d82b0a?w=500&auto=format&fit=crop&q=80',
      defaultVariant: 'Oatmilk',
      placeholderIcon: Icons.local_cafe_rounded,
    ),
    Product(
      id: '6',
      code: 'SN-001',
      name: 'Croissant Butter',
      price: 15000,
      category: ProductCategory.snack,
      stock: 14,
      minStock: 6,
      unit: 'pcs',
      imageUrl: 'https://images.unsplash.com/photo-1555507036-ab1f4038808a?w=500&auto=format&fit=crop&q=80',
      defaultVariant: 'Butter',
      placeholderIcon: Icons.bakery_dining_rounded,
    ),
    Product(
      id: '7',
      code: 'FD-001',
      name: 'Avocado Toast',
      price: 25000,
      category: ProductCategory.makanan,
      stock: 10,
      minStock: 5,
      unit: 'porsi',
      imageUrl: 'https://images.unsplash.com/photo-1525351484163-7529414344d8?w=500&auto=format&fit=crop&q=80',
      defaultVariant: 'Sourdough',
      placeholderIcon: Icons.restaurant_rounded,
    ),
    Product(
      id: '8',
      code: 'SN-002',
      name: 'Blueberry Muffin',
      price: 18000,
      category: ProductCategory.snack,
      stock: 12,
      minStock: 5,
      unit: 'pcs',
      imageUrl: 'https://images.unsplash.com/photo-1607958996333-41aef7caefaa?w=500&auto=format&fit=crop&q=80',
      defaultVariant: 'Warm',
      placeholderIcon: Icons.bakery_dining_rounded,
    ),
    Product(
      id: '9',
      code: 'FD-002',
      name: 'Beef Pie',
      price: 30000,
      category: ProductCategory.makanan,
      stock: 8,
      minStock: 4,
      unit: 'porsi',
      imageUrl: 'https://images.unsplash.com/photo-1621236378699-8597faf6a173?w=500&auto=format&fit=crop&q=80',
      defaultVariant: 'Original',
      placeholderIcon: Icons.restaurant_rounded,
    ),
    Product(
      id: '10',
      code: 'SN-003',
      name: 'Cheese Danish',
      price: 22000,
      category: ProductCategory.snack,
      stock: 9,
      minStock: 5,
      unit: 'pcs',
      imageUrl: 'https://images.unsplash.com/photo-1509440159596-0249088772ff?w=500&auto=format&fit=crop&q=80',
      defaultVariant: 'Cream Cheese',
      placeholderIcon: Icons.bakery_dining_rounded,
    ),
    Product(
      id: '11',
      code: 'FD-003',
      name: 'Club Sandwich',
      price: 35000,
      category: ProductCategory.makanan,
      stock: 6,
      minStock: 4,
      unit: 'porsi',
      imageUrl: 'https://images.unsplash.com/photo-1528735602780-2552fd46c7af?w=500&auto=format&fit=crop&q=80',
      defaultVariant: 'Wheat Bread',
      placeholderIcon: Icons.restaurant_rounded,
    ),
    Product(
      id: '12',
      code: 'FD-004',
      name: 'Tuna Melt',
      price: 28000,
      category: ProductCategory.makanan,
      stock: 7,
      minStock: 4,
      unit: 'porsi',
      imageUrl: 'https://images.unsplash.com/photo-1619860860774-1e2e17343432?w=500&auto=format&fit=crop&q=80',
      defaultVariant: 'Mozzarella',
      placeholderIcon: Icons.restaurant_rounded,
    ),
  ];
}
