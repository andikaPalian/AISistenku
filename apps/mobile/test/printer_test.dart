import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:AISISTENKU/core/services/thermal_printer_service.dart';
import 'package:AISISTENKU/models/product.dart';
import 'package:AISISTENKU/models/profile_model.dart';
import 'package:AISISTENKU/screens/pos/payment_success_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final dummyCart = [
    CartItem(
      product: Product(
        id: 'prod-01',
        name: 'Kopi Susu Gula Aren',
        code: 'KOP-01',
        category: ProductCategory.kopi,
        price: 18000,
        stock: 50,
      ),
      quantity: 2,
    ),
    CartItem(
      product: Product(
        id: 'prod-02',
        name: 'Croissant Butter',
        code: 'PAS-01',
        category: ProductCategory.snack,
        price: 22000,
        stock: 20,
      ),
      quantity: 1,
    ),
  ];

  final dummyOrder = OrderRecord(
    orderId: 'TRX-123456',
    orderCode: '#3A-123456',
    orderType: OrderType.dineIn,
    tableNumber: '04',
    customerName: 'Kak Budi',
    items: dummyCart,
    subtotal: 58000,
    tax: 5800,
    total: 63800,
    paymentMethod: PaymentMethodType.cash,
    cashGiven: 70000,
    change: 6200,
    createdAt: DateTime(2026, 9, 13, 14, 30),
  );

  group('ThermalPrinterService Unit Tests', () {
    test('Service instance is singleton and initializes with default 58mm paper', () {
      final service = ThermalPrinterService.instance;
      expect(service, isNotNull);
      expect(service.paperSize, equals(ThermalPaperSize.mm58));
      expect(service.paperSize.maxChars, equals(32));
    });

    test('Change paper size updates state and max characters for 80mm', () {
      final service = ThermalPrinterService.instance;
      service.setPaperSize(ThermalPaperSize.mm80);
      expect(service.paperSize, equals(ThermalPaperSize.mm80));
      expect(service.paperSize.maxChars, equals(48));

      // Reset back to 58mm
      service.setPaperSize(ThermalPaperSize.mm58);
      expect(service.paperSize, equals(ThermalPaperSize.mm58));
    });

    test('getPairedDevices returns list without throwing in non-hardware environment', () async {
      final service = ThermalPrinterService.instance;
      final devices = await service.getPairedDevices();
      expect(devices, isNotEmpty);
      expect(devices.first.name, isNotNull);
    });

    test('generateReceiptBytes produces valid ESC/POS byte sequence for 58mm and 80mm', () async {
      final service = ThermalPrinterService.instance;
      const business = BusinessProfile(
        id: 'biz-01',
        name: 'Kedai Kopi Uji Coba',
        category: 'Cafe',
        address: 'Jl. Ahmad Yani No. 12',
        phone: '081234567890',
        operationalHours: '08:00 - 22:00',
        taxPercentage: 10.0,
        receiptFooter: 'Terima kasih atas kunjungannya!',
      );

      // 58mm
      service.setPaperSize(ThermalPaperSize.mm58);
      final bytes58 = await service.generateReceiptBytes(
        order: dummyOrder,
        business: business,
      );
      expect(bytes58, isNotEmpty);
      expect(bytes58.length, greaterThan(50));

      // 80mm
      service.setPaperSize(ThermalPaperSize.mm80);
      final bytes80 = await service.generateReceiptBytes(
        order: dummyOrder,
        business: business,
      );
      expect(bytes80, isNotEmpty);
      expect(bytes80.length, greaterThan(50));
    });

    test('formatReceiptText generates structured WhatsApp/plain text message', () {
      final service = ThermalPrinterService.instance;
      const business = BusinessProfile(
        id: 'biz-01',
        name: 'Kedai Kopi Uji Coba',
        category: 'Cafe',
        address: 'Jl. Ahmad Yani No. 12',
        phone: '081234567890',
        operationalHours: '08:00 - 22:00',
        taxPercentage: 10.0,
        receiptFooter: 'Sampai Jumpa Kembali!',
      );

      final text = service.formatReceiptText(
        order: dummyOrder,
        business: business,
      );

      expect(text, contains('KEDAI KOPI UJI COBA'));
      expect(text, contains('#3A-123456'));
      expect(text, contains('Kopi Susu Gula Aren'));
      expect(text, contains('Croissant Butter'));
      expect(text, contains('Rp63.800'));
      expect(text, contains('Sampai Jumpa Kembali!'));
    });
  });

  group('PaymentSuccessScreen Widget Tests', () {
    setUp(() {
      ProfileRepository.instance.updatePreferences(autoPrintReceipt: false);
    });

    testWidgets('PaymentSuccessScreen displays order details, thermal printer status, and action buttons', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: PaymentSuccessScreen(
            order: dummyOrder,
            onNewTransaction: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Screen Elements
      expect(find.text('Pembayaran Berhasil!'), findsOneWidget);
      expect(find.text('#3A-123456'), findsWidgets);
      expect(find.textContaining('Printer Thermal'), findsOneWidget);
      expect(find.text('Hubungkan'), findsOneWidget);
      expect(find.text('Cetak Struk'), findsOneWidget);
      expect(find.text('Kirim Struk'), findsOneWidget);
      expect(find.text('Transaksi Baru'), findsOneWidget);
    });

    testWidgets('Tap Kirim Struk opens Share Modal with WhatsApp format', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: PaymentSuccessScreen(
            order: dummyOrder,
            onNewTransaction: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      final shareBtn = find.text('Kirim Struk');
      expect(shareBtn, findsOneWidget);
      await tester.tap(shareBtn);
      await tester.pumpAndSettle();

      // Verify Share Modal
      expect(find.text('Kirim & Bagikan Struk Digital'), findsOneWidget);
      expect(find.text('Salin Format WhatsApp'), findsOneWidget);
      expect(find.text('Salin Teks Lengkap'), findsOneWidget);
    });

    testWidgets('Tap Hubungkan opens PrinterSelectionModal and allows switching 58mm/80mm', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: PaymentSuccessScreen(
            order: dummyOrder,
            onNewTransaction: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      final connectBtn = find.text('Hubungkan');
      expect(connectBtn, findsOneWidget);
      await tester.tap(connectBtn);
      await tester.pumpAndSettle();

      // Verify Modal rendered
      expect(find.text('Printer Thermal Bluetooth'), findsOneWidget);
      expect(find.text('Ukuran Kertas Thermal Struk'), findsOneWidget);
      expect(find.text('58 mm'), findsWidgets);
      expect(find.text('80 mm'), findsWidgets);
      expect(find.text('Perangkat Bluetooth Berpasangan'), findsOneWidget);

      // Switch to 80mm
      await tester.tap(find.text('80 mm').first);
      await tester.pumpAndSettle();
      expect(ThermalPrinterService.instance.paperSize, equals(ThermalPaperSize.mm80));

      // Switch back to 58mm
      await tester.tap(find.text('58 mm').first);
      await tester.pumpAndSettle();
      expect(ThermalPrinterService.instance.paperSize, equals(ThermalPaperSize.mm58));
    });
  });
}
