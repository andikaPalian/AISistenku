import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'stock_model.dart';
import 'finance_model.dart';

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

  void _seedChat() {
    final now = DateTime.now();

    _messages.addAll([
      // 1. Initial User Query
      AiChatMessage(
        id: 'msg-001',
        sender: ChatSender.user,
        text: 'Bagaimana bisnis saya hari ini?',
        type: AiMessageType.text,
        timestamp: DateTime(now.year, now.month, now.day, 14, 20),
      ),
      // 2. AI Business Summary Response
      AiChatMessage(
        id: 'msg-002',
        sender: ChatSender.ai,
        text:
            'Kinerja bisnis hari ini tampak baik. Pendapatan telah mencapai Rp1.250.000, naik 12% dibandingkan kemarin.',
        type: AiMessageType.businessSummary,
        timestamp: DateTime(now.year, now.month, now.day, 14, 20, 5),
        extraData: {
          'revenue': 1250000.0,
          'profit': 450000.0,
          'bestSeller': 'Iced Aren Latte',
        },
      ),
      // 3. User Natural Language Purchase Recording
      AiChatMessage(
        id: 'msg-003',
        sender: ChatSender.user,
        text: 'Saya baru saja beli 10kg gula pasir dengan harga total 170rb',
        type: AiMessageType.text,
        timestamp: DateTime(now.year, now.month, now.day, 14, 22),
      ),
      // 4. AI Detected Action Confirmation Card (Confirmed)
      AiChatMessage(
        id: 'msg-004',
        sender: ChatSender.ai,
        text: 'Pembelian berhasil dideteksi dan dicocokkan dengan inventaris:',
        type: AiMessageType.actionConfirm,
        timestamp: DateTime(now.year, now.month, now.day, 14, 22, 4),
        actionPayload: AiActionPayload(
          actionId: 'act-001',
          intent: 'ADD_STOCK_AND_EXPENSE',
          itemName: 'Sugar',
          quantity: 10,
          unit: 'kg',
          expenseAmount: 170000,
          category: 'Bahan Baku',
          status: AiActionStatus.confirmed,
        ),
      ),
    ]);
  }

  /// Send user message and trigger automated AI intelligence.
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

    // Simulate AI thinking and processing
    await Future.delayed(const Duration(milliseconds: 900));

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

  /// Confirm and execute an action (mutates Stock and Finance repositories!).
  void confirmAction(String actionId) {
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

    // 4. Default / Business Overview Query
    final finRepo = FinanceRepository.instance;
    final income = finRepo.getTotalIncome(FinancePeriod.today);
    final expense = finRepo.getTotalExpense(FinancePeriod.today);
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
        'bestSeller': 'Iced Aren Latte',
      },
    );
  }

  /// Clear chat messages.
  void clearChat() {
    _messages.clear();
    _seedChat();
    notifyListeners();
  }
}
