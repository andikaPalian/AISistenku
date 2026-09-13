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

/// Represents a raw material component (ingredient) in a product recipe (BOM).
class ProductRecipeItem {
  final String? id;
  final String stockId;
  final String stockName;
  final double quantityRequired; // in base stock unit (e.g. 0.018 kg, 0.12 L, 1 pcs)
  final String unit; // display/preferred unit (e.g. 'g', 'ml', 'pcs', 'kg', 'L', 'btl')
  final double displayQuantity; // e.g. 18 for g, 120 for ml
  final int costPerUnit; // cost per stock base unit (from StockItem.costPerUnit)

  const ProductRecipeItem({
    this.id,
    required this.stockId,
    required this.stockName,
    required this.quantityRequired,
    required this.unit,
    this.displayQuantity = 0,
    this.costPerUnit = 0,
  });

  /// Display string, e.g. "18g Coffee Beans" or "120ml Fresh Milk"
  String get displayText {
    final qtyStr = displayQuantity > 0
        ? (displayQuantity == displayQuantity.roundToDouble()
            ? displayQuantity.toInt().toString()
            : displayQuantity.toStringAsFixed(1))
        : (quantityRequired == quantityRequired.roundToDouble()
            ? quantityRequired.toInt().toString()
            : quantityRequired.toStringAsFixed(3));
    return '$qtyStr$unit $stockName';
  }

