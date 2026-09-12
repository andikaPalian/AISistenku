import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:AISISTENKU/screens/splash_screen.dart';

void main() {
  group('Splash Screen UI Widget Tests', () {
    testWidgets('SplashScreen renders authentic logo, title, and feature badge',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SplashScreen(),
        ),
      );

      // Verify Initial Rendering
      expect(find.text('AISISTENKU'), findsOneWidget);
      expect(find.text('Sistem POS & Manajemen Toko Pintar'), findsOneWidget);
      expect(find.text('Asisten Bisnis Cerdas UMKM'), findsOneWidget);
      expect(find.text('Tiga Angkatan • Ekosistem Terpadu'), findsOneWidget);
      expect(find.byType(Image), findsOneWidget);

      // Pump through animation
      await tester.pump(const Duration(milliseconds: 1000));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Complete navigation timer to avoid pending timers
      await tester.pump(const Duration(milliseconds: 3000));
    });
  });
}
