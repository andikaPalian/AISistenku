import 'package:flutter/material.dart';
import '../core/services/api_service.dart';
import 'stock_model.dart';
import 'finance_model.dart';
import 'profile_model.dart';

/// Sender of the AI Chat message.
enum ChatSender {
  user,
  ai,
}

/// Message payload & card display types.
enum AiMessageType {
  text,
  businessSummary,
  actionConfirm,
  contentCaption,
  stockAlert,
}

/// Status of the detected action.
enum AiActionStatus {
  pending,
  confirmed,
  cancelled,
}

/// Data payload for executable AI actions and creative content.
class AiActionPayload {
  final String actionId;
  final String intent; // 'ADD_STOCK_AND_EXPENSE', 'ADD_EXPENSE', 'RESTOCK', 'PROMO_CAPTION'
  final String? itemName;
  final double? quantity;
  final String? unit;
  final double? expenseAmount;
  final String? category;
  final String? captionTitle;
  final String? captionText;
  final List<String>? hashtags;
  final String? platform; // 'Instagram', 'TikTok', 'WhatsApp'
  final String? tone; // 'Santai', 'Gen-Z', 'Estetik'
  AiActionStatus status;

  AiActionPayload({
    required this.actionId,
    required this.intent,
    this.itemName,
    this.quantity,
    this.unit,
    this.expenseAmount,
    this.category,
    this.captionTitle,
    this.captionText,
    this.hashtags,
    this.platform,
    this.tone,
    this.status = AiActionStatus.pending,
  });
}

/// Single AI Chat message entity.
class AiChatMessage {
  final String id;
  final ChatSender sender;
  final String text;
  final AiMessageType type;
  final DateTime timestamp;
  final AiActionPayload? actionPayload;
  final Map<String, dynamic>? extraData;

  AiChatMessage({
    required this.id,
    required this.sender,
    required this.text,
    this.type = AiMessageType.text,
    required this.timestamp,
    this.actionPayload,
    this.extraData,
  });
}

/// Repository managing chat history, intelligent NLP intent recognition,
/// and bidirectional database/repository mutations.
class AiChatRepository extends ChangeNotifier {
  static final AiChatRepository instance = AiChatRepository._internal();

  AiChatRepository._internal() {
    _seedChat();
  }

  final List<AiChatMessage> _messages = [];
  bool _isTyping = false;

  List<AiChatMessage> get messages => List.unmodifiable(_messages);
  bool get isTyping => _isTyping;

  void clearForNewUser() {
    _messages.clear();
    notifyListeners();
  }

  void loadDemoData() {
    _messages.clear();
    _seedChat();
    notifyListeners();
  }

  void _seedChat() {
    _messages.clear();
    final name = ProfileRepository.instance.user.name.split(' ').first;
    final greetingPrefix = (name.isNotEmpty && name.toLowerCase() != 'owner') ? 'Halo, $name!' : 'Halo!';

    _messages.add(
      AiChatMessage(
        id: 'msg-welcome',
        sender: ChatSender.ai,
        text:
            '$greetingPrefix Saya AIsistenku, asisten cerdas untuk kelola toko & kedai Anda.\n\nAda yang bisa saya bantu hari ini? Anda bisa menanyakan omzet penjualan, mengecek ketersediaan stok bahan, mencatat pengeluaran belanja, atau membuat caption promosi media sosial.',
        type: AiMessageType.text,
        timestamp: DateTime.now(),
      ),
    );
  }

