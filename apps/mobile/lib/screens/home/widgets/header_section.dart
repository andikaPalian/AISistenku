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
                // ── 1. Top App Bar Row ──────────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Store Switcher (Left)
                    GestureDetector(
                      onTap: _showStoreSwitcherModal,
                      behavior: HitTestBehavior.opaque,
                      child: Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E293B),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.08),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Image.asset(
                                'assets/icons/logoAisitenku.png',
                                width: 24,
                                height: 24,
                                errorBuilder: (_, __, ___) => const Icon(
                                  Icons.local_cafe_rounded,
                                  color: AppColors.mintAccent,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    effectiveStoreName,
                                    style: GoogleFonts.poppins(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.darkText,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(
                                    Icons.arrow_drop_down_rounded,
                                    color: AppColors.darkText,
                                    size: 20,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 1),
                              Text(
                                effectiveRole,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: AppColors.mutedText,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Top Right Actions (Notification + Avatar)
                    Row(
                      children: [
                        const _NotificationBell(),
                        const SizedBox(width: 10),
                        GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const ProfileScreen(),
                              ),
                            );
                          },
                          child: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.border, width: 1.5),
                            ),
                            child: ClipOval(
                              child: Image.network(
                                user.avatarUrl ??
                                    'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150&auto=format&fit=crop&q=80',
                                width: 38,
                                height: 38,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  width: 38,
                                  height: 38,
                                  color: AppColors.primaryTeal,
                                  child: Center(
                                    child: Text(
                                      effectiveUserName.isNotEmpty
                                          ? effectiveUserName[0].toUpperCase()
                                          : 'B',
                                      style: GoogleFonts.inter(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // ── 2. Greeting & Status Row ──────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      '${_getGreeting()}, $effectiveUserName 👋',
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppColors.darkText,
                        letterSpacing: -0.3,
                      ),
                    ),

                    // Live status badge
                    Container(

              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: _isStoreOpen ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _isStoreOpen ? const Color(0xFFBBF7D0) : const Color(0xFFFECACA),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: _isStoreOpen ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _isStoreOpen ? 'Toko Buka' : 'Tutup',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _isStoreOpen ? const Color(0xFF15803D) : const Color(0xFF991B1B),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 4),

        // ── 3. Date & Operational Hours Subtitle ───────────────────────
        Row(
          children: [
            Text(
              _getFormattedDate(),
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.mutedText,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 4,
              height: 4,
              decoration: const BoxDecoration(
                color: AppColors.mutedForeground,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.access_time_rounded,
              size: 14,
              color: AppColors.mutedText,
            ),
            const SizedBox(width: 4),
            Text(
              '08:00 - 22:00 WIB',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.mutedText,
                fontWeight: FontWeight.w500,
              ),
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
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.tealBackgrounds,
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.lightTealBorder,
                width: 1,
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                const Icon(
                  Icons.notifications_outlined,
                  color: AppColors.darkText,
                  size: 20,
                ),
                if (unreadCount > 0)
                  Positioned(
                    right: 7,
                    top: 7,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEA580C),
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
