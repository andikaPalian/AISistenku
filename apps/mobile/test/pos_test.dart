import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:AISISTENKU/models/product.dart';
import 'package:AISISTENKU/models/stock_model.dart';
import 'package:AISISTENKU/screens/pos/pos_screen.dart';
import 'package:AISISTENKU/screens/pos/widgets/add_edit_product_modal.dart';
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

    test('Product Recipe and BOM calculations work accurately', () {
      final icedLatte = ProductCatalog.items.first;
      expect(icedLatte.hasRecipe, isTrue);
      expect(icedLatte.recipes.length, greaterThanOrEqualTo(3));
      expect(icedLatte.estimatedCostOfGoods, greaterThan(0));
      expect(icedLatte.estimatedGrossProfit, greaterThan(0));
      expect(icedLatte.estimatedMarginPercentage, greaterThan(0));
      expect(icedLatte.recipeSummary, contains('Coffee Beans'));
    });
  });

  group('POS Recipe UI & Modal Tests', () {
    testWidgets('AddEditProductModal renders Komposisi Bahan Baku section and presets', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: AddEditProductModal(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Komposisi Bahan Baku (Resep)'), findsOneWidget);
      expect(find.text('Resep & Bill of Materials (BOM)'), findsOneWidget);
      expect(find.text('Template:'), findsOneWidget);
      expect(find.text('☕ Kopi Susu (18g Kopi + 120ml Susu)'), findsOneWidget);
      expect(find.text('Tambah Bahan Baku Resep'), findsOneWidget);
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

    testWidgets('PosHeader tap Riwayat Hari Ini opens modern bottom sheet with filter pills and omset', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PosScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Riwayat Hari Ini'), findsOneWidget);
      await tester.tap(find.text('Riwayat Hari Ini'));
      await tester.pumpAndSettle();

      // Verify Header & Metrics
      expect(find.text('Riwayat Pesanan Kasir'), findsOneWidget);
      expect(find.text('Omset Kasir Terkini'), findsOneWidget);

      // Verify Filter Pills
      expect(find.text('Semua Pesanan'), findsOneWidget);
      expect(find.text('Selesai'), findsAtLeastNWidgets(1));
      expect(find.text('Refund / Batal'), findsOneWidget);
      expect(find.text('Semua Transaksi'), findsOneWidget);

      // Tap Refund tab
      await tester.tap(find.text('Refund / Batal'));
      await tester.pumpAndSettle();
    });
  });

  group('POS & Inventory Dynamic Stock Sync Tests', () {
    test('Restocking raw item / direct item (Pepaya) in StockRepository immediately updates dynamicStock in ProductRepository and triggers listeners', () {
      // 1. Add Pepaya to StockRepository with 10 units
      final pepayaStock = StockItem(
        id: 'pepaya',
        name: 'Pepaya',
        currentStock: 10.0,
        unit: 'buah',
        minStock: 3.0,
        costPerUnit: 8000,
        category: StockCategory.bahanBaku,
        lastUpdated: DateTime.now(),
      );
      StockRepository.instance.addStockItem(pepayaStock);

      // 2. Add Pepaya product to ProductRepository (direct product without recipes)
      final pepayaProduct = Product(
        id: 'prod-pepaya',
        name: 'Pepaya',
        price: 15000,
        category: ProductCategory.makanan,
        stock: 0,
        minStock: 2,
        unit: 'buah',
      );
      ProductRepository.instance.addProduct(pepayaProduct);

      // 3. Verify dynamicStock reflects StockRepository current stock (10)
      final foundProduct = ProductRepository.instance.products.firstWhere((p) => p.name == 'Pepaya');
      expect(foundProduct.dynamicStock, 10);

      // 4. Restock Pepaya by adding 15 units -> total 25
      StockRepository.instance.restockItem(
        stockId: 'pepaya',
        quantity: 15.0,
      );

      // 5. Verify dynamicStock immediately reflects 25 in POS ProductRepository
      final updatedProduct = ProductRepository.instance.products.firstWhere((p) => p.name == 'Pepaya');
      expect(updatedProduct.dynamicStock, 25);
      expect(updatedProduct.stock, 25);

      // 6. Deducting stock via POS checkout decrements both Product and StockItem
      ProductRepository.instance.deductStock('prod-pepaya', 5);
      final stockAfterDeduct = StockRepository.instance.getItemById('pepaya');
      expect(stockAfterDeduct?.currentStock, 20.0);
      final productAfterDeduct = ProductRepository.instance.products.firstWhere((p) => p.name == 'Pepaya');
      expect(productAfterDeduct.dynamicStock, 20);
    });

    testWidgets('ProductCard renders dynamicStock matching restocked inventory item', (WidgetTester tester) async {
      final item = StockRepository.instance.getItemById('pepaya-segar');
      if (item == null) {
        StockRepository.instance.addStockItem(StockItem(
          id: 'pepaya-segar',
          name: 'Pepaya Segar',
          currentStock: 35.0,
          unit: 'buah',
          minStock: 5.0,
          costPerUnit: 7000,
          category: StockCategory.bahanBaku,
          lastUpdated: DateTime.now(),
        ));
      } else {
        StockRepository.instance.adjustStock(
          stockId: 'pepaya-segar',
          actualQuantity: 35.0,
          reason: 'Sync test',
        );
      }

      final pepayaProduct = Product(
        id: 'prod-pepaya-segar',
        name: 'Pepaya Segar',
        price: 12000,
        category: ProductCategory.makanan,
        stock: 0, // static stock is 0, but dynamicStock will be 35
        minStock: 5,
        unit: 'buah',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProductCard(
              product: pepayaProduct,
              quantity: 0,
              onTap: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Pepaya Segar'), findsOneWidget);
      expect(find.text('Stok: 35'), findsOneWidget);
    });
  });
}

