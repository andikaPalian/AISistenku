import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'api_service.dart';
import '../../models/product.dart';
import '../../models/stock_model.dart';
import '../../models/finance_model.dart';

/// Status of an offline order in the local synchronization queue.
enum OfflineSyncStatus {
  pending('Menunggu Sinkronisasi', Icons.cloud_upload_outlined, Color(0xFFEAB308)),
  syncing('Sedang Sinkronisasi...', Icons.sync_rounded, Color(0xFF0284C7)),
  synced('Tersinkronisasi ke Server', Icons.check_circle_outline_rounded, Color(0xFF16A34A)),
  failed('Koneksi Gagal (Akan Diulang)', Icons.error_outline_rounded, Color(0xFFDC2626));

  final String label;
  final IconData icon;
  final Color color;
  const OfflineSyncStatus(this.label, this.icon, this.color);
}

/// Represents an order cached locally when network / Wi-Fi is offline.
class OfflineOrder {
  final String id;
  final OrderRecord orderRecord;
  final Map<String, dynamic> backendPayload;
  final DateTime createdAt;
  OfflineSyncStatus syncStatus;
  int retryCount;
  String? lastError;
  DateTime? syncedAt;

  OfflineOrder({
    required this.id,
    required this.orderRecord,
    required this.backendPayload,
    required this.createdAt,
    this.syncStatus = OfflineSyncStatus.pending,
    this.retryCount = 0,
    this.lastError,
    this.syncedAt,
  });

  bool get isPending => syncStatus != OfflineSyncStatus.synced;
  bool get isSynced => syncStatus == OfflineSyncStatus.synced;

  Map<String, dynamic> toJson() => {
    'id': id,
    'orderRecord': orderRecord.toJson(),
    'backendPayload': backendPayload,
    'createdAt': createdAt.toIso8601String(),
    'syncStatus': syncStatus.name,
    'retryCount': retryCount,
    if (lastError != null) 'lastError': lastError,
    if (syncedAt != null) 'syncedAt': syncedAt!.toIso8601String(),
  };

  factory OfflineOrder.fromJson(Map<String, dynamic> json) {
    OfflineSyncStatus status = OfflineSyncStatus.pending;
    final statusStr = json['syncStatus']?.toString();
    for (final s in OfflineSyncStatus.values) {
      if (s.name == statusStr) {
        status = s;
        break;
      }
    }

    return OfflineOrder(
      id: json['id']?.toString() ?? '',
      orderRecord: OrderRecord.fromJson(
        Map<String, dynamic>.from(json['orderRecord'] as Map),
      ),
      backendPayload: Map<String, dynamic>.from(json['backendPayload'] as Map),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      syncStatus: status,
      retryCount: (json['retryCount'] as num?)?.toInt() ?? 0,
      lastError: json['lastError']?.toString(),
      syncedAt: json['syncedAt'] != null
          ? DateTime.tryParse(json['syncedAt'].toString())
          : null,
    );
  }
}

/// Summary result after flushing pending offline orders.
class SyncBatchResult {
  final int totalAttempted;
  final int syncedCount;
  final int failedCount;
  final String message;

  const SyncBatchResult({
    required this.totalAttempted,
    required this.syncedCount,
    required this.failedCount,
    required this.message,
  });
}

/// Centralized Local Database Cache & Automatic Offline Sync Service.
///
/// Features:
/// 1. Hive Local Cache: Transactions are persisted immediately to local disk box.
/// 2. Zero-Loss POS: If cafe Wi-Fi drops, orders queue locally and cashier is never blocked.
/// 3. Auto-Flush on Reconnect: Periodically checks backend health and flushes queue when online.
/// 4. Manual Sync Trigger: Cashier can tap "Sinkronkan Sekarang" anytime.
/// 5. Reactive State: Exposes `pendingCount`, `isOnline`, `isSyncing` via ChangeNotifier.
class OfflineSyncService extends ChangeNotifier {
  static final OfflineSyncService instance = OfflineSyncService._internal();
  OfflineSyncService._internal();

  static const String _boxName = 'tiga_offline_orders_box';
  Box<String>? _box;
  bool _isInitialized = false;

