import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiga_angkatan/models/profile_model.dart';
import 'package:tiga_angkatan/screens/profile/profile_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Profile Model & Repository Tests', () {
    setUp(() {
      ProfileRepository.instance.resetToDemo();
    });

    test('Initial profile repository has correct default values', () {
      final user = ProfileRepository.instance.user;
      final biz = ProfileRepository.instance.business;
      final prefs = ProfileRepository.instance.preferences;

      expect(user.name, 'Budi Santoso');
      expect(user.email, 'owner@tigaangkatan.id');
      expect(user.role, contains('Owner'));
      expect(user.isVerified, isTrue);

      expect(biz.name, contains('Kedai Kopi Senja'));
      expect(biz.taxPercentage, 10.0);
      expect(biz.operationalHours, '08:00 - 22:00 WIB');

      expect(prefs.autoPrintReceipt, isTrue);
      expect(prefs.pushNotifications, isTrue);
      expect(prefs.stockAlerts, isTrue);
    });

    test('updateUserProfile updates name and notifies listeners', () async {
      final repo = ProfileRepository.instance;
      bool notified = false;
      repo.userNotifier.addListener(() => notified = true);

      await repo.updateUserProfile(
        name: 'Andika Palian',
        phone: '0811-2233-4455',
      );

      expect(repo.user.name, 'Andika Palian');
      expect(repo.user.phone, '0811-2233-4455');
      expect(notified, isTrue);
    });

    test('updateBusinessProfile updates store info and notifies listeners', () async {
      final repo = ProfileRepository.instance;
      bool notified = false;
      repo.businessNotifier.addListener(() => notified = true);

      await repo.updateBusinessProfile(
        name: 'Kopi Tiga Angkatan Cabang 1',
        category: 'Roastery & Specialty Coffee',
        address: 'Jl. Riau No. 45, Bandung',
        phone: '0819-8765-4321',
        operationalHours: '07:00 - 23:00 WIB',
        taxPercentage: 11.0,
      );

      expect(repo.business.name, 'Kopi Tiga Angkatan Cabang 1');
      expect(repo.business.category, 'Roastery & Specialty Coffee');
      expect(repo.business.address, 'Jl. Riau No. 45, Bandung');
      expect(repo.business.operationalHours, '07:00 - 23:00 WIB');
      expect(repo.business.taxPercentage, 11.0);
      expect(notified, isTrue);
    });

    test('updatePreferences toggles switch preferences correctly', () {
      final repo = ProfileRepository.instance;
      repo.updatePreferences(
        autoPrintReceipt: false,
        biometricLogin: true,
      );

      expect(repo.preferences.autoPrintReceipt, isFalse);
      expect(repo.preferences.biometricLogin, isTrue);
      expect(repo.preferences.pushNotifications, isTrue);
    });
  });

  group('Profile Screen UI Widget Tests', () {
    setUp(() {
      ProfileRepository.instance.resetToDemo();
    });

    testWidgets('ProfileScreen renders App Bar, Hero Card, and Sections',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ProfileScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Check App Bar
      expect(find.text('Profil & Pengaturan'), findsOneWidget);

      // Check User name and Store name
      expect(find.text('Budi Santoso'), findsWidgets);
      expect(find.textContaining('Kedai Kopi Senja'), findsWidgets);

      // Check Section Headers
      expect(find.text('Profil Pemilik Akun'), findsOneWidget);
      expect(find.text('Identitas Bisnis & Gerai'), findsOneWidget);
      expect(find.text('Pengaturan POS & Perangkat'), findsOneWidget);
      expect(find.text('Koneksi Backend Server'), findsOneWidget);
      expect(find.text('Bantuan & Informasi'), findsOneWidget);

      // Check Logout Button
      expect(find.text('Keluar dari Akun'), findsOneWidget);
    });

    testWidgets('Tap Edit Profil opens Edit User Profile Bottom Sheet',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ProfileScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Find and tap "Edit Profil" button in Hero Card
      final editBtn = find.text('Edit Profil');
      expect(editBtn, findsOneWidget);
      await tester.tap(editBtn);
      await tester.pumpAndSettle();

      // Verify bottom sheet title and submit button
      expect(find.text('Edit Data Akun Pemilik'), findsOneWidget);
      expect(find.text('Simpan Perubahan'), findsOneWidget);
    });

    testWidgets('Tap Kelola Toko opens Edit Business Profile Bottom Sheet',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ProfileScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Find and tap "Kelola Toko" button in Hero Card
      final storeBtn = find.text('Kelola Toko');
      expect(storeBtn, findsOneWidget);
      await tester.tap(storeBtn);
      await tester.pumpAndSettle();

      // Verify bottom sheet title and fields
      expect(find.text('Edit Profil Bisnis & Toko'), findsOneWidget);
      expect(find.text('Nama Bisnis / Toko'), findsOneWidget);
      expect(find.text('Simpan Perubahan Bisnis'), findsOneWidget);
    });

    testWidgets('Tap Keluar dari Akun opens Logout Confirmation Bottom Sheet',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ProfileScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Find logout button and scroll to it if needed
      final logoutBtn = find.text('Keluar dari Akun');
      expect(logoutBtn, findsOneWidget);
      await tester.ensureVisible(logoutBtn);
      await tester.pumpAndSettle();

      await tester.tap(logoutBtn);
      await tester.pumpAndSettle();

      // Verify logout confirmation dialog / sheet
      expect(find.text('Konfirmasi Keluar Akun'), findsOneWidget);
      expect(find.text('Ya, Keluar'), findsOneWidget);
      expect(find.text('Batal'), findsOneWidget);
    });
  });
}