  /// Fetch previous messages from backend API.
  Future<void> fetchMessagesFromBackend() async {
    try {
      final res = await ApiService.instance.get('/ai/messages');
      if (res != null && res['messages'] is List) {
        final List list = res['messages'];
        if (list.isNotEmpty) {
          final List<AiChatMessage> loaded = [];
          for (final m in list) {
            final sender = m['sender'] == 'USER' ? ChatSender.user : ChatSender.ai;
            final typeStr = m['type'] ?? 'text';
            AiMessageType msgType = AiMessageType.text;
            AiActionPayload? actionPayload;
            Map<String, dynamic>? extraData;

            final rawAction = m['actionPayload'] ?? m['extraData'] ?? m['extra_data'];
            if ((typeStr == 'actionConfirm' || typeStr == 'action_confirmation') && rawAction != null) {
              msgType = AiMessageType.actionConfirm;
              final ap = rawAction;
              final payload = ap['payload'] is Map ? ap['payload'] : ap;
              actionPayload = AiActionPayload(
                actionId: ap['actionId'] ?? ap['id'] ?? 'act-001',
                intent: ap['intent'] ?? 'ADD_STOCK',
                itemName: payload['itemName'] ?? payload['item'] ?? 'Bahan',
                quantity: (payload['quantity'] as num?)?.toDouble() ?? 1.0,
                unit: payload['unit'] ?? 'unit',
                expenseAmount: (payload['expenseAmount'] ?? payload['amount'] as num?)?.toDouble(),
                category: payload['category'] ?? 'Bahan Baku',
                status: (ap['status'] == 'CONFIRMED' || ap['status'] == 'confirmed')
                    ? AiActionStatus.confirmed
                    : AiActionStatus.pending,
              );
            } else if (typeStr == 'businessSummary') {
              msgType = AiMessageType.businessSummary;
              if (m['extra_data'] is Map) extraData = Map<String, dynamic>.from(m['extra_data']);
            } else if (typeStr == 'contentCaption') {
              msgType = AiMessageType.contentCaption;
              if (m['actionPayload'] != null) {
                final ap = m['actionPayload'];
                actionPayload = AiActionPayload(
                  actionId: ap['actionId'] ?? 'cap-001',
                  intent: ap['intent'] ?? 'PROMO_CAPTION',
                  captionTitle: ap['captionTitle'],
                  captionText: ap['captionText'],
                  hashtags: ap['hashtags'] != null ? List<String>.from(ap['hashtags']) : null,
                  platform: ap['platform'],
                  tone: ap['tone'],
                  status: AiActionStatus.pending,
                );
              }
            }
            loaded.add(AiChatMessage(
              id: m['message_id'] ?? m['id'] ?? 'msg-${DateTime.now().millisecondsSinceEpoch}',
              sender: sender,
              text: m['text'] ?? '',
              type: msgType,
              actionPayload: actionPayload,
              extraData: extraData,
              timestamp: m['timestamp'] != null
                  ? DateTime.tryParse(m['timestamp']) ?? DateTime.now()
                  : DateTime.now(),
            ));
          }
          if (loaded.isNotEmpty) {
            _messages.clear();
            _messages.addAll(loaded);
            notifyListeners();
          }
        }
      }
    } catch (e) {
      debugPrint('⚠️ Fetch AI messages error: $e');
    }
  }

