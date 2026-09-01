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

/// Represents a menu item in the POS system.
class Product {
  final String id;
  final String name;
  final int price;
  final ProductCategory category;
  final IconData? placeholderIcon;

  const Product({
    required this.id,
    required this.name,
    required this.price,
    required this.category,
    this.placeholderIcon,
  });

  /// Format price as Indonesian Rupiah (e.g. "Rp15.000").
  String get formattedPrice {
    final str = price.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) buffer.write('.');
      buffer.write(str[i]);
    }
    return 'Rp$buffer';
  }
}

/// Represents an item added to the cart with quantity.
class CartItem {
  final Product product;
  int quantity;

  CartItem({required this.product, this.quantity = 1});

  int get subtotal => product.price * quantity;
}

/// Dummy product catalog for the POS screen.
class ProductCatalog {
  static const List<Product> items = [
    Product(
      id: '1',
      name: 'Iced Latte',
      price: 15000,
      category: ProductCategory.kopi,
      placeholderIcon: Icons.coffee_rounded,
    ),
    Product(
      id: '2',
      name: 'Americano',
      price: 18000,
      category: ProductCategory.kopi,
      placeholderIcon: Icons.coffee_rounded,
    ),
    Product(
      id: '3',
      name: 'Cappuccino',
      price: 20000,
      category: ProductCategory.kopi,
      placeholderIcon: Icons.coffee_rounded,
    ),
    Product(
      id: '4',
      name: 'Chocolate',
      price: 17000,
      category: ProductCategory.nonKopi,
      placeholderIcon: Icons.local_cafe_rounded,
    ),
    Product(
      id: '5',
      name: 'Matcha Latte',
      price: 20000,
      category: ProductCategory.nonKopi,
      placeholderIcon: Icons.local_cafe_rounded,
    ),
    Product(
      id: '6',
      name: 'Croissant',
      price: 15000,
      category: ProductCategory.snack,
      placeholderIcon: Icons.bakery_dining_rounded,
    ),
    Product(
      id: '7',
      name: 'Avocado Toast',
      price: 25000,
      category: ProductCategory.makanan,
      placeholderIcon: Icons.restaurant_rounded,
    ),
    Product(
      id: '8',
      name: 'Blueberry Muffin',
      price: 18000,
      category: ProductCategory.snack,
      placeholderIcon: Icons.bakery_dining_rounded,
    ),
    Product(
      id: '9',
      name: 'Beef Pie',
      price: 30000,
      category: ProductCategory.makanan,
      placeholderIcon: Icons.restaurant_rounded,
    ),
    Product(
      id: '10',
      name: 'Cheese Danish',
      price: 22000,
      category: ProductCategory.snack,
      placeholderIcon: Icons.bakery_dining_rounded,
    ),
    Product(
      id: '11',
      name: 'Club Sandwich',
      price: 35000,
      category: ProductCategory.makanan,
      placeholderIcon: Icons.restaurant_rounded,
    ),
    Product(
      id: '12',
      name: 'Tuna Melt',
      price: 28000,
      category: ProductCategory.makanan,
      placeholderIcon: Icons.restaurant_rounded,
    ),
  ];
}
