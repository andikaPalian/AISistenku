import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:AISISTENKU/core/services/offline_sync_service.dart';
import 'package:AISISTENKU/models/product.dart';
import 'package:AISISTENKU/models/profile_model.dart';
import 'package:AISISTENKU/screens/pos/widgets/offline_sync_modal.dart';
import 'package:AISISTENKU/screens/pos/payment_success_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final dummyCart = [
    CartItem(
      product: const Product(
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
      product: const Product(
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
    orderId: 'TRX-OFFLINE-001',
    orderCode: '#3A-OFF-001',
    orderType: OrderType.dineIn,
    tableNumber: '05',
    customerName: 'Kak Doni',
    items: dummyCart,
    subtotal: 58000,
    tax: 5800,
    total: 63800,
    paymentMethod: PaymentMethodType.cash,
    cashGiven: 70000,
    change: 6200,
    createdAt: DateTime(2026, 9, 13, 15, 0),
  );

  final dummyPayload = {
    'orderCode': '#3A-OFF-001',
    'orderType': 'DineIn',
    'tableNumber': '05',
    'customerName': 'Kak Doni',
    'paymentMethod': 'Cash',
    'subtotal': 58000,
    'tax': 5800,
    'totalAmount': 63800,
    'cashGiven': 70000,
    'changeAmount': 6200,
    'items': [
      {
        'productId': 'prod-01',
        'productName': 'Kopi Susu Gula Aren',
        'quantity': 2,
        'price': 18000,
        'subtotal': 36000,
      },
      {
        'productId': 'prod-02',
        'productName': 'Croissant Butter',
        'quantity': 1,
        'price': 22000,
        'subtotal': 22000,
      },
    ],
  };

  group('OfflineOrder Model Serialization Tests', () {
    test('OfflineOrder serialization and deserialization retains full data fidelity', () {
      final offlineOrder = OfflineOrder(
        id: dummyOrder.orderId,
        orderRecord: dummyOrder,
        backendPayload: dummyPayload,
        createdAt: DateTime(2026, 9, 13, 15, 0),
        syncStatus: OfflineSyncStatus.pending,
      );

      final json = offlineOrder.toJson();
      expect(json['id'], equals('TRX-OFFLINE-001'));
      expect(json['syncStatus'], equals('pending'));

      final restored = OfflineOrder.fromJson(json);
      expect(restored.id, equals('TRX-OFFLINE-001'));
      expect(restored.orderRecord.orderCode, equals('#3A-OFF-001'));
      expect(restored.orderRecord.items.length, equals(2));
      expect(restored.orderRecord.total, equals(63800));
      expect(restored.orderRecord.tableNumber, equals('05'));
      expect(restored.orderRecord.customerName, equals('Kak Doni'));
      expect(restored.isPending, isTrue);
      expect(restored.isSynced, isFalse);
    });

    test('Status transitions work properly for syncing and synced', () {
      final offlineOrder = OfflineOrder(
        id: 'TRX-101',
        orderRecord: dummyOrder,
        backendPayload: dummyPayload,
        createdAt: DateTime.now(),
      );

      expect(offlineOrder.syncStatus, equals(OfflineSyncStatus.pending));
      offlineOrder.syncStatus = OfflineSyncStatus.syncing;
      expect(offlineOrder.isPending, isTrue);

      offlineOrder.syncStatus = OfflineSyncStatus.synced;
      expect(offlineOrder.isSynced, isTrue);
      expect(offlineOrder.isPending, isFalse);
    });
  });

  group('OfflineSyncService Local Cache & Queue Tests', () {
    late OfflineSyncService service;

    setUp(() async {
      service = OfflineSyncService.instance;
      await service.init();
      await service.clearForTesting();
    });

    test('Initial service state has 0 pending orders', () {
      expect(service.pendingCount, equals(0));
      expect(service.hasPending, isFalse);
      expect(service.allOrders, isEmpty);
    });

    test('processAndQueueOrder adds order to local cache queue', () async {
      final queued = await service.processAndQueueOrder(
        order: dummyOrder,
        backendPayload: dummyPayload,
      );

      // In test environment without backend, it returns false (kept in offline queue)
      expect(queued, isFalse);
      expect(service.allOrders.length, equals(1));
      expect(service.allOrders.first.id, equals('TRX-OFFLINE-001'));
      expect(service.isOrderPending('TRX-OFFLINE-001'), isTrue);
    });

    test('Clear synced orders removes only synced items from local database', () async {
      await service.processAndQueueOrder(
        order: dummyOrder,
        backendPayload: dummyPayload,
      );

      // Mark order as synced manually for testing purge
      final item = service.allOrders.first;
      item.syncStatus = OfflineSyncStatus.synced;
      item.syncedAt = DateTime.now();

      expect(service.syncedOrders.length, equals(1));
      expect(service.pendingOrders.length, equals(0));

      await service.clearSyncedOrders();
      expect(service.allOrders, isEmpty);
    });
  });

  group('OfflineSyncModal UI Widget Tests', () {
    setUp(() async {
      final service = OfflineSyncService.instance;
      await service.init();
      await service.clearForTesting();
      await service.processAndQueueOrder(
        order: dummyOrder,
        backendPayload: dummyPayload,
      );
    });

    testWidgets('OfflineSyncModal displays header, banner, KPI counter, and offline order cards', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: OfflineSyncModal(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Header
      expect(find.text('Antrean Pesanan Offline'), findsOneWidget);
      expect(find.text('Penyimpanan lokal Hive & auto-sync'), findsOneWidget);

      // Verify KPI Counters
      expect(find.text('Menunggu'), findsOneWidget);
      expect(find.text('Tersinkron'), findsOneWidget);
      expect(find.text('1 Pesanan'), findsOneWidget);

      // Verify Order Card
      expect(find.text('#3A-OFF-001'), findsOneWidget);
      expect(find.textContaining('Kopi Susu Gula Aren'), findsOneWidget);
      expect(find.text('Rp63.800'), findsOneWidget);

      // Verify Bottom Button
      expect(find.textContaining('Sinkronkan'), findsOneWidget);
    });
  });

  group('PaymentSuccessScreen Offline Notice Tests', () {
    setUp(() async {
      ProfileRepository.instance.updatePreferences(autoPrintReceipt: false);
      final service = OfflineSyncService.instance;
      await service.init();
      await service.clearForTesting();
      await service.processAndQueueOrder(
        order: dummyOrder,
        backendPayload: dummyPayload,
      );
    });

    testWidgets('PaymentSuccessScreen renders offline cache banner when order is pending in queue', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: PaymentSuccessScreen(
            order: dummyOrder,
            onNewTransaction: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Offline Notice in Receipt
      expect(find.text('Tersimpan di Cache Offline Kasir'), findsOneWidget);
      expect(find.textContaining('Pesanan aman di memori Hive'), findsOneWidget);
    });
  });
}