  /// Send user message and trigger automated AI intelligence via Backend API.
  Future<void> sendMessage(String text) async {
    final cleanText = text.trim();
    if (cleanText.isEmpty) return;

    final userMsg = AiChatMessage(
      id: 'msg-${DateTime.now().millisecondsSinceEpoch}',
      sender: ChatSender.user,
      text: cleanText,
      type: AiMessageType.text,
      timestamp: DateTime.now(),
    );

    _messages.add(userMsg);
    _isTyping = true;
    notifyListeners();

    try {
      // 1. Send to Backend AI API
      final res = await ApiService.instance.post('/ai/chat', {'text': cleanText});
      if (res != null && res['aiResponse'] != null) {
        final r = res['aiResponse'];
        final resText = (r['text'] ?? '').toString();
        final resTypeStr = (r['type'] ?? 'text').toString();

        AiMessageType msgType = AiMessageType.text;
        AiActionPayload? actionPayload;
        Map<String, dynamic>? extraData;

        final rawAction = r['actionPayload'] ?? r['extraData'] ?? res['action'];
        if ((resTypeStr == 'actionConfirm' || resTypeStr == 'action_confirmation') && rawAction != null) {
          msgType = AiMessageType.actionConfirm;
          final ap = rawAction;
          final payload = ap['payload'] is Map ? ap['payload'] : ap;
          actionPayload = AiActionPayload(
            actionId: ap['actionId'] ?? ap['id'] ?? 'act-${DateTime.now().millisecondsSinceEpoch}',
            intent: ap['intent'] ?? 'ADD_STOCK',
            itemName: payload['itemName'] ?? payload['item'] ?? 'Bahan',
            quantity: (payload['quantity'] as num?)?.toDouble() ?? 1.0,
            unit: payload['unit'] ?? 'unit',
            expenseAmount: (payload['expenseAmount'] ?? payload['amount'] as num?)?.toDouble(),
            category: payload['category'] ?? 'Bahan Baku',
            status: (ap['status'] == 'CONFIRMED' || ap['status'] == 'confirmed')
                ? AiActionStatus.confirmed
                : AiActionStatus.pending,
          );
        } else if (resTypeStr == 'businessSummary') {
          msgType = AiMessageType.businessSummary;
          if (r['extra_data'] != null && r['extra_data'] is Map) {
            extraData = Map<String, dynamic>.from(r['extra_data']);
          }
        } else if (resTypeStr == 'contentCaption') {
          msgType = AiMessageType.contentCaption;
          if (r['actionPayload'] != null) {
            final ap = r['actionPayload'];
            actionPayload = AiActionPayload(
              actionId: ap['actionId'] ?? 'cap-${DateTime.now().millisecondsSinceEpoch}',
              intent: ap['intent'] ?? 'PROMO_CAPTION',
              captionTitle: ap['captionTitle'],
              captionText: ap['captionText'],
              hashtags: ap['hashtags'] != null ? List<String>.from(ap['hashtags']) : null,
              platform: ap['platform'],
              tone: ap['tone'],
              status: AiActionStatus.pending,
            );
          }
        }

        final aiMsg = AiChatMessage(
          id: r['message_id'] ?? 'msg-${DateTime.now().millisecondsSinceEpoch}',
          sender: ChatSender.ai,
          text: resText,
          type: msgType,
          actionPayload: actionPayload,
          extraData: extraData,
          timestamp: DateTime.now(),
        );

        _messages.add(aiMsg);
        _isTyping = false;
        notifyListeners();
        return;
      }
    } catch (e) {
      debugPrint('⚠️ Backend AI error, falling back to local NLP: $e');
    }

    // 2. Offline / Local Fallback NLP Engine
    await Future.delayed(const Duration(milliseconds: 600));
    final aiResponse = _generateAiResponse(cleanText);
    _messages.add(aiResponse);
    _isTyping = false;
    notifyListeners();
  }

  /// Manually add a chat message.
  void addMessage(AiChatMessage msg) {
    _messages.add(msg);
    notifyListeners();
  }

  /// Confirm and execute an action (mutates Stock and Finance repositories & backend).
  void confirmAction(String actionId) {
    // Sync with backend action confirmation
    ApiService.instance.post('/ai/actions/$actionId/confirm', {}).catchError((_) => null);

    for (final msg in _messages) {
      if (msg.actionPayload != null &&
          msg.actionPayload!.actionId == actionId) {
        final payload = msg.actionPayload!;
        payload.status = AiActionStatus.confirmed;

        // 1. Mutate Stock Repository if applicable
        if (payload.itemName != null && payload.quantity != null) {
          final stockRepo = StockRepository.instance;
          final existingItem = stockRepo.items.cast<StockItem?>().firstWhere(
                (item) => item!.name
                    .toLowerCase()
                    .contains(payload.itemName!.toLowerCase()),
                orElse: () => null,
              );

          if (existingItem != null) {
            stockRepo.restockItem(
              stockId: existingItem.id,
              quantity: payload.quantity!,
              note: 'Restock via konfirmasi AIsisten',
            );
          } else {
            stockRepo.addStockItem(
              StockItem(
                id: 'item_${DateTime.now().millisecondsSinceEpoch}',
                name: payload.itemName!,
                category: StockCategory.pemanis,
                currentStock: payload.quantity!,
                minStock: 5.0,
                unit: payload.unit ?? 'kg',
                costPerUnit: ((payload.expenseAmount ?? 0) /
                        (payload.quantity! > 0 ? payload.quantity! : 1))
                    .round(),
                lastUpdated: DateTime.now(),
              ),
            );
          }
        }

        // 2. Mutate Finance Repository if expense amount is present
        if (payload.expenseAmount != null && payload.expenseAmount! > 0) {
          FinanceRepository.instance.addTransaction(
            title: '${payload.itemName ?? 'Bahan Baku'} Purchase',
            type: TransactionType.expense,
            category: FinanceCategory.ingredients,
            amount: payload.expenseAmount!,
            source: TransactionSource.aiAgent,
            notes: 'Pembelian otomatis via konfirmasi AIsisten',
            timestamp: DateTime.now(),
          );
        }

        notifyListeners();
        break;
      }
    }
  }

