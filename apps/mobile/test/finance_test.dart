import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:AISISTENKU/models/finance_model.dart';
import 'package:AISISTENKU/screens/finance/finance_screen.dart';
import 'package:AISISTENKU/screens/finance/add_transaction_screen.dart';

void main() {
  group('Finance Model & Repository Tests', () {
    test('Format Rupiah correctly formats currency amounts', () {
      expect(FinanceRepository.formatRupiah(5250000), 'Rp5.250.000');
      expect(FinanceRepository.formatRupiah(45000), 'Rp45.000');
      expect(FinanceRepository.formatRupiah(0), 'Rp0');
      expect(FinanceRepository.formatRupiah(-150000), '-Rp150.000');
    });

    test('FinanceTransaction formattedAmountWithSign includes +/- signs', () {
      final incomeTx = FinanceTransaction(
        id: '1',
        title: 'Iced Latte',
        type: TransactionType.income,
        category: FinanceCategory.sales,
        amount: 45000,
        source: TransactionSource.posAutomatic,
        timestamp: DateTime.now(),
      );

      final expenseTx = FinanceTransaction(
        id: '2',
        title: 'Sugar',
        type: TransactionType.expense,
        category: FinanceCategory.ingredients,
        amount: 170000,
        source: TransactionSource.manual,
        timestamp: DateTime.now(),
      );

      expect(incomeTx.formattedAmountWithSign, '+Rp45.000');
      expect(expenseTx.formattedAmountWithSign, '-Rp170.000');
    });

    test('FinanceRepository adds and calculates transactions accurately', () {
      final repo = FinanceRepository.instance;
      final initialCount = repo.transactions.length;

      repo.addTransaction(
        title: 'Pembelian Sirup Hazelnut',
        type: TransactionType.expense,
        category: FinanceCategory.ingredients,
        amount: 85000,
        source: TransactionSource.manual,
        notes: '2 Botol Sirup',
        timestamp: DateTime.now(),
      );

      expect(repo.transactions.length, initialCount + 1);
      expect(repo.transactions.first.title, 'Pembelian Sirup Hazelnut');
      expect(repo.transactions.first.amount, 85000);
    });
  });

  group('Finance UI Screen Tests', () {
    testWidgets('FinanceScreen renders Header, Cards, and Sections',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: FinanceScreen(),
        ),
      );

      // Verify Header
      expect(find.text('Keuangan'), findsOneWidget);
      expect(find.text('Pantau Uang Bisnis Anda'), findsOneWidget);
      expect(find.text('Hari Ini'), findsOneWidget);
      expect(find.text('Minggu Ini'), findsOneWidget);
      expect(find.text('Bulan Ini'), findsOneWidget);

      // Verify Stat Cards
      expect(find.text('SALDO KAS UTAMA'), findsOneWidget);
      expect(find.text('PEMASUKAN'), findsOneWidget);
      expect(find.text('PENGELUARAN'), findsOneWidget);

      // Verify Analytics & Decisions
      expect(find.text('Grafik Penjualan & Arus Kas'), findsOneWidget);
      expect(find.text('Jam Sibuk Penjualan (Peak Hours)'), findsOneWidget);
      expect(find.text('Menu Terlaris & Kontribusi'), findsOneWidget);
      expect(find.text('AIsisten Rekomendasi Bisnis'), findsOneWidget);

      // Verify Recent Transactions
      expect(find.textContaining('Transaksi'), findsWidgets);
      expect(find.text('Tambah Transaksi +'), findsOneWidget);
    });

    testWidgets('AddTransactionScreen toggles income/expense and submits',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AddTransactionScreen(initialType: TransactionType.expense),
        ),
      );

      expect(find.text('Tambah Transaksi'), findsOneWidget);
      expect(find.text('Pemasukan'), findsOneWidget);
      expect(find.text('Pengeluaran'), findsOneWidget);
      expect(find.text('Nama Transaksi'), findsOneWidget);
      expect(find.text('Tambah Pengeluaran +'), findsOneWidget);

      // Switch to Pemasukan
      await tester.tap(find.text('Pemasukan'));
      await tester.pumpAndSettle();

      expect(find.text('Tambah Pemasukan +'), findsOneWidget);
    });
  });
}