  /// Calculate estimated cost of this ingredient (Rupiah).
  int get estimatedCost => (quantityRequired * costPerUnit).round();

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    'stockId': stockId,
    'quantityRequired': quantityRequired,
  };

  factory ProductRecipeItem.fromJson(Map<String, dynamic> json) {
    final stockObj = json['stock'] as Map<String, dynamic>?;
    final stockId = (json['stockId'] ?? json['stock_id'] ?? stockObj?['id'] ?? '').toString();
    final stockName = (stockObj?['name'] ?? json['stockName'] ?? json['stock_name'] ?? 'Bahan').toString();
    final baseUnit = (stockObj?['unit'] ?? json['unit'] ?? 'pcs').toString();
    final qty = double.tryParse((json['quantityRequired'] ?? json['quantity_required'] ?? json['qty'] ?? '0').toString()) ?? 0.0;
    final cost = int.tryParse((stockObj?['costPerUnit'] ?? stockObj?['cost_per_unit'] ?? json['costPerUnit'] ?? '0').toString()) ?? 0;

    String dispUnit = baseUnit;
    double dispQty = qty;
    if (baseUnit.toLowerCase() == 'kg' && qty < 1.0 && qty > 0) {
      dispUnit = 'g';
      dispQty = (qty * 1000).roundToDouble();
    } else if (baseUnit.toLowerCase() == 'l' && qty < 1.0 && qty > 0) {
      dispUnit = 'ml';
      dispQty = (qty * 1000).roundToDouble();
    }

    return ProductRecipeItem(
      id: json['id']?.toString(),
      stockId: stockId,
      stockName: stockName,
      quantityRequired: qty,
      unit: dispUnit,
      displayQuantity: dispQty,
      costPerUnit: cost,
    );
  }

  ProductRecipeItem copyWith({
    String? id,
    String? stockId,
    String? stockName,
    double? quantityRequired,
    String? unit,
    double? displayQuantity,
    int? costPerUnit,
  }) {
    return ProductRecipeItem(
      id: id ?? this.id,
      stockId: stockId ?? this.stockId,
      stockName: stockName ?? this.stockName,
      quantityRequired: quantityRequired ?? this.quantityRequired,
      unit: unit ?? this.unit,
      displayQuantity: displayQuantity ?? this.displayQuantity,
      costPerUnit: costPerUnit ?? this.costPerUnit,
    );
  }
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
  final List<ProductRecipeItem> recipes;

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
    this.recipes = const [],
  });

  /// Returns the dynamically calculated stock quantity from StockRepository.
  ///
  /// 1. If product has recipes:
  ///    Calculates maximum available portions based on available ingredient stocks in StockRepository:
  ///    portions = min(stockItem.currentStock / recipe.quantityRequired).
  ///
  /// 2. If product is a direct inventory item (1:1 with StockItem):
  ///    Matches by ID ('stock-${product.id}', product.id) or case-insensitive product.name.
  ///    Returns stockItem.currentStock.toInt().
  ///
  /// 3. Otherwise:
  ///    Falls back to this.stock.
  int get dynamicStock {
    if (recipes.isNotEmpty) {
      int minPortions = 999999;
      bool foundAny = false;
      for (final r in recipes) {
        final stockItem = StockRepository.instance.getItemById(r.stockId) ??
            StockRepository.instance.items.cast<StockItem?>().firstWhere(
              (s) => s != null && s.name.trim().toLowerCase() == r.stockName.trim().toLowerCase(),
              orElse: () => null,
            );
        if (stockItem != null && r.quantityRequired > 0) {
          foundAny = true;
          final portions = (stockItem.currentStock / r.quantityRequired).floor();
          if (portions < minPortions) {
            minPortions = portions;
          }
        }
      }
      if (foundAny && minPortions != 999999) {
        return minPortions.clamp(0, 999999);
      }
    }

    // Direct 1:1 match with StockItem by ID or Name
    final directStock = StockRepository.instance.items.cast<StockItem?>().firstWhere(
      (s) =>
          s != null &&
          (s.id == id ||
           s.id == 'stock-$id' ||
           s.name.trim().toLowerCase() == name.trim().toLowerCase()),
      orElse: () => null,
    );
    if (directStock != null) {
      return directStock.currentStock.toInt();
    }

    return stock;
  }

  bool get isLowStock => dynamicStock <= minStock;

  /// Whether this product has linked raw material recipes.
  bool get hasRecipe => recipes.isNotEmpty;

  /// Total estimated raw material cost (HPP / COGS) per portion.
  int get estimatedCostOfGoods {
    return recipes.fold(0, (sum, r) => sum + r.estimatedCost);
  }

  /// Estimated gross profit per portion.
  int get estimatedGrossProfit => price - estimatedCostOfGoods;

  /// Estimated gross profit margin percentage (0 to 100).
  int get estimatedMarginPercentage {
    if (price <= 0) return 0;
    return ((price - estimatedCostOfGoods) / price * 100).round();
  }

  /// Human-readable recipe formula string (e.g. "18g Coffee Beans + 120ml Fresh Milk").
  String get recipeSummary {
    if (recipes.isEmpty) return 'Tanpa resep (stok langsung)';
    return recipes.map((r) => r.displayText).join(' + ');
  }

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
    List<ProductRecipeItem>? recipes,
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
      recipes: recipes ?? this.recipes,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    if (code != null) 'code': code,
    'name': name,
    'price': price,
    'category': category.name,
    'defaultVariant': defaultVariant,
    if (imageUrl != null) 'imageUrl': imageUrl,
    'stock': stock,
    'minStock': minStock,
    'unit': unit,
    'recipes': recipes.map((r) => r.toJson()).toList(),
  };

  factory Product.fromJson(Map<String, dynamic> json) {
    ProductCategory cat = ProductCategory.kopi;
    final catStr = (json['category'] ?? '').toString().toLowerCase();
    for (final c in ProductCategory.values) {
      if (c.name.toLowerCase() == catStr || c.label.toLowerCase() == catStr) {
        cat = c;
        break;
      }
    }
    List<ProductRecipeItem> rec = [];
    if (json['recipes'] is List) {
      rec = (json['recipes'] as List)
          .map((r) => ProductRecipeItem.fromJson(Map<String, dynamic>.from(r as Map)))
          .toList();
    }
    return Product(
      id: json['id']?.toString() ?? '',
      code: json['code']?.toString(),
      name: json['name']?.toString() ?? '',
      price: (json['price'] as num?)?.toInt() ?? 0,
      category: cat,
      defaultVariant: json['defaultVariant']?.toString() ?? 'Regular',
      imageUrl: json['imageUrl']?.toString(),
      stock: (json['stock'] as num?)?.toInt() ?? 20,
      minStock: (json['minStock'] as num?)?.toInt() ?? 5,
      unit: json['unit']?.toString() ?? 'cup',
      recipes: rec,
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

  Map<String, dynamic> toJson() => {
    'product': product.toJson(),
    'quantity': quantity,
    'variant': variant,
    if (note != null) 'note': note,
  };

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      product: Product.fromJson(Map<String, dynamic>.from(json['product'] as Map)),
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      variant: json['variant']?.toString() ?? 'Regular',
      note: json['note']?.toString(),
    );
  }
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

  Map<String, dynamic> toJson() => {
    'orderId': orderId,
    'orderCode': orderCode,
    'orderType': orderType.name,
    if (tableNumber != null) 'tableNumber': tableNumber,
    if (customerName != null) 'customerName': customerName,
    'items': items.map((i) => i.toJson()).toList(),
    'subtotal': subtotal,
    'tax': tax,
    'total': total,
    'paymentMethod': paymentMethod.name,
    'cashGiven': cashGiven,
    'change': change,
    'status': status,
    'createdAt': createdAt.toIso8601String(),
  };

  factory OrderRecord.fromJson(Map<String, dynamic> json) {
    OrderType oType = OrderType.dineIn;
    final oTypeStr = (json['orderType'] ?? '').toString().toLowerCase();
    if (oTypeStr.contains('take')) {
      oType = OrderType.takeAway;
    }

    PaymentMethodType pMethod = PaymentMethodType.cash;
    final pMethodStr = (json['paymentMethod'] ?? '').toString().toLowerCase();
    if (pMethodStr.contains('qris')) {
      pMethod = PaymentMethodType.qris;
    } else if (pMethodStr.contains('card') || pMethodStr.contains('debit')) {
      pMethod = PaymentMethodType.card;
    }

    List<CartItem> cartItems = [];
    if (json['items'] is List) {
      cartItems = (json['items'] as List)
          .map((i) => CartItem.fromJson(Map<String, dynamic>.from(i as Map)))
          .toList();
    }

    return OrderRecord(
      orderId: json['orderId']?.toString() ?? '',
      orderCode: json['orderCode']?.toString() ?? '#3A-88895',
      orderType: oType,
      tableNumber: json['tableNumber']?.toString(),
      customerName: json['customerName']?.toString(),
      items: cartItems,
      subtotal: (json['subtotal'] as num?)?.toInt() ?? 0,
      tax: (json['tax'] as num?)?.toInt() ?? 0,
      total: (json['total'] as num?)?.toInt() ?? 0,
      paymentMethod: pMethod,
      cashGiven: (json['cashGiven'] as num?)?.toInt() ?? 0,
      change: (json['change'] as num?)?.toInt() ?? 0,
      status: json['status']?.toString() ?? 'PAID',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

/// Repository & state manager for products in the POS catalog.
class ProductRepository extends ChangeNotifier {
  static final ProductRepository instance = ProductRepository._internal();
  ProductRepository._internal() {
    _products = List.from(ProductCatalog.defaultSeedItems);
    StockRepository.instance.addListener(_handleStockRepositoryChanged);
  }

  void _handleStockRepositoryChanged() {
    syncAllStocksFromInventory();
  }

  /// Automatically syncs all POS products with the latest inventory levels.
  void syncAllStocksFromInventory() {
    bool changed = false;
    for (int i = 0; i < _products.length; i++) {
      final p = _products[i];
      final dyn = p.dynamicStock;
      if (p.stock != dyn) {
        _products[i] = p.copyWith(stock: dyn);
        changed = true;
      }
    }
    if (changed) {
      notifyListeners();
    }
  }

  /// Synchronizes a specific stock item mutation (restock/adjust) to POS products.
  void syncWithStockItem(String stockId, double newStockQty, {String? stockName}) {
    bool changed = false;
    for (int i = 0; i < _products.length; i++) {
      final p = _products[i];
      final isDirectMatch = p.id == stockId ||
          p.id == stockId.replaceFirst('stock-', '') ||
          'stock-${p.id}' == stockId ||
          (stockName != null && p.name.trim().toLowerCase() == stockName.trim().toLowerCase());

      if (isDirectMatch) {
        _products[i] = p.copyWith(stock: newStockQty.toInt());
        changed = true;
      } else if (p.recipes.any((r) =>
          r.stockId == stockId ||
          (stockName != null && r.stockName.trim().toLowerCase() == stockName.trim().toLowerCase()))) {
        final newPortions = p.dynamicStock;
        _products[i] = p.copyWith(stock: newPortions);
        changed = true;
      }
    }
    if (changed) {
      notifyListeners();
    }
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
      List? list;
      if (res != null) {
        if (res['data'] is List) {
          list = res['data'];
        } else if (res['products'] is List) {
          list = res['products'];
        }
      }
      if (list != null) {
        final List<Product> loaded = [];
        for (final item in list) {
          ProductCategory cat = ProductCategory.kopi;
          final catStr = (item['category'] ?? '').toString().toLowerCase();
          if (catStr.contains('non')) {
            cat = ProductCategory.nonKopi;
          } else if (catStr.contains('snack')) {
            cat = ProductCategory.snack;
          } else if (catStr.contains('makan') || catStr.contains('food')) {
            cat = ProductCategory.makanan;
          } else if (catStr.contains('coffee') || catStr.contains('kopi')) {
            cat = ProductCategory.kopi;
          }

          final priceVal = int.tryParse((item['price'] ?? '0').toString()) ??
              (item['price'] as num?)?.toInt() ??
              0;

          final stockVal = int.tryParse((item['stock'] ?? item['current_stock'] ?? '20').toString()) ??
              (item['stock'] as num?)?.toInt() ??
              (item['current_stock'] as num?)?.toInt() ??
              20;

          final minStockVal = int.tryParse((item['minStock'] ?? item['min_stock'] ?? '5').toString()) ??
              (item['minStock'] as num?)?.toInt() ??
              (item['min_stock'] as num?)?.toInt() ??
              5;

          final img = (item['imageUrl'] ?? item['image_url'])?.toString();
          final variant = (item['defaultVariant'] ?? item['default_variant'] ?? 'Regular').toString();

          List<ProductRecipeItem> recipes = [];
          if (item['recipes'] is List) {
            recipes = (item['recipes'] as List)
                .map((r) => ProductRecipeItem.fromJson(r as Map<String, dynamic>))
                .toList();
          }

          loaded.add(Product(
            id: (item['id'] ?? item['product_id'] ?? 'prod-${DateTime.now().millisecondsSinceEpoch}').toString(),
            code: item['code']?.toString(),
            name: (item['name'] ?? 'Menu').toString(),
            price: priceVal,
            category: cat,
            stock: stockVal,
            minStock: minStockVal,
            unit: (item['unit'] ?? 'cup').toString(),
            imageUrl: img,
            defaultVariant: variant,
            placeholderIcon: Icons.coffee_rounded,
            recipes: recipes,
          ));
        }
        if (loaded.isNotEmpty) {
          _products = loaded;
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('⚠️ fetchProductsFromBackend error: $e');
    }
  }

  void addProduct(Product product) {
    _products.insert(0, product);
    notifyListeners();

    String backendCategory = 'COFFEE';
    if (product.category == ProductCategory.nonKopi) {
      backendCategory = 'NON_COFFEE';
    } else if (product.category == ProductCategory.makanan) {
      backendCategory = 'FOOD';
    } else if (product.category == ProductCategory.snack) {
      backendCategory = 'SNACK';
    }

    // Link product in stock items
    if (product.recipes.isNotEmpty) {
      for (final r in product.recipes) {
        StockRepository.instance.linkProductToStock(r.stockId, product.name);
      }
    }

    // Sync to backend
    ApiService.instance.post('/products', {
      'name': product.name,
      'price': product.price,
      'category': backendCategory,
      'defaultVariant': product.defaultVariant,
      if (product.imageUrl != null && product.imageUrl!.isNotEmpty) 'imageUrl': product.imageUrl,
    }).then((res) {
      final newId = res?['data']?['id'] ?? res?['product']?['id'];
      if (newId != null) {
        final idx = _products.indexWhere((p) => p.id == product.id);
        if (idx != -1) {
          _products[idx] = _products[idx].copyWith(id: newId.toString());
          notifyListeners();
        }
        if (product.recipes.isNotEmpty) {
          ApiService.instance.put('/products/$newId/recipe', {
            'items': product.recipes.map((r) => r.toJson()).toList(),
          }).catchError((_) => null);
        }
      }
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

    String backendCategory = 'COFFEE';
    if (updated.category == ProductCategory.nonKopi) {
      backendCategory = 'NON_COFFEE';
    } else if (updated.category == ProductCategory.makanan) {
      backendCategory = 'FOOD';
    } else if (updated.category == ProductCategory.snack) {
      backendCategory = 'SNACK';
    }

    // Link product in stock items and sync recipe to backend
    if (updated.recipes.isNotEmpty) {
      for (final r in updated.recipes) {
        StockRepository.instance.linkProductToStock(r.stockId, updated.name);
      }
      ApiService.instance.put('/products/${updated.id}/recipe', {
        'items': updated.recipes.map((r) => r.toJson()).toList(),
      }).catchError((_) => null);
    } else {
      // User cleared all recipes, sync empty list to remove backend recipes
      ApiService.instance.put('/products/${updated.id}/recipe', {
        'items': [],
      }).catchError((_) => null);
    }

    syncAllStocksFromInventory();

    // Sync to backend
    ApiService.instance.patch('/products/${updated.id}', {
      'name': updated.name,
      'price': updated.price,
      'category': backendCategory,
      'defaultVariant': updated.defaultVariant,
      if (updated.imageUrl != null && updated.imageUrl!.isNotEmpty) 'imageUrl': updated.imageUrl,
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

  /// Deduct stock of a product when an order is completed.
  void deductStock(String productId, int quantity) {
    final idx = _products.indexWhere(
      (p) => p.id == productId || p.name.toLowerCase() == productId.toLowerCase(),
    );
    if (idx != -1) {
      final current = _products[idx];
      final newStock = (current.stock - quantity).clamp(0, 999999);
      _products[idx] = current.copyWith(stock: newStock);
      notifyListeners();

      // Deduct ingredients from inventory stock according to product recipes
      if (current.recipes.isNotEmpty) {
        for (final recipe in current.recipes) {
          final totalDeduct = recipe.quantityRequired * quantity;
          StockRepository.instance.deductRecipeStock(
            stockId: recipe.stockId,
            quantity: totalDeduct,
            productName: current.name,
          );
        }
      } else {
        // Direct product deduction in inventory
        final matchedStock = StockRepository.instance.items.cast<StockItem?>().firstWhere(
          (s) =>
              s != null &&
              (s.id == current.id ||
               s.id == 'stock-${current.id}' ||
               s.name.trim().toLowerCase() == current.name.trim().toLowerCase()),
          orElse: () => null,
        );
        if (matchedStock != null) {
          StockRepository.instance.deductRecipeStock(
            stockId: matchedStock.id,
            quantity: quantity.toDouble(),
            productName: current.name,
          );
        }
      }
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
      recipes: [
        ProductRecipeItem(
          stockId: 'coffee_beans',
          stockName: 'Coffee Beans',
          quantityRequired: 0.018,
          unit: 'g',
          displayQuantity: 18,
          costPerUnit: 95000,
        ),
        ProductRecipeItem(
          stockId: 'fresh_milk',
          stockName: 'Fresh Milk',
          quantityRequired: 0.12,
          unit: 'ml',
          displayQuantity: 120,
          costPerUnit: 24000,
        ),
        ProductRecipeItem(
          stockId: 'sugar',
          stockName: 'Sugar',
          quantityRequired: 0.015,
          unit: 'g',
          displayQuantity: 15,
          costPerUnit: 16000,
        ),
        ProductRecipeItem(
          stockId: 'cup_16oz',
          stockName: 'Cup Plastic 16oz + Lid',
          quantityRequired: 1.0,
          unit: 'pcs',
          displayQuantity: 1,
          costPerUnit: 850,
        ),
      ],
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
      recipes: [
        ProductRecipeItem(
          stockId: 'coffee_beans',
          stockName: 'Coffee Beans',
          quantityRequired: 0.018,
          unit: 'g',
          displayQuantity: 18,
          costPerUnit: 95000,
        ),
        ProductRecipeItem(
          stockId: 'cup_16oz',
          stockName: 'Cup Plastic 16oz + Lid',
          quantityRequired: 1.0,
          unit: 'pcs',
          displayQuantity: 1,
          costPerUnit: 850,
        ),
      ],
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
      recipes: [
        ProductRecipeItem(
          stockId: 'coffee_beans',
          stockName: 'Coffee Beans',
          quantityRequired: 0.018,
          unit: 'g',
          displayQuantity: 18,
          costPerUnit: 95000,
        ),
        ProductRecipeItem(
          stockId: 'fresh_milk',
          stockName: 'Fresh Milk',
          quantityRequired: 0.15,
          unit: 'ml',
          displayQuantity: 150,
          costPerUnit: 24000,
        ),
        ProductRecipeItem(
          stockId: 'cup_16oz',
          stockName: 'Cup Plastic 16oz + Lid',
          quantityRequired: 1.0,
          unit: 'pcs',
          displayQuantity: 1,
          costPerUnit: 850,
        ),
      ],
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
      recipes: [
        ProductRecipeItem(
          stockId: 'chocolate_syrup',
          stockName: 'Chocolate Syrup',
          quantityRequired: 0.04,
          unit: 'btl',
          displayQuantity: 0.04,
          costPerUnit: 65000,
        ),
        ProductRecipeItem(
          stockId: 'fresh_milk',
          stockName: 'Fresh Milk',
          quantityRequired: 0.15,
          unit: 'ml',
          displayQuantity: 150,
          costPerUnit: 24000,
        ),
        ProductRecipeItem(
          stockId: 'cup_16oz',
          stockName: 'Cup Plastic 16oz + Lid',
          quantityRequired: 1.0,
          unit: 'pcs',
          displayQuantity: 1,
          costPerUnit: 850,
        ),
      ],
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
      recipes: [
        ProductRecipeItem(
          stockId: 'matcha_powder',
          stockName: 'Matcha Powder Uji',
          quantityRequired: 0.02,
          unit: 'g',
          displayQuantity: 20,
          costPerUnit: 140000,
        ),
        ProductRecipeItem(
          stockId: 'fresh_milk',
          stockName: 'Fresh Milk',
          quantityRequired: 0.15,
          unit: 'ml',
          displayQuantity: 150,
          costPerUnit: 24000,
        ),
        ProductRecipeItem(
          stockId: 'cup_16oz',
          stockName: 'Cup Plastic 16oz + Lid',
          quantityRequired: 1.0,
          unit: 'pcs',
          displayQuantity: 1,
          costPerUnit: 850,
        ),
      ],
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
