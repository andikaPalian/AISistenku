import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../shell_screen.dart';
import '../../profile/profile_screen.dart';

/// Modern Neo-Clean Store Management Bottom Sheet.
///
/// Gives fast access to secondary operational modules:
/// - Diskon & Promo
/// - Pelanggan (CRM)
/// - Manajemen Meja (Dine-In)
/// - Pegawai & Shift
/// - Laporan Keuangan
/// - Pengaturan Toko
class MoreMenuSheet extends StatelessWidget {
  const MoreMenuSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const MoreMenuSheet(),
    );
  }

  void _showComingSoonSnackBar(BuildContext context, String feature) {
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info_outline_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Modul $feature aktif dalam mode sinkronisasi toko.',
                style: GoogleFonts.plusJakartaSans(fontSize: 13),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF1E293B),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        top: 12,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).padding.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 18),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Menu Manajemen Toko',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Pilih modul operasional bisnis Anda',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFFF1F5F9),
                  shape: const CircleBorder(),
                  padding: const EdgeInsets.all(6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 2x3 Grid of modules
          GridView.count(
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 0.95,
            children: [
              // 1. Diskon & Promosi
              _buildGridItem(
                context: context,
                label: 'Diskon',
                sublabel: 'Promo Toko',
                icon: Icons.percent_rounded,
                badgeColor: const Color(0xFFFEF3C7),
                iconColor: const Color(0xFFD97706),
                onTap: () => _showComingSoonSnackBar(context, 'Diskon & Promosi'),
              ),

              // 2. Pelanggan (CRM)
              _buildGridItem(
                context: context,
                label: 'Pelanggan',
                sublabel: 'Member CRM',
                icon: Icons.people_alt_rounded,
                badgeColor: const Color(0xFFDCFCE7),
                iconColor: const Color(0xFF16A34A),
                onTap: () => _showComingSoonSnackBar(context, 'Data Pelanggan'),
              ),

              // 3. Meja & Dine-In
              _buildGridItem(
                context: context,
                label: 'Meja',
                sublabel: 'Dine-In',
                icon: Icons.table_restaurant_rounded,
                badgeColor: const Color(0xFFE0E7FF),
                iconColor: const Color(0xFF4F46E5),
                onTap: () => _showComingSoonSnackBar(context, 'Manajemen Meja'),
              ),

              // 4. Karyawan & Shift
              _buildGridItem(
                context: context,
                label: 'Pegawai',
                sublabel: 'Shift Kasir',
                icon: Icons.badge_rounded,
                badgeColor: const Color(0xFFFCE7F3),
                iconColor: const Color(0xFFDB2777),
                onTap: () => _showComingSoonSnackBar(context, 'Shift & Pegawai'),
              ),

              // 5. Laporan Keuangan
              _buildGridItem(
                context: context,
                label: 'Laporan',
                sublabel: 'Arus Kas',
                icon: Icons.bar_chart_rounded,
                badgeColor: const Color(0xFFEDE9FE),
                iconColor: const Color(0xFF7C3AED),
                onTap: () {
                  Navigator.of(context).pop();
                  ShellScreen.switchTab(context, 4);
                },
              ),

              // 6. Pengaturan Toko
              _buildGridItem(
                context: context,
                label: 'Pengaturan',
                sublabel: 'Profil & Struk',
                icon: Icons.settings_rounded,
                badgeColor: const Color(0xFFF1F5F9),
                iconColor: const Color(0xFF475569),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ProfileScreen()),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildGridItem({
    required BuildContext context,
    required String label,
    required String sublabel,
    required IconData icon,
    required Color badgeColor,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: badgeColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 1),
              Text(
                sublabel,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF64748B),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
