import 'package:flutter/material.dart';

enum NotificationType {
  stockAlert('Stok', Icons.inventory_2_outlined, Color(0xFFE11D48), Color(0xFFFFF1F2)),
  salesMilestone('Penjualan', Icons.trending_up_rounded, Color(0xFF16A34A), Color(0xFFF0FDF4)),
  aiInsight('AIsisten', Icons.auto_awesome_rounded, Color(0xFF0F172A), Color(0xFFF1F5F9)),
  system('Sistem', Icons.info_outline_rounded, Color(0xFF2563EB), Color(0xFFEFF6FF));

  final String label;
  final IconData icon;
  final Color color;
  final Color bgColor;
  const NotificationType(this.label, this.icon, this.color, this.bgColor);
}

class AppNotification {
  final String id;
  final String title;
  final String message;
  final NotificationType type;
  final DateTime timestamp;
  bool isRead;
  final String? actionLabel;

  AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.timestamp,
    this.isRead = false,
    this.actionLabel,
  });

  String get timeAgo {
    final diff = DateTime.now().difference(timestamp);
    if (diff.inMinutes < 1) return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} mnt lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    if (diff.inDays < 7) return '${diff.inDays} hari lalu';
    return '${timestamp.day}/${timestamp.month}';
  }
}

class NotificationRepository extends ChangeNotifier {
  NotificationRepository._() {
    _seedData();
  }

  static final NotificationRepository instance = NotificationRepository._();

  final List<AppNotification> _notifications = [];

  List<AppNotification> get notifications => List.unmodifiable(_notifications);

  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  void _seedData() {
    final now = DateTime.now();
    _notifications.addAll([
      AppNotification(
        id: 'notif-1',
        title: 'Stok Gula Pasir Kritis! 🚨',
        message: 'Tersisa 3 kg (di bawah minimum 5 kg). Segera restock agar operasional kafe tidak terganggu.',
        type: NotificationType.stockAlert,
        timestamp: now.subtract(const Duration(minutes: 15)),
        isRead: false,
        actionLabel: 'Restock Sekarang',
      ),
      AppNotification(
        id: 'notif-2',
        title: 'Target Penjualan Hari Ini Tercapai 🎉',
        message: 'Total omzet telah menembus Rp1.250.000 (+12% dari kemarin). 38 pesanan terselesaikan.',
        type: NotificationType.salesMilestone,
        timestamp: now.subtract(const Duration(hours: 1, minutes: 20)),
        isRead: false,
      ),
      AppNotification(
        id: 'notif-3',
        title: 'Rekomendasi Bundling AIsisten 🤖',
        message: 'Kopi Aren & Croissant Butter sering dipesan bersamaan. Buat promo bundling combo sore untuk menambah nilai transaksi.',
        type: NotificationType.aiInsight,
        timestamp: now.subtract(const Duration(hours: 3)),
        isRead: false,
        actionLabel: 'Lihat Saran',
      ),
      AppNotification(
        id: 'notif-4',
        title: 'Peringatan Stok Fresh Milk 🥛',
        message: 'Stok Susu UHT Full Cream tersisa 5 L mendekati batas minimum 8 L. Waktu pemesanan supplier disarankan sore ini.',
        type: NotificationType.stockAlert,
        timestamp: now.subtract(const Duration(hours: 5)),
        isRead: true,
        actionLabel: 'Cek Stok',
      ),
    ]);
  }

  void markAsRead(String id) {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1 && !_notifications[index].isRead) {
      _notifications[index].isRead = true;
      notifyListeners();
    }
  }

  void markAllAsRead() {
    for (final n in _notifications) {
      n.isRead = true;
    }
    notifyListeners();
  }

  void deleteNotification(String id) {
    _notifications.removeWhere((n) => n.id == id);
    notifyListeners();
  }

  void clearAll() {
    _notifications.clear();
    notifyListeners();
  }

  void addNotification(AppNotification notification) {
    _notifications.insert(0, notification);
    notifyListeners();
  }
}
