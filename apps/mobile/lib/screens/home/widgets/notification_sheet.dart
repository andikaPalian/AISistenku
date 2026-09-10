import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/notification_model.dart';

/// Interactive Notification Center Bottom Sheet Modal.
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
            maxHeight: MediaQuery.of(context).size.height * 0.78,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Handle Bar ──────────────────────────────────────────
              const SizedBox(height: 12),
              Center(
                child: Container(
                  width: 44,
                  height: 4.5,
                  decoration: BoxDecoration(
                    color: AppColors.lightTealBorder,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),


              // ── Header Bar ──────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Notifikasi',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.darkText,
                          ),
                        ),
                        if (repo.unreadCount > 0) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primaryTeal,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              ' Baru',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (repo.unreadCount > 0)
                      InkWell(
                        onTap: () => repo.markAllAsRead(),
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 4,
                          ),
                          child: Text(
                            'Tandai dibaca',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryTeal,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // ── Category Filters ────────────────────────────────────
              SizedBox(
                height: 38,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  physics: const BouncingScrollPhysics(),
                  itemCount: _filters.length,
                  itemBuilder: (context, index) {
                    final isSelected = _selectedFilterIndex == index;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(_filters[index]),
                        selected: isSelected,
                        onSelected: (val) {
                          if (val) setState(() => _selectedFilterIndex = index);
                        },
                        labelStyle: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          color: isSelected ? Colors.white : AppColors.darkText,
                        ),
                        backgroundColor: AppColors.surface,
                        selectedColor: AppColors.primaryTeal,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: isSelected ? AppColors.primaryTeal : AppColors.border,
                          ),
                        ),
                        showCheckmark: false,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 8),
              const Divider(height: 1, color: Color(0xFFF1F5F9)),

              // ── Notifications List ──────────────────────────────────
              Flexible(
                child: filteredNotifs.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(40),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.notifications_off_outlined,
                              size: 44,
                              color: AppColors.mutedText,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Belum ada notifikasi',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.darkText,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Pemberitahuan stok dan operasional akan muncul di sini.',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AppColors.mutedText,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
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

  Widget _buildNotificationCard(AppNotification notif, NotificationRepository repo) {
    return GestureDetector(
      onTap: () => repo.markAsRead(notif.id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: notif.isRead ? Colors.white : notif.type.bgColor.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: notif.isRead
                ? AppColors.lightTealBorder
                : notif.type.color.withValues(alpha: 0.35),
            width: notif.isRead ? 1 : 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: notif.type.bgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                notif.type.icon,
                size: 20,
                color: notif.type.color,
              ),
            ),
            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          notif.title,
                          style: GoogleFonts.poppins(
                            fontSize: 13.5,
                            fontWeight: notif.isRead ? FontWeight.w600 : FontWeight.w700,
                            color: AppColors.darkText,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        notif.timeAgo,
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: AppColors.mutedText,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notif.message,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: const Color(0xFF475569),
                      height: 1.4,
                    ),
                  ),
                  if (notif.actionLabel != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: notif.type.color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        notif.actionLabel!,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: notif.type.color,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Unread Dot
            if (!notif.isRead) ...[
              const SizedBox(width: 8),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: notif.type.color,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
