import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/notification_model.dart';
import '../../../models/profile_model.dart';
import 'notification_sheet.dart';
import '../../profile/profile_screen.dart';

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
  Widget _buildInitialsBadge(String name) {
    final initials = name.trim().split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join('').toUpperCase();
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      child: Text(
        initials.isNotEmpty ? initials : 'B',
        style: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
    );
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
            final effectiveStoreName =
                widget.storeName ?? (business.name.isNotEmpty ? business.name : 'Kedai Kopi Senja');

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Left Side: Avatar + Store & Greeting
                    // Left: User Profile Squircle Button
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ProfileScreen(),
                          ),
                        );
                      },
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: user.avatarUrl != null && user.avatarUrl!.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(11),
                                child: Image.network(
                                  user.avatarUrl!,
                                  width: 34,
                                  height: 34,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => _buildInitialsBadge(user.name),
                                ),
                              )
                            : _buildInitialsBadge(user.name),
                      ),
                    ),

                    // Center: Current location
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Current location',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: const Color(0xFF64748B),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          GestureDetector(
                            onTap: _showStoreSwitcherModal,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.location_on_rounded,
                                  color: Color(0xFF22C55E), // Vibrant Green Pin
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    effectiveStoreName,
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
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
                                  size: 16,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Right Side: Notification Bell Rounded Square
                    const _NotificationBellSquare(),
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





class _NotificationBellSquare extends StatelessWidget {
  const _NotificationBellSquare();

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
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
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
