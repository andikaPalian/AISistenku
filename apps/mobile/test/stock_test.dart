import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiga_angkatan/models/stock_model.dart';
import 'package:tiga_angkatan/screens/stock/stock_screen.dart';
import 'package:tiga_angkatan/screens/stock/stock_detail_screen.dart';

void main() {
  group('Stock Model & Repository Tests', () {
    test('StockItem status calculation', () {
      final itemSafe = StockItem(
        id: '1',
        name: 'Test Safe',
        category: StockCategory.kopi,
        currentStock: 10.0,
        minStock: 5.0,
        unit: 'kg',
        costPerUnit: 50000,
        lastUpdated: DateTime.now(),
      );
      expect(itemSafe.status, StockStatus.baik);

      final itemLow = itemSafe.copyWith(currentStock: 4.5);
      expect(itemLow.status, StockStatus.rendah);

      final itemCritical = itemSafe.copyWith(currentStock: 2.0);
      expect(itemCritical.status, StockStatus.kritis);
    });

    test('StockRepository restock flow updates quantity and logs', () {
      final repo = StockRepository.instance;
      final initialSugar = repo.getItemById('sugar')!;
      final initialQty = initialSugar.currentStock;

      repo.restockItem(
        stockId: 'sugar',
        quantity: 5.0,
        costPerUnit: 16000,
        supplier: 'Test Supplier',
      );

      final updatedSugar = repo.getItemById('sugar')!;
      expect(updatedSugar.currentStock, initialQty + 5.0);

      final logs = repo.getLogsForStock('sugar');
      expect(logs.first.type, StockLogType.inStock);
      expect(logs.first.quantity, 5.0);
    });
  });

  group('Stock UI Widget Tests', () {
    testWidgets('StockScreen renders KPI summary cards and stock list', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: StockScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Stok Bahan'), findsOneWidget);
      expect(find.text('Total Bahan'), findsOneWidget);
      expect(find.text('Rendah'), findsAtLeastNWidgets(1));
      expect(find.text('Kritis'), findsAtLeastNWidgets(1));
      expect(find.text('Sugar'), findsOneWidget);
      expect(find.text('Fresh Milk'), findsOneWidget);
    });

    testWidgets('StockDetailScreen renders hero card and stock history for Sugar', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: StockDetailScreen(stockId: 'sugar'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Sugar'), findsOneWidget);
      expect(find.text('STOK SAAT INI'), findsOneWidget);
      expect(find.text('Riwayat Stok'), findsOneWidget);
      expect(find.text('Stok Minimum'), findsOneWidget);
    });
  });
}
