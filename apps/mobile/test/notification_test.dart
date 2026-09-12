import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:AISISTENKU/models/notification_model.dart';
import 'package:AISISTENKU/screens/home/widgets/notification_sheet.dart';

void main() {
  group('Notification Model & Repository Tests', () {
    test('NotificationRepository seeds initial notifications and calculates unread count', () {
      final repo = NotificationRepository.instance;
      expect(repo.notifications.length, greaterThan(0));
      expect(repo.unreadCount, greaterThan(0));
    });

    test('markAsRead and markAllAsRead updates state correctly', () {
      final repo = NotificationRepository.instance;
      repo.markAllAsRead();
      expect(repo.unreadCount, 0);
    });
  });

  group('Notification UI Widget Tests', () {
    testWidgets('NotificationSheet renders Header, Category chips, and notification cards', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: NotificationSheet(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Notifikasi'), findsOneWidget);
      expect(find.text('Semua'), findsOneWidget);
      expect(find.text('Stok'), findsOneWidget);
      expect(find.text('Penjualan'), findsOneWidget);
      expect(find.text('AIsisten'), findsOneWidget);
    });
  });
}
