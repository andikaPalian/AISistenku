import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/notification_model.dart';
import '../../../models/profile_model.dart';
import '../../profile/profile_screen.dart';
import 'notification_sheet.dart';

/// Top header section matching the reference design:
/// 1. Top Bar: Store switcher ("Kedai Kopi Senja ▾", "Owner • 2 Cabang"), Notification bell, and User Avatar.
/// 2. Greeting Row: "Selamat Pagi, Budi 👋" with live status pill "🟢 Toko Buka".
/// 3. Subtitle: Indonesian formatted date and operational hours.
class HeaderSection extends StatefulWidget {
  final String? storeName;
  final String? roleSubtitle;
  final String? userName;

  const HeaderSection({
    super.key,
    this.storeName,
    this.roleSubtitle,
    this.userName,
  });

  @override
  State<HeaderSection> createState() => _HeaderSectionState();
}

class _HeaderSectionState extends State<HeaderSection> {
  final bool _isStoreOpen = true;

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 11) return 'Selamat Pagi';
    if (hour < 15) return 'Selamat Siang';
    if (hour < 18) return 'Selamat Sore';
    return 'Selamat Malam';
  }

  String _getFormattedDate() {
    const days = [
      'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'
    ];
    const months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    final now = DateTime.now();
    final dayName = days[now.weekday - 1];
    final monthName = months[now.month - 1];
    return '$dayName, ${now.day} $monthName ${now.year}';
  }

  void _showStoreSwitcherModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Pilih Cabang Bisnis',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.darkText,
                  ),
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                      color: AppColors.forestTeal,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.storefront_rounded, color: Colors.white, size: 20),
                  ),
                  title: Text(
                    'Kedai Kopi Senja (Pusat)',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  subtitle: Text('Jl. Melati No. 12, Bandung', style: GoogleFonts.inter(fontSize: 12)),
                  trailing: const Icon(Icons.check_circle_rounded, color: AppColors.primaryTeal),
                  onTap: () => Navigator.pop(context),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.neutralSubCard,
                      border: Border.all(color: AppColors.border),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.storefront_outlined, color: AppColors.mutedText, size: 20),
                  ),
                  title: Text(
                    'Kedai Kopi Senja (Cabang Dago)',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 14),
                  ),
                  subtitle: Text('Jl. Ir. H. Juanda No. 88, Bandung', style: GoogleFonts.inter(fontSize: 12)),
                  onTap: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<UserProfile>(
      valueListenable: ProfileRepository.instance.userNotifier,
      builder: (context, user, _) {
        return ValueListenableBuilder<BusinessProfile>(
          valueListenable: ProfileRepository.instance.businessNotifier,
          builder: (context, business, _) {
            final effectiveUserName = widget.userName ??
                (user.name.isNotEmpty ? user.name.split(' ').first : 'Budi');
            final effectiveStoreName =
                widget.storeName ?? (business.name.isNotEmpty ? business.name : 'Kedai Kopi Senja');
            final effectiveRole = widget.roleSubtitle ??
                '${user.role.split(' ').first} • ${business.branchCount} Cabang';

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Left Side: Avatar + Store & Greeting
                    Expanded(
                      child: Row(
                        children: [
                          // Avatar
                          GestureDetector(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => const ProfileScreen(),
                                ),
                              );
                            },
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
                              ),
                              child: ClipOval(
                                child: Image.network(
                                  user.avatarUrl ??
                                      'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150&auto=format&fit=crop&q=80',
                                  width: 44,
                                  height: 44,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    width: 44,
                                    height: 44,
                                    color: AppColors.primaryTeal,
                                    child: Center(
                                      child: Text(
                                        effectiveUserName.isNotEmpty
                                            ? effectiveUserName[0].toUpperCase()
                                            : 'B',
                                        style: GoogleFonts.inter(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          
                          // Store Name & Greeting
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                GestureDetector(
                                  onTap: _showStoreSwitcherModal,
                                  behavior: HitTestBehavior.opaque,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Flexible(
                                        child: Text(
                                          effectiveStoreName,
                                          style: GoogleFonts.poppins(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                            color: const Color(0xFF0F172A),
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 2),
                                      const Icon(
                                        Icons.keyboard_arrow_down_rounded,
                                        color: Color(0xFF0F172A),
                                        size: 20,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${_getGreeting()}, $effectiveUserName 👋',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: const Color(0xFF64748B),
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Right Side: Notification Bell
                    const Padding(
                      padding: EdgeInsets.only(left: 12),
                      child: _NotificationBell(),
                    ),
                  ],
                ),
              ],
    );
  },
);
},
);
}
}





class _NotificationBell extends StatelessWidget {
  const _NotificationBell();

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: NotificationRepository.instance,
      builder: (context, _) {
        final unreadCount = NotificationRepository.instance.unreadCount;

        return GestureDetector(
          onTap: () => NotificationSheet.show(context),
          behavior: HitTestBehavior.opaque,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
              border: Border.all(color: const Color(0xFFF1F5F9), width: 1),
            ),
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                const Icon(
                  Icons.notifications_none_rounded,
                  color: Color(0xFF0F172A),
                  size: 24,
                ),
                if (unreadCount > 0)
                  Positioned(
                    right: 10,
                    top: 10,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444), // Standard bright red
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
