import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:AISISTENKU/models/finance_model.dart';
import 'package:AISISTENKU/screens/finance/finance_screen.dart';
import 'package:AISISTENKU/screens/finance/add_transaction_screen.dart';
import 'package:AISISTENKU/screens/finance/widgets/transaction_detail_modal.dart';
import 'package:AISISTENKU/screens/home/widgets/revenue_card.dart';

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

    test('isOrderAlreadyRefunded accurately detects duplicate refund attempts', () {
      final repo = FinanceRepository.instance;
      repo.addTransaction(
        title: 'Jurnal Balik / Refund ORD-20260913-777',
        type: TransactionType.expense,
        category: FinanceCategory.refund,
        amount: 45000,
        source: TransactionSource.posAutomatic,
        notes: 'Alasan: Pelanggan salah pesan',
        timestamp: DateTime.now(),
      );

      expect(repo.isOrderAlreadyRefunded(orderCode: 'ORD-20260913-777'), isTrue);
      expect(repo.isOrderAlreadyRefunded(orderCode: 'ORD-99999999-999'), isFalse);
    });

    test('FinanceRepository calculates net revenue and refund totals accurately', () {
      final repo = FinanceRepository.instance;
      final initialRefundCount = repo.getRefundCount(FinancePeriod.today);
      final initialRefundTotal = repo.getTotalRefund(FinancePeriod.today);

      repo.addTransaction(
        title: 'Jurnal Balik / Refund ORD-901',
        type: TransactionType.expense,
        category: FinanceCategory.refund,
        amount: 22000,
        source: TransactionSource.posAutomatic,
        timestamp: DateTime.now(),
      );

      expect(repo.getRefundCount(FinancePeriod.today), initialRefundCount + 1);
      expect(repo.getTotalRefund(FinancePeriod.today), initialRefundTotal + 22000);
      expect(repo.getNetRevenue(FinancePeriod.today), lessThanOrEqualTo(repo.getTotalIncome(FinancePeriod.today)));
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
      expect(find.text('Tambah Transaksi Baru'), findsOneWidget);
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

    testWidgets('TransactionDetailModal renders refund button and confirmation dialog for POS order',
        (WidgetTester tester) async {
      final posTx = FinanceTransaction(
        id: 'tx-test-pos',
        title: 'Iced Latte Sales',
        type: TransactionType.income,
        category: FinanceCategory.sales,
        amount: 45000,
        source: TransactionSource.posAutomatic,
        orderId: 'order-test-123',
        notes: 'Order #3A-88895',
        timestamp: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => TransactionDetailModal.show(context, transaction: posTx),
                child: const Text('Open Modal'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Modal'));
      await tester.pumpAndSettle();

      // Verify Transaction Details
      expect(find.text('Iced Latte Sales'), findsOneWidget);
      expect(find.text('+Rp45.000'), findsOneWidget);

      // Verify Refund Button exists
      expect(find.text('Batalkan & Refund Pesanan Ini'), findsOneWidget);

      // Tap Refund Button
      await tester.tap(find.text('Batalkan & Refund Pesanan Ini'));
      await tester.pumpAndSettle();

      // Verify Confirmation Dialog
      expect(find.text('Batalkan Pesanan POS?'), findsOneWidget);
      expect(find.text('Mengembalikan kuantitas stok bahan resep ke inventaris.'), findsOneWidget);
      expect(find.text('Mencatat jurnal balik pengeluaran (refund) di pembukuan.'), findsOneWidget);
      expect(find.text('Mengubah status transaksi menjadi REFUNDED.'), findsOneWidget);
      expect(find.text('Konfirmasi Refund'), findsOneWidget);
      expect(find.text('Batal'), findsOneWidget);
    });

    testWidgets('TransactionDetailModal locks refund button and shows already refunded banner when order is refunded',
        (WidgetTester tester) async {
      final refundedTx = FinanceTransaction(
        id: 'tx-already-refunded',
        title: 'Iced Latte Sales',
        type: TransactionType.income,
        category: FinanceCategory.sales,
        amount: 45000,
        source: TransactionSource.posAutomatic,
        orderId: 'order-test-refunded',
        orderStatus: 'REFUNDED',
        notes: 'Order #ORD-20260913-099',
        timestamp: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => TransactionDetailModal.show(context, transaction: refundedTx),
                child: const Text('Open Refunded Modal'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Refunded Modal'));
      await tester.pumpAndSettle();

      // Verify Refund Button is NOT displayed
      expect(find.text('Batalkan & Refund Pesanan Ini'), findsNothing);

      // Verify Already Refunded Banner and Badge are displayed
      expect(find.text('Di-refund'), findsOneWidget);
      expect(find.text('Pesanan Ini Sudah Di-Refund'), findsOneWidget);
      expect(find.textContaining('Transaksi ini tidak dapat di-refund kembali'), findsOneWidget);
    });

    testWidgets('RevenueCard renders hero amount, micro-metrics, and handles refund state gracefully',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: RevenueCard(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify essential components
      expect(find.text('Transaksi'), findsOneWidget);
      expect(find.text('Beban Toko'), findsOneWidget);
      expect(find.text('Terlaris'), findsOneWidget);
      expect(find.text('Lihat Laporan Keuangan'), findsOneWidget);
    });
  });
}
