import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'api_service.dart';
import 'offline_sync_service.dart';
import '../../models/notification_model.dart';
import '../../models/stock_model.dart';
import '../widgets/in_app_alert_banner.dart';

/// Real-time WebSocket Gateway Client for POS cashier notifications.
///
/// Connects to backend Socket.IO server, automatically joins the current
/// business tenant room, and listens to real-time events like:
/// - `stock:low-alert`: Triggered when inventory drops below `minStock`
/// - `stock:mutated`: Triggered on any inventory change
class SocketService {
  static final SocketService instance = SocketService._internal();
  SocketService._internal();

  io.Socket? _socket;
  String? _token;
  String? _businessId;
  bool _isConnected = false;

  bool get isConnected => _isConnected;
  String? get currentBusinessId => _businessId;
  String? get currentToken => _token;

  /// Connect to the backend WebSocket Gateway with JWT auth & business room isolation.
  void connect({required String token, required String businessId}) {
    if (token.isEmpty) return;

    _token = token;
    _businessId = businessId;

    if (_socket != null) {
      if (_isConnected) {
        switchBusiness(businessId);
        return;
      }
      _socket?.dispose();
      _socket = null;
    }

    // Determine gateway base URL by stripping /api from ApiConfig.baseUrl
    final rawBase = ApiConfig.baseUrl;
    final serverUrl = rawBase.replaceAll(RegExp(r'/api(/v1)?/?$'), '');

    debugPrint('🔌 [SocketService] Connecting to $serverUrl for business $businessId');

    try {
      _socket = io.io(
        serverUrl,
        io.OptionBuilder()
          .setTransports(['websocket', 'polling'])
          .enableAutoConnect()
          .enableReconnection()
          .setReconnectionDelay(2000)
          .setReconnectionAttempts(15)
          .setAuth({
            'token': token,
            'businessId': businessId,
          })
          .setExtraHeaders({
            'Authorization': 'Bearer $token',
            'X-Business-Id': businessId,
          })
          .build(),
      );

      _socket?.onConnect((_) {
        _isConnected = true;
        debugPrint('🟢 [SocketService] Connected to real-time gateway');
        OfflineSyncService.instance.onConnectionRestored();
      });

      _socket?.onConnectError((data) {
        _isConnected = false;
        debugPrint('⚠️ [SocketService] Connection error: $data');
      });

      _socket?.onDisconnect((reason) {
        _isConnected = false;
        debugPrint('🔴 [SocketService] Disconnected: $reason');
      });

      _socket?.on('ws:ready', (data) {
        debugPrint('⚡ [SocketService] Gateway ready: $data');
      });

      // ── Event: stock:low-alert ──────────────────────────────────────────
      _socket?.on('stock:low-alert', (data) {
        _handleStockLowAlert(data);
      });

      // ── Event: stock:mutated ────────────────────────────────────────────
      _socket?.on('stock:mutated', (data) {
        _handleStockMutated(data);
      });
    } catch (e) {
      debugPrint('💥 [SocketService] Initialization failed: $e');
    }
  }

  /// Switch to a different business tenant room (e.g. multi-outlet branch switch).
  void switchBusiness(String newBusinessId) {
    if (newBusinessId.isEmpty) return;
    _businessId = newBusinessId;
    if (_socket != null && _isConnected) {
      _socket?.emit('business:switch', newBusinessId);
    }
  }

  /// Handler for low stock warnings pushed from the backend.
  void _handleStockLowAlert(dynamic data) {
    debugPrint('🚨 [SocketService] stock:low-alert received: $data');
    if (data == null || data is! Map) return;

    final alerts = data['alerts'];
    if (alerts == null || alerts is! List || alerts.isEmpty) return;

    // Trigger physical feedback
    HapticFeedback.heavyImpact();
    SystemSound.play(SystemSoundType.alert);

    // Refresh stock list immediately so data on screen updates in real time
    StockRepository.instance.fetchStocksFromBackend();

    final orderCode = data['orderCode']?.toString();
    final firstAlert = alerts.first;
    if (firstAlert is! Map) return;

    final name = firstAlert['name']?.toString() ?? 'Bahan';
    final currentStock = firstAlert['currentStock'];
    final minStock = firstAlert['minStock'];
    final unit = firstAlert['unit']?.toString() ?? 'unit';
    final severity = firstAlert['severity']?.toString();

    String title;
    String message;

    if (alerts.length == 1) {
      final isCritical = severity == 'critical';
      title = isCritical
          ? '🚨 STOK KRITIS: $name!'
          : '⚠️ Peringatan Stok: $name Menipis';
      message = orderCode != null
          ? 'Akibat pesanan $orderCode, sisa stok $name tinggal $currentStock $unit (min: $minStock $unit). Segera restock!'
          : 'Sisa stok $name tinggal $currentStock $unit (batas aman: $minStock $unit). Segera lakukan pemesanan ulang!';
    } else {
      title = '🚨 ${alerts.length} Bahan Baku di Bawah Batas Minimum!';
      final summaryList = alerts.take(3).map((a) {
        if (a is Map) {
          return '${a['name']} (${a['currentStock']} ${a['unit']})';
        }
        return '';
      }).where((s) => s.isNotEmpty).join(', ');

      message = orderCode != null
          ? 'Transaksi $orderCode menghabiskan stok: $summaryList${alerts.length > 3 ? ', dll' : ''}.'
          : 'Bahan baku perlu restock segera: $summaryList.';
    }

    InAppAlertBanner.showGlobal(
      title: title,
      message: message,
      type: NotificationType.stockAlert,
      actionLabel: 'Cek Stok',
      duration: const Duration(seconds: 6),
    );
  }

  /// Handler for stock mutation (silent background refresh).
  void _handleStockMutated(dynamic data) {
    debugPrint('📦 [SocketService] stock:mutated received: $data');
    StockRepository.instance.fetchStocksFromBackend();
  }

  /// Disconnect socket on user logout.
  void disconnect() {
    if (_socket != null) {
      _socket?.disconnect();
      _socket?.dispose();
      _socket = null;
    }
    _isConnected = false;
    _token = null;
    _businessId = null;
    debugPrint('🔌 [SocketService] Closed and cleaned up');
  }
}
