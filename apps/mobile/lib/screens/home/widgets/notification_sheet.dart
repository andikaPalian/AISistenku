import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/notification_model.dart';

/// Modern Neo-Clean Notification Center Bottom Sheet Modal.
///
/// Features:
/// - Curved Obsidian & Crisp White surface with subtle slate handle bar.
/// - Unread counter badge ('X Baru') in high-contrast Obsidian pill.
/// - Action buttons: 'Tandai dibaca' & 'Bersihkan Semua'.
/// - High-contrast horizontal pill filter bar ('Semua', 'Stok', 'Penjualan', 'AIsisten').
/// - Polished cards with unread accent dots, non-truncated titles (maxLines: 2),
///   relative timestamps (e.g. '15 mnt lalu'), and interactive action buttons.
/// - Swipe-to-dismiss (Dismissible) capability with intuitive delete cues.
class NotificationSheet extends StatefulWidget {
  const NotificationSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const NotificationSheet(),
    );
  }

  @override
  State<NotificationSheet> createState() => _NotificationSheetState();
}

class _NotificationSheetState extends State<NotificationSheet> {
  int _selectedFilterIndex = 0; // 0=Semua, 1=Stok, 2=Penjualan, 3=AIsisten
  static const _filters = ['Semua', 'Stok', 'Penjualan', 'AIsisten'];

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: NotificationRepository.instance,
      builder: (context, _) {
        final repo = NotificationRepository.instance;
        final allNotifs = repo.notifications;

        final filteredNotifs = allNotifs.where((n) {
          if (_selectedFilterIndex == 1) return n.type == NotificationType.stockAlert;
          if (_selectedFilterIndex == 2) return n.type == NotificationType.salesMilestone;
          if (_selectedFilterIndex == 3) return n.type == NotificationType.aiInsight;
          return true;
        }).toList();

        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.82,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── 1. Slate Drag Handle ──────────────────────────────
              const SizedBox(height: 12),
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // ── 2. Header Bar ─────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Notifikasi',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF0F172A),
                            letterSpacing: -0.3,
                          ),
                        ),
                        if (repo.unreadCount > 0) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF111111),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${repo.unreadCount} Baru',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    Row(
                      children: [
                        if (repo.unreadCount > 0)
                          InkWell(
                            onTap: () => repo.markAllAsRead(),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.done_all_rounded,
                                    size: 14,
                                    color: Color(0xFF0F172A),
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    'Tandai dibaca',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF0F172A),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        if (allNotifs.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline_rounded,
                              size: 19,
                              color: Color(0xFF94A3B8),
                            ),
                            tooltip: 'Bersihkan Semua',
                            onPressed: () => _confirmClearAll(context, repo),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 32,
                              minHeight: 32,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // ── 3. Category Filter Chips ──────────────────────────
              SizedBox(
                height: 38,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  physics: const BouncingScrollPhysics(),
                  itemCount: _filters.length,
                  itemBuilder: (context, index) {
                    final isSelected = _selectedFilterIndex == index;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedFilterIndex = index),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFF111111) : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? const Color(0xFF111111) : const Color(0xFFE2E8F0),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            _filters[index],
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12.5,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                              color: isSelected ? Colors.white : const Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 12),
              const Divider(height: 1, color: Color(0xFFF1F5F9)),

              // ── 4. Notifications List / Empty State ───────────────
              Flexible(
                child: filteredNotifs.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                shape: BoxShape.circle,
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: const Icon(
                                Icons.notifications_none_rounded,
                                size: 30,
                                color: Color(0xFF94A3B8),
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              'Belum Ada Notifikasi',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Pemberitahuan stok kritis, target omzet, dan rekomendasi AI akan muncul di sini.',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12.5,
                                color: const Color(0xFF64748B),
                                height: 1.4,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
                        physics: const BouncingScrollPhysics(),
                        itemCount: filteredNotifs.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final notif = filteredNotifs[index];
                          return _buildNotificationCard(notif, repo);
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _confirmClearAll(BuildContext context, NotificationRepository repo) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Bersihkan Notifikasi?',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w800,
            fontSize: 17,
            color: const Color(0xFF0F172A),
          ),
        ),
        content: Text(
          'Semua daftar notifikasi akan dihapus dari riwayat.',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            color: const Color(0xFF64748B),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Batal',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w600,
                color: const Color(0xFF64748B),
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              repo.clearAll();
              Navigator.pop(ctx);
            },
            child: Text(
              'Hapus',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(AppNotification notif, NotificationRepository repo) {
    return Dismissible(
      key: Key(notif.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) {
        repo.deleteNotification(notif.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Notifikasi "${notif.title}" dihapus'),
            duration: const Duration(seconds: 2),
            backgroundColor: const Color(0xFF111111),
          ),
        );
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: const Color(0xFFEF4444),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 6),
            Text(
              'Hapus',
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
      child: GestureDetector(
        onTap: () => repo.markAsRead(notif.id),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: !notif.isRead ? const Color(0xFFCBD5E1) : const Color(0xFFF1F5F9),
              width: !notif.isRead ? 1.4 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: !notif.isRead ? 0.04 : 0.02),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon Avatar
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: notif.type.bgColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: notif.type.color.withValues(alpha: 0.18),
                    width: 1,
                  ),
                ),
                child: Icon(
                  notif.type.icon,
                  size: 20,
                  color: notif.type.color,
                ),
              ),
              const SizedBox(width: 14),

              // Content Column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Row: Category Pill, Time Ago, & Unread Indicator
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: notif.type.bgColor,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            notif.type.label.toUpperCase(),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              color: notif.type.color,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            Text(
                              notif.timeAgo,
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 10.5,
                                color: const Color(0xFF94A3B8),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (!notif.isRead) ...[
                              const SizedBox(width: 6),
                              Container(
                                width: 7,
                                height: 7,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF22C55E),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Title (No truncation, maxLines: 2)
                    Text(
                      notif.title,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13.5,
                        fontWeight: notif.isRead ? FontWeight.w600 : FontWeight.w700,
                        color: notif.isRead ? const Color(0xFF334155) : const Color(0xFF0F172A),
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),

                    // Message Body
                    Text(
                      notif.message,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: const Color(0xFF64748B),
                        height: 1.45,
                      ),
                    ),

                    // Interactive Action Button
                    if (notif.actionLabel != null) ...[
                      const SizedBox(height: 10),
                      InkWell(
                        onTap: () {
                          repo.markAsRead(notif.id);
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Mengarahkan ke: ${notif.actionLabel}'),
                              backgroundColor: const Color(0xFF111111),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF111111),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                notif.actionLabel!,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.arrow_forward_rounded,
                                size: 13,
                                color: Colors.white,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
