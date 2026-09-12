import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:AISISTENKU/screens/auth/login_screen.dart';

void main() {
  group('Auth Screen UI Widget Tests', () {
    testWidgets('LoginScreen renders header, logo, switcher, fields, and buttons',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LoginScreen(),
        ),
      );

      // Verify Header & Logo
      expect(find.text('AISISTENKU — Sistem Manajemen Toko & POS'), findsOneWidget);
      expect(find.text('Selamat Datang'), findsOneWidget);
      expect(find.byType(Image), findsOneWidget);

      // Verify Tab Switcher & Button
      expect(find.text('Masuk'), findsOneWidget); // Tab switcher
      expect(find.text('Masuk ke Akun'), findsOneWidget); // Submit button
      expect(find.text('Daftar Baru'), findsOneWidget);

      // Verify Input Fields
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);

      // Verify Buttons
      expect(find.text('Coba Demo Akun Cafe (Data Contoh)'), findsOneWidget);

      // Switch to Register Tab
      await tester.tap(find.text('Daftar Baru'));
      await tester.pumpAndSettle();

      expect(find.text('Daftar Akun Baru'), findsOneWidget);
      expect(find.text('Nama Lengkap / Toko'), findsOneWidget);
      expect(find.text('Nama Bisnis / Toko'), findsOneWidget);
      expect(find.text('Alamat Toko / Bisnis'), findsOneWidget);
      expect(find.text('Daftar Sekarang'), findsOneWidget);
    });
  });
}
