import 'package:flutter/material.dart';

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
  final String name;
  final int price;
  final ProductCategory category;
  final String defaultVariant;
  final IconData? placeholderIcon;

  const Product({
    required this.id,
    required this.name,
    required this.price,
    required this.category,
    this.defaultVariant = 'Regular',
    this.placeholderIcon,
  });

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
    String? variant,
    this.note,
  }) : variant = variant ?? product.defaultVariant;

  int get subtotal => product.price * quantity;
  String get formattedSubtotal => Product.formatRupiah(subtotal);

  CartItem copyWith({
    Product? product,
    int? quantity,
    String? variant,
    String? note,
  }) {
    return CartItem(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      variant: variant ?? this.variant,
      note: note ?? this.note,
    );
  }
}

/// Order completed record.
class OrderRecord {
  final String orderId;
  final List<CartItem> items;
  final OrderType orderType;
  final String? tableNumber;
  final String? customerName;
  final PaymentMethodType paymentMethod;
  final int subtotal;
  final int tax;
  final int total;
  final int cashGiven;
  final int change;
  final DateTime createdAt;

  const OrderRecord({
    required this.orderId,
    required this.items,
    required this.orderType,
    this.tableNumber,
    this.customerName,
    required this.paymentMethod,
    required this.subtotal,
    required this.tax,
    required this.total,
    this.cashGiven = 0,
    this.change = 0,
    required this.createdAt,
  });
}

/// Dummy product catalog for the POS screen.
class ProductCatalog {
  static const List<Product> items = [
    Product(
      id: '1',
      name: 'Iced Latte',
      price: 15000,
      category: ProductCategory.kopi,
      defaultVariant: 'Less Sugar, Ice',
      placeholderIcon: Icons.coffee_rounded,
    ),
    Product(
      id: '2',
      name: 'Americano',
      price: 18000,
      category: ProductCategory.kopi,
      defaultVariant: 'Hot / No Sugar',
      placeholderIcon: Icons.coffee_rounded,
    ),
    Product(
      id: '3',
      name: 'Cappuccino',
      price: 20000,
      category: ProductCategory.kopi,
      defaultVariant: 'Regular',
      placeholderIcon: Icons.coffee_rounded,
    ),
    Product(
      id: '4',
      name: 'Chocolate',
      price: 17000,
      category: ProductCategory.nonKopi,
      defaultVariant: 'Ice',
      placeholderIcon: Icons.local_cafe_rounded,
    ),
    Product(
      id: '5',
      name: 'Matcha Latte',
      price: 20000,
      category: ProductCategory.nonKopi,
      defaultVariant: 'Oatmilk',
      placeholderIcon: Icons.local_cafe_rounded,
    ),
    Product(
      id: '6',
      name: 'Croissant',
      price: 15000,
      category: ProductCategory.snack,
      defaultVariant: 'Butter',
      placeholderIcon: Icons.bakery_dining_rounded,
    ),
    Product(
      id: '7',
      name: 'Avocado Toast',
      price: 25000,
      category: ProductCategory.makanan,
      defaultVariant: 'Sourdough',
      placeholderIcon: Icons.restaurant_rounded,
    ),
    Product(
      id: '8',
      name: 'Blueberry Muffin',
      price: 18000,
      category: ProductCategory.snack,
      defaultVariant: 'Warm',
      placeholderIcon: Icons.bakery_dining_rounded,
    ),
    Product(
      id: '9',
      name: 'Beef Pie',
      price: 30000,
      category: ProductCategory.makanan,
      defaultVariant: 'Original',
      placeholderIcon: Icons.restaurant_rounded,
    ),
    Product(
      id: '10',
      name: 'Cheese Danish',
      price: 22000,
      category: ProductCategory.snack,
      defaultVariant: 'Cream Cheese',
      placeholderIcon: Icons.bakery_dining_rounded,
    ),
    Product(
      id: '11',
      name: 'Club Sandwich',
      price: 35000,
      category: ProductCategory.makanan,
      defaultVariant: 'Wheat Bread',
      placeholderIcon: Icons.restaurant_rounded,
    ),
    Product(
      id: '12',
      name: 'Tuna Melt',
      price: 28000,
      category: ProductCategory.makanan,
      defaultVariant: 'Mozzarella',
      placeholderIcon: Icons.restaurant_rounded,
    ),
  ];
}
