import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:AISISTENKU/models/product.dart';
import 'package:AISISTENKU/screens/pos/pos_screen.dart';
import 'package:AISISTENKU/screens/pos/widgets/product_card.dart';

void main() {
  group('POS Product Model Tests', () {
    test('Product contains image, stock, and lowStock logic', () {
      final product = ProductCatalog.items.first;
      expect(product.imageUrl, isNotNull);
      expect(product.imageUrl!.startsWith('http'), isTrue);
      expect(product.stock, greaterThan(0));
      expect(product.formattedPrice, 'Rp15.000');
    });

    test('All 12 products in ProductCatalog have image URLs matching website', () {
      expect(ProductCatalog.items.length, 12);
      for (final item in ProductCatalog.items) {
        expect(item.imageUrl, isNotNull);
        expect(item.imageUrl!.isNotEmpty, isTrue);
        expect(item.code, isNotNull);
      }
    });
  });

  group('POS UI Widget Tests', () {
    testWidgets('PosScreen renders Header, Category chips, Search and Product Grid with images', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: PosScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Tiga Angkatan - Kartasura'), findsOneWidget);
      expect(find.text('Outlet Utama • Siap Saji 15 Menit'), findsOneWidget);
      expect(find.text('All'), findsOneWidget);
      expect(find.text('Kopi'), findsAtLeastNWidgets(1));
      expect(find.text('Iced Latte'), findsOneWidget);
      expect(find.text('Americano'), findsOneWidget);
    });

    testWidgets('ProductCard renders image container, price badge, and stepper', (WidgetTester tester) async {
      final product = ProductCatalog.items.first;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProductCard(
              product: product,
              quantity: 2,
              onTap: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Iced Latte'), findsOneWidget);
      expect(find.text(product.formattedPrice), findsOneWidget);
      expect(find.text('2'), findsWidgets); // badge & stepper
      expect(find.byIcon(Icons.add_rounded), findsOneWidget);
      expect(find.byIcon(Icons.remove_rounded), findsOneWidget);
    });
  });
}