  final List<OfflineOrder> _orders = [];
  bool _isOnline = true;
  bool _isSyncing = false;
  Timer? _heartbeatTimer;

  List<OfflineOrder> get allOrders => List.unmodifiable(_orders);
  List<OfflineOrder> get pendingOrders =>
      _orders.where((o) => o.isPending).toList();
  List<OfflineOrder> get syncedOrders =>
      _orders.where((o) => o.isSynced).toList();

  int get pendingCount => pendingOrders.length;
  bool get hasPending => pendingCount > 0;
  bool get isOnline => _isOnline;
  bool get isSyncing => _isSyncing;

  bool isOrderPending(String orderId) =>
      pendingOrders.any((o) => o.id == orderId);

  /// Initialize local Hive database and start connectivity listener.
  Future<void> init() async {
    if (_isInitialized) return;

    try {
      await Hive.initFlutter();
    } catch (_) {
      try {
        final tempDir = Directory.systemTemp.createTempSync('tiga_offline_test');
        Hive.init(tempDir.path);
      } catch (_) {}
    }

    try {
      _box = await Hive.openBox<String>(_boxName);
      _loadOrdersFromBox();
    } catch (e) {
      debugPrint('⚠️ [OfflineSyncService] Failed to open Hive box: $e');
    }

    _isInitialized = true;
    _startHeartbeat();
    // Immediate initial probe
    unawaited(checkConnectivityAndAutoFlush());
  }

