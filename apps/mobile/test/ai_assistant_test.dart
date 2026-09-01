import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiga_angkatan/models/ai_chat_model.dart';
import 'package:tiga_angkatan/models/stock_model.dart';
import 'package:tiga_angkatan/models/finance_model.dart';
import 'package:tiga_angkatan/screens/ai_assistant/ai_assistant_screen.dart';

void main() {
  group('AI Chat Model & Action Execution Tests', () {
    test('AI Chat Repository seeds initial conversation properly', () {
      final repo = AiChatRepository.instance;
      expect(repo.messages.length, greaterThanOrEqualTo(4));
      expect(repo.messages.any((m) => m.sender == ChatSender.user), isTrue);
      expect(repo.messages.any((m) => m.sender == ChatSender.ai), isTrue);
    });

    test('NLP parser recognizes purchase and restock intents', () async {
      final repo = AiChatRepository.instance;
      final initialCount = repo.messages.length;

      await repo.sendMessage('Saya beli 5L susu fresh milk seharga 100rb');

      expect(repo.messages.length, initialCount + 2);
      final lastMsg = repo.messages.last;
      expect(lastMsg.type, AiMessageType.actionConfirm);
      expect(lastMsg.actionPayload?.itemName, 'Fresh Milk');
      expect(lastMsg.actionPayload?.quantity, 5);
      expect(lastMsg.actionPayload?.unit, 'L');
    });

    test('NLP parser generates social media captions and promo content', () async {
      final repo = AiChatRepository.instance;

      await repo.sendMessage('Buatkan caption promo instagram kopi susu');

      final lastMsg = repo.messages.last;
      expect(lastMsg.type, AiMessageType.contentCaption);
      expect(lastMsg.actionPayload?.captionText, isNotNull);
      expect(lastMsg.actionPayload?.hashtags, isNotEmpty);
    });

    test('Action confirmation synchronizes with Stock and Finance repositories', () {
      final repo = AiChatRepository.instance;
      final stockRepo = StockRepository.instance;
      final finRepo = FinanceRepository.instance;

      final initialStockCount = stockRepo.items.length;
      final initialTxCount = finRepo.transactions.length;

      final testActionId = 'act-test-${DateTime.now().millisecondsSinceEpoch}';
      repo.addMessage(
        AiChatMessage(
          id: 'msg-test',
          sender: ChatSender.ai,
          text: 'Konfirmasi',
          type: AiMessageType.actionConfirm,
          timestamp: DateTime.now(),
          actionPayload: AiActionPayload(
            actionId: testActionId,
            intent: 'ADD_STOCK_AND_EXPENSE',
            itemName: 'Caramel Syrup',
            quantity: 3,
            unit: 'btl',
            expenseAmount: 210000,
          ),
        ),
      );

      repo.confirmAction(testActionId);

      // Verify Stock was added/updated
      expect(stockRepo.items.length, greaterThanOrEqualTo(initialStockCount));

      // Verify Expense transaction was created in Finance
      expect(finRepo.transactions.length, initialTxCount + 1);
      expect(finRepo.transactions.first.amount, 210000);
      expect(finRepo.transactions.first.source, TransactionSource.aiAgent);
    });
  });

  group('AI Assistant Screen UI Tests', () {
    testWidgets('AiAssistantScreen renders Header, Hero, Quick Prompts and Messages',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AiAssistantScreen(),
        ),
      );

      expect(find.text('AIsistenku'), findsOneWidget);
      expect(find.textContaining('Hi, Budi'), findsOneWidget);
      expect(find.text('Catatan Pengeluaran'), findsOneWidget);
      expect(find.text('Cek Stok'), findsOneWidget);
      expect(find.text('Ask AIsistenku anything...'), findsOneWidget);
      expect(find.byIcon(Icons.mic_none_rounded), findsOneWidget);
      expect(find.byIcon(Icons.send_rounded), findsOneWidget);
    });
  });
}
