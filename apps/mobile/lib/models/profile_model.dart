import 'package:flutter/foundation.dart';
import '../core/services/api_service.dart';

/// Represents the authenticated user profile.
class UserProfile {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String role;
  final String? avatarUrl;
  final String joinedAt;
  final bool isVerified;

  const UserProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    this.avatarUrl,
    required this.joinedAt,
    this.isVerified = true,
  });

  UserProfile copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? role,
    String? avatarUrl,
    String? joinedAt,
    bool? isVerified,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      joinedAt: joinedAt ?? this.joinedAt,
      isVerified: isVerified ?? this.isVerified,
    );
  }

  /// First word of user's full name (e.g. "Andika" from "Andika Palian", "Budi" from "Budi Santoso")
  String get firstName {
    final clean = name.trim();
    if (clean.isEmpty) return 'Rekan';
    return clean.split(' ').first;
  }

  factory UserProfile.defaultOwner() {
    return const UserProfile(
      id: 'usr-owner-001',
      name: 'Budi Santoso',
      email: 'owner@tigaangkatan.id',
      phone: '0812-3456-7890',
      role: 'Owner Bisnis (Pusat)',
      joinedAt: 'Januari 2024',
      isVerified: true,
    );
  }
}

/// Represents the business/store identity and operational profile.
class BusinessProfile {
  final String id;
  final String name;
  final String category;
  final String address;
  final String phone;
  final String operationalHours;
  final int branchCount;
  final double taxPercentage;
  final String receiptFooter;

  const BusinessProfile({
    required this.id,
    required this.name,
    required this.category,
    required this.address,
    required this.phone,
    required this.operationalHours,
    this.branchCount = 2,
    this.taxPercentage = 10.0,
    this.receiptFooter = 'Terima kasih atas kunjungan Anda!',
  });

  BusinessProfile copyWith({
    String? id,
    String? name,
    String? category,
    String? address,
    String? phone,
    String? operationalHours,
    int? branchCount,
    double? taxPercentage,
    String? receiptFooter,
  }) {
    return BusinessProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      operationalHours: operationalHours ?? this.operationalHours,
      branchCount: branchCount ?? this.branchCount,
      taxPercentage: taxPercentage ?? this.taxPercentage,
      receiptFooter: receiptFooter ?? this.receiptFooter,
    );
  }

  factory BusinessProfile.defaultStore() {
    return const BusinessProfile(
      id: '',
      name: 'Kedai Kopi Senja (Pusat)',
      category: 'Coffee Shop & Cafe',
      address: 'Jl. Melati No. 12, Bandung, Jawa Barat',
      phone: '0821-9876-5432',
      operationalHours: '08:00 - 22:00 WIB',
      branchCount: 2,
      taxPercentage: 10.0,
      receiptFooter: 'Terima kasih atas kunjungan Anda! Selamat menikmati kopi kami.',
    );
  }
}

/// Hardware and application preferences.
class AppPreferences {
  final bool printerConnected;
  final String printerDeviceName;
  final bool autoPrintReceipt;
  final bool pushNotifications;
  final bool stockAlerts;
  final bool biometricLogin;

  const AppPreferences({
    this.printerConnected = true,
    this.printerDeviceName = 'Thermal RPP02N (Bluetooth)',
    this.autoPrintReceipt = true,
    this.pushNotifications = true,
    this.stockAlerts = true,
    this.biometricLogin = false,
  });

  AppPreferences copyWith({
    bool? printerConnected,
    String? printerDeviceName,
    bool? autoPrintReceipt,
    bool? pushNotifications,
    bool? stockAlerts,
    bool? biometricLogin,
  }) {
    return AppPreferences(
      printerConnected: printerConnected ?? this.printerConnected,
      printerDeviceName: printerDeviceName ?? this.printerDeviceName,
      autoPrintReceipt: autoPrintReceipt ?? this.autoPrintReceipt,
      pushNotifications: pushNotifications ?? this.pushNotifications,
      stockAlerts: stockAlerts ?? this.stockAlerts,
      biometricLogin: biometricLogin ?? this.biometricLogin,
    );
  }
}

/// Central repository managing user account, store settings, and preferences.
class ProfileRepository {
  static final ProfileRepository instance = ProfileRepository._internal();
  ProfileRepository._internal();

  UserProfile _user = UserProfile.defaultOwner();
  BusinessProfile _business = BusinessProfile.defaultStore();
  AppPreferences _preferences = const AppPreferences();

  final ValueNotifier<UserProfile> userNotifier =
      ValueNotifier<UserProfile>(UserProfile.defaultOwner());
  final ValueNotifier<BusinessProfile> businessNotifier =
      ValueNotifier<BusinessProfile>(BusinessProfile.defaultStore());
  final ValueNotifier<AppPreferences> preferencesNotifier =
      ValueNotifier<AppPreferences>(const AppPreferences());

  UserProfile get user => _user;
  BusinessProfile get business => _business;
  AppPreferences get preferences => _preferences;