  void _loadOrdersFromBox() {
    if (_box == null) return;
    _orders.clear();
    for (final raw in _box!.values) {
      try {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        _orders.add(OfflineOrder.fromJson(map));
      } catch (e) {
        debugPrint('⚠️ [OfflineSyncService] Corrupt offline order entry: $e');
      }
    }
    // Sort newest first
    _orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    notifyListeners();
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    // Check every 15 seconds
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      checkConnectivityAndAutoFlush();
    });
  }

  /// Check server reachability and automatically flush pending queue if online.
  Future<void> checkConnectivityAndAutoFlush() async {
    final reachable = await ApiService.instance.checkHealth();
    final wasOffline = !_isOnline;
    _isOnline = reachable;

    if (_isOnline && hasPending && !_isSyncing) {
      debugPrint('🌐 [OfflineSyncService] Connection active with $pendingCount pending orders. Auto-flushing...');
      await flushPendingOrders();
    } else if (wasOffline != !_isOnline) {
      notifyListeners();
    }
  }

  /// Hook called when Socket.IO connects or reconnects to backend gateway.
  void onConnectionRestored() {
    _isOnline = true;
    notifyListeners();
    if (hasPending && !_isSyncing) {
      flushPendingOrders();
    }
  }

  /// Process order: Saves to local Hive cache immediately, then attempts network send.
  ///
  /// Returns `true` if directly synced to server, `false` if safely stored in offline queue.
  Future<bool> processAndQueueOrder({
    required OrderRecord order,
    required Map<String, dynamic> backendPayload,
  }) async {
    // 1. Persist to local Hive box immediately (Guaranteed offline safety)
    final offlineItem = OfflineOrder(
      id: order.orderId,
      orderRecord: order,
      backendPayload: backendPayload,
      createdAt: DateTime.now(),
      syncStatus: OfflineSyncStatus.pending,
    );

    _orders.insert(0, offlineItem);
    await _persistOrder(offlineItem);
    notifyListeners();

    debugPrint('💾 [OfflineSyncService] Order ${order.orderCode} saved to local offline cache.');

    // 2. Attempt immediate dispatch to backend
    try {
      final success = await _dispatchSingleOrder(offlineItem);
      if (success) {
        _isOnline = true;
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('⚠️ [OfflineSyncService] Offline fallback: Network unavailable ($e). Held in queue.');
      _isOnline = false;
      notifyListeners();
    }

    return false;
  }

  Future<bool> _dispatchSingleOrder(OfflineOrder item) async {
    item.syncStatus = OfflineSyncStatus.syncing;
    notifyListeners();

    try {
      // Auto-repair payload if older stored offline order had missing productName/price
      final payload = Map<String, dynamic>.from(item.backendPayload);
      if (payload['items'] is List) {
        final rawList = payload['items'] as List;
        final fixedList = <Map<String, dynamic>>[];
        for (int i = 0; i < rawList.length; i++) {
          final m = Map<String, dynamic>.from(rawList[i] as Map);
          if (i < item.orderRecord.items.length) {
            final rec = item.orderRecord.items[i];
            m['productId'] ??= rec.product.id;
            m['product_id'] ??= rec.product.id;
            m['productName'] ??= rec.product.name;
            m['product_name'] ??= rec.product.name;
            m['name'] ??= rec.product.name;
            m['price'] ??= rec.product.price;
            m['unit_price'] ??= rec.product.price;
            m['quantity'] ??= rec.quantity;
            m['variant'] ??= rec.variant;
          }
          fixedList.add(m);
        }
        payload['items'] = fixedList;
      }

      await ApiService.instance.post('/orders', payload);

      item.syncStatus = OfflineSyncStatus.synced;
      item.syncedAt = DateTime.now();
      item.lastError = null;
      await _persistOrder(item);
      notifyListeners();
      return true;
    } catch (e) {
      item.syncStatus = OfflineSyncStatus.failed;
      item.retryCount++;
      item.lastError = e.toString();
      await _persistOrder(item);
      notifyListeners();
      return false;
    }
  }

  Future<void> _persistOrder(OfflineOrder item) async {
    if (_box != null) {
      await _box!.put(item.id, jsonEncode(item.toJson()));
    }
  }

  /// Flush all pending offline orders to the backend sequentially.
  Future<SyncBatchResult> flushPendingOrders({bool force = false}) async {
    if (_isSyncing) {
      return const SyncBatchResult(
        totalAttempted: 0,
        syncedCount: 0,
        failedCount: 0,
        message: 'Sinkronisasi sedang berlangsung.',
      );
    }

    final toSync = pendingOrders;
    if (toSync.isEmpty) {
      return const SyncBatchResult(
        totalAttempted: 0,
        syncedCount: 0,
        failedCount: 0,
        message: 'Tidak ada transaksi pending.',
      );
    }

    _isSyncing = true;
    notifyListeners();

    int synced = 0;
    int failed = 0;

    // Flush oldest first for chronological consistency
    final queue = toSync.reversed.toList();

    for (final item in queue) {
      final success = await _dispatchSingleOrder(item);
      if (success) {
        synced++;
      } else {
        failed++;
        // If connection is clearly down (network error) and not forced, stop batch
        final errStr = item.lastError ?? '';
        final isNetworkErr = errStr.contains('SocketException') ||
            errStr.contains('TimeoutException') ||
            errStr.contains('ClientException') ||
            errStr.contains('Connection refused') ||
            errStr.contains('Failed host lookup');

        if (!force && isNetworkErr) {
          _isOnline = false;
          debugPrint('⚠️ [OfflineSyncService] Batch halted due to offline connection.');
          break;
        }
      }
    }

    // If any order succeeded, refresh related repositories from backend
    if (synced > 0) {
      try {
        StockRepository.instance.fetchStocksFromBackend();
        ProductRepository.instance.fetchProductsFromBackend();
        FinanceRepository.instance.fetchFinanceFromBackend();
      } catch (_) {}
    }

    _isSyncing = false;
    notifyListeners();

    final summary = synced > 0
        ? 'Berhasil menyinkronkan $synced pesanan ke backend.'
        : 'Gagal menyinkronkan ($failed transaksi gagal/offline).';

    return SyncBatchResult(
      totalAttempted: synced + failed,
      syncedCount: synced,
      failedCount: failed,
      message: summary,
    );
  }

  /// Clear all successfully synced orders from local storage.
  Future<void> clearSyncedOrders() async {
    final synced = syncedOrders;
    for (final s in synced) {
      _orders.removeWhere((o) => o.id == s.id);
      await _box?.delete(s.id);
    }
    notifyListeners();
  }

  /// Reset all data (for testing or logging out).
  Future<void> clearForTesting() async {
    _orders.clear();
    await _box?.clear();
    _isOnline = true;
    _isSyncing = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _heartbeatTimer?.cancel();
    super.dispose();
  }
}