  /// Smart rule-based Natural Language Processing engine.
  AiChatMessage _generateAiResponse(String query) {
    final lower = query.toLowerCase();
    final now = DateTime.now();

    // 1. Check for Purchase / Expense / Restock Natural Language
    if (lower.contains('beli') ||
        lower.contains('belanja') ||
        lower.contains('restock') ||
        lower.contains('habis beli')) {
      double qty = 5;
      String unit = 'kg';
      String item = 'Bahan Baku';
      double price = 100000;

      // Extract quantity
      final qtyRegex = RegExp(r'(\d+)\s*(kg|g|liter|l|botol|btl|dus|karton|pack|pcs)');
      final qtyMatch = qtyRegex.firstMatch(lower);
      if (qtyMatch != null) {
        qty = double.tryParse(qtyMatch.group(1) ?? '5') ?? 5;
        unit = qtyMatch.group(2) ?? 'kg';
      }

      // Extract item name
      if (lower.contains('gula')) {
        item = 'Sugar';
      } else if (lower.contains('kopi') || lower.contains('beans')) {
        item = 'Coffee Beans';
      } else if (lower.contains('susu') || lower.contains('milk')) {
        item = 'Fresh Milk';
        unit = 'L';
      } else if (lower.contains('sirup') || lower.contains('syrup')) {
        item = 'Caramel Syrup';
        unit = 'btl';
      } else if (lower.contains('cup') || lower.contains('gelas')) {
        item = 'Paper Cup 16oz';
        unit = 'pcs';
      } else {
        item = 'Bahan Baku';
      }

      // Extract price
      final priceRegex = RegExp(r'(\d+)\s*(rb|ribu|k|000)');
      final priceMatch = priceRegex.firstMatch(lower);
      if (priceMatch != null) {
        final rawNum = int.tryParse(priceMatch.group(1) ?? '100') ?? 100;
        final unitStr = priceMatch.group(2) ?? 'rb';
        if (unitStr == '000') {
          price = rawNum.toDouble() * 1000;
        } else {
          price = rawNum.toDouble() * 1000;
        }
      } else if (lower.contains('170rb') || lower.contains('170.000')) {
        price = 170000;
      }

      return AiChatMessage(
        id: 'msg-${DateTime.now().millisecondsSinceEpoch}',
        sender: ChatSender.ai,
        text: 'Saya mendeteksi transaksi pembelian baru. Apakah ingin saya catat ke Stok & Keuangan?',
        type: AiMessageType.actionConfirm,
        timestamp: now,
        actionPayload: AiActionPayload(
          actionId: 'act-${DateTime.now().millisecondsSinceEpoch}',
          intent: 'ADD_STOCK_AND_EXPENSE',
          itemName: item,
          quantity: qty,
          unit: unit,
          expenseAmount: price,
          category: 'Bahan Baku',
          status: AiActionStatus.pending,
        ),
      );
    }

    // 2. Check for Social Media / Caption / Promo Content Generation
    if (lower.contains('caption') ||
        lower.contains('konten') ||
        lower.contains('sosmed') ||
        lower.contains('promo') ||
        lower.contains('ide')) {
      String title = 'Rekomendasi Konten Instagram & TikTok';
      String caption =
          '☕ Ngantuk di jam rawan siang? Tenang, segelas Kopi Susu Gula Aren racikan spesial @KopiTiga siap balikin semangatmu!\n\nPaduan espresso mantap, susu creamy, dan manis legit aren asli bikin harimu makin fokus. Yuk mampir atau order via POS sekarang!';
      List<String> hashtags = [
        '#KopiSusuAren',
        '#NgopiSore',
        '#PromoKopi',
        '#CoffeeShopLife',
        '#UMKMJuara'
      ];

      if (lower.contains('diskon') || lower.contains('jumat')) {
        title = 'Promo Spesial Jumat Berkah 🎁';
        caption =
            '✨ Jumat Berkah, ngopi makin hemat! Dapatkan Diskon 20% untuk semua varian Non-Kopi & Snack setiap pembelian Kopi Susu Aren hari ini.\n\nTag teman nongkrongmu dan serbu outlet sebelum kehabisan!';
        hashtags = ['#JumatBerkah', '#PromoJumat', '#DiskonKopi', '#KopiLokal'];
      }

      return AiChatMessage(
        id: 'msg-${DateTime.now().millisecondsSinceEpoch}',
        sender: ChatSender.ai,
        text: 'Berikut rekomendasi ide konten dan caption menarik yang siap Anda gunakan:',
        type: AiMessageType.contentCaption,
        timestamp: now,
        actionPayload: AiActionPayload(
          actionId: 'cap-${DateTime.now().millisecondsSinceEpoch}',
          intent: 'PROMO_CAPTION',
          captionTitle: title,
          captionText: caption,
          hashtags: hashtags,
          platform: 'Instagram & TikTok',
          tone: 'Santai & Menarik',
        ),
      );
    }

    // 3. Check for Stock Inquiries
    if (lower.contains('stok') || lower.contains('habis') || lower.contains('bahan')) {
      final lowStockItems = StockRepository.instance.items
          .where((i) => i.status == StockStatus.kritis || i.status == StockStatus.rendah)
          .toList();

      return AiChatMessage(
        id: 'msg-${DateTime.now().millisecondsSinceEpoch}',
        sender: ChatSender.ai,
        text: lowStockItems.isNotEmpty
            ? 'Ada ${lowStockItems.length} bahan baku yang perlu diperhatikan karena berada di bawah batas aman minimum:'
            : 'Semua stok bahan baku saat ini berada dalam kondisi aman (Baik).',
        type: AiMessageType.stockAlert,
        timestamp: now,
        extraData: {
          'lowItems': lowStockItems
              .map((i) => {
                    'name': i.name,
                    'qty': i.currentStock,
                    'unit': i.unit,
                    'status': i.status.label,
                  })
              .toList(),
        },
      );
    }

    // 4. Check for Greeting (Hi, Halo, etc.)
    final isGreeting = RegExp(r'^(hi|halo|hello|hai|p|hey|assalamualaikum|selamat|tes|ping)\b', caseSensitive: false).hasMatch(lower.trim());
    if (isGreeting) {
      return AiChatMessage(
        id: 'msg-${DateTime.now().millisecondsSinceEpoch}',
        sender: ChatSender.ai,
        text:
            'Halo! Saya AIsisten, partner cerdas untuk kelola toko Anda. Ada yang bisa saya bantu hari ini? Anda bisa minta saya cek stok bahan, catat pengeluaran belanja, lihat analisis laba rugi, atau ide konten promo medsos!',
        type: AiMessageType.text,
        timestamp: now,
      );
    }

    // 5. Default / Business Overview Query
    final finRepo = FinanceRepository.instance;
    final income = finRepo.getTotalIncome(FinancePeriod.today).toDouble();
    final expense = finRepo.getTotalExpense(FinancePeriod.today).toDouble();
    final profit = income - expense;

    return AiChatMessage(
      id: 'msg-${DateTime.now().millisecondsSinceEpoch}',
      sender: ChatSender.ai,
      text:
          'Kinerja bisnis hari ini berjalan lancar. Total penjualan mencapai ${FinanceRepository.formatRupiah(income)} dengan laba bersih estimasi ${FinanceRepository.formatRupiah(profit)}.',
      type: AiMessageType.businessSummary,
      timestamp: now,
      extraData: {
        'revenue': income,
        'profit': profit,
        'expense': expense,
        'bestSeller': 'Iced Aren Latte',
      },
    );
  }

  /// Clear chat messages and reset to initial AI greeting.
  void clearChat() {
    _messages.clear();
    _seedChat();
    notifyListeners();
    ApiService.instance.delete('/ai/messages').catchError((_) => null);
  }
}