  /// Fetch user profile and business details from backend
  Future<void> fetchProfileFromBackend() async {
    try {
      final res = await ApiService.instance.get('/auth/me');
      if (res != null && res is Map) {
        final data = res['data'] ?? res;
        if (data is Map) {
          final id = (data['id'] ?? _user.id).toString();
          final name = (data['name'] ?? _user.name).toString();
          final email = (data['email'] ?? _user.email).toString();
          final avatarUrl = data['avatarUrl']?.toString();

          _user = _user.copyWith(
            id: id,
            name: name,
            email: email,
            avatarUrl: avatarUrl,
          );
          userNotifier.value = _user;

          // Parse membership / business if present
          final memberships = data['memberships'];
          if (memberships is List && memberships.isNotEmpty) {
            final first = memberships.first;
            if (first is Map) {
              final role = first['role']?.toString();
              if (role != null && role.isNotEmpty) {
                _user = _user.copyWith(
                  role: role == 'OWNER' ? 'Owner Bisnis (Pusat)' : 'Kasir / Staff',
                );
                userNotifier.value = _user;
              }

              final biz = first['business'];
              if (biz is Map) {
                final bizId = (biz['id'] ?? _business.id).toString();
                final bizName = (biz['name'] ?? _business.name).toString();
                final bizAddress = (biz['address'] ?? _business.address).toString();
                final bizPhone = (biz['phone'] ?? _business.phone).toString();

                _business = _business.copyWith(
                  id: bizId,
                  name: bizName,
                  address: bizAddress,
                  phone: bizPhone,
                );
                businessNotifier.value = _business;
                ApiService.instance.setBusinessId(bizId);
              }
            }
          }
        }
      }
    } catch (e) {
      debugPrint('⚠️ ProfileRepository.fetchProfileFromBackend error: $e');
    }
  }

  /// Update user account profile
  Future<bool> updateUserProfile({
    required String name,
    String? phone,
    String? avatarUrl,
  }) async {
    _user = _user.copyWith(
      name: name.trim(),
      phone: phone?.trim(),
      avatarUrl: avatarUrl,
    );
    userNotifier.value = _user;

    try {
      final body = <String, dynamic>{
        'name': name.trim(),
      };
      if (avatarUrl != null) {
        body['avatarUrl'] = avatarUrl;
      }
      await ApiService.instance.patch('/auth/me', body);
      return true;
    } catch (e) {
      debugPrint('⚠️ Backend update profile failed (using local state): $e');
      return false;
    }
  }

  /// Upload avatar image to Cloudinary via backend and persist URL.
  /// Returns the secure URL on success, null on failure.
  Future<String?> uploadAvatar(Uint8List bytes, {String? filename}) async {
    try {
      final name = (filename != null && filename.isNotEmpty)
          ? filename
          : 'avatar_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final res = await ApiService.instance.uploadMultipart(
        '/upload/avatar',
        bytes: bytes,
        filename: name,
        fieldName: 'avatar',
      );

      final url = res?['data']?['url']?.toString();
      if (url != null && url.isNotEmpty) {
        _user = _user.copyWith(avatarUrl: url);
        userNotifier.value = _user;
        return url;
      }
      return null;
    } catch (e) {
      debugPrint('⚠️ ProfileRepository.uploadAvatar error: $e');
      return null;
    }
  }

  /// Update business / store profile
  Future<bool> updateBusinessProfile({
    required String name,
    String? category,
    String? address,
    String? phone,
    String? operationalHours,
    double? taxPercentage,
    String? receiptFooter,
  }) async {
    _business = _business.copyWith(
      name: name.trim(),
      category: category?.trim(),
      address: address?.trim(),
      phone: phone?.trim(),
      operationalHours: operationalHours?.trim(),
      taxPercentage: taxPercentage,
      receiptFooter: receiptFooter?.trim(),
    );
    businessNotifier.value = _business;

    try {
      if (_business.id.isNotEmpty) {
        await ApiService.instance.patch('/businesses/${_business.id}', {
          'name': name.trim(),
          if (address != null) 'address': address.trim(),
          if (phone != null) 'phone': phone.trim(),
        });
      }
      return true;
    } catch (e) {
      debugPrint('⚠️ Backend update business failed (using local state): $e');
      return false;
    }
  }

  /// Update hardware and app preferences
  void updatePreferences({
    bool? printerConnected,
    String? printerDeviceName,
    bool? autoPrintReceipt,
    bool? pushNotifications,
    bool? stockAlerts,
    bool? biometricLogin,
  }) {
    _preferences = _preferences.copyWith(
      printerConnected: printerConnected,
      printerDeviceName: printerDeviceName,
      autoPrintReceipt: autoPrintReceipt,
      pushNotifications: pushNotifications,
      stockAlerts: stockAlerts,
      biometricLogin: biometricLogin,
    );
    preferencesNotifier.value = _preferences;
  }

  /// Reset to clean state (for logout or test)
  void resetToDemo() {
    _user = UserProfile.defaultOwner();
    _business = BusinessProfile.defaultStore();
    _preferences = const AppPreferences();
    userNotifier.value = _user;
    businessNotifier.value = _business;
    preferencesNotifier.value = _preferences;
    ApiService.instance.setBusinessId(null);
  }
}
