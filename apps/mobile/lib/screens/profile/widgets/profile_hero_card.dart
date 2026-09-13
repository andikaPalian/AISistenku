import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/profile_model.dart';

/// Modern Neo-Clean Profile Hero Identity Card.
///
/// Features:
/// - Obsidian gradient hero card with subtle border and floating elevation.
/// - Dynamic initials or custom avatar with vibrant emerald accent ring.
/// - Clear role & verified store pill tags.
/// - Quick operational highlights bar (branches, hours, PB1 tax).
/// - Dual high-contrast action pill buttons: "Edit Profil" & "Kelola Toko".
class ProfileHeroCard extends StatelessWidget {
  final UserProfile user;
  final BusinessProfile business;
  final VoidCallback onEditProfile;
  final VoidCallback onManageStore;
  final VoidCallback? onChangeAvatar;

  const ProfileHeroCard({
    super.key,
    required this.user,
    required this.business,
    required this.onEditProfile,
    required this.onManageStore,
    this.onChangeAvatar,
  });

  String _getInitials(String name) {
    final clean = name.trim();
    if (clean.isEmpty) return 'AP';
    final parts = clean.split(' ').where((e) => e.isNotEmpty).toList();
    if (parts.isEmpty) return 'AP';
    if (parts.length == 1) {
      return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
    }
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final initials = _getInitials(user.name);
    final hasCustomAvatar = user.avatarUrl != null && user.avatarUrl!.trim().isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF111111),
            Color(0xFF1E293B),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFF334155).withValues(alpha: 0.6),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── 1. Avatar with Emerald Ring & Camera Badge ──────────
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                width: 82,
                height: 82,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF22C55E),
                    width: 2.8,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF22C55E).withValues(alpha: 0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: hasCustomAvatar
                      ? Image.network(
                          user.avatarUrl!,
                          width: 82,
                          height: 82,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _buildFallbackAvatar(initials),
                        )
                      : _buildFallbackAvatar(initials),
                ),
              ),

              // Camera Action Button
              GestureDetector(
                onTap: onChangeAvatar ?? onEditProfile,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF111111),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF22C55E),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.camera_alt_rounded,
                    size: 14,
                    color: Color(0xFF22C55E),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // ── 2. Name & Verified Badge ────────────────────────────
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  user.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              const Icon(
                Icons.verified_rounded,
                color: Color(0xFF22C55E),
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 6),

          // ── 3. Role & Store Badges ──────────────────────────────
          Wrap(
            spacing: 8,
            runSpacing: 6,
            alignment: WrapAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF22C55E).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF22C55E).withValues(alpha: 0.35),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.shield_rounded,
                      color: Color(0xFF4ADE80),
                      size: 13,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      user.role,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF4ADE80),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.16),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.storefront_rounded,
                      color: Colors.white70,
                      size: 13,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      business.name,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // ── 4. Quick Highlights Bar (Branches, Hours, PB1) ──────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildHighlightItem(
                  icon: Icons.store_mall_directory_rounded,
                  label: '${business.branchCount} Gerai',
                ),
                Container(
                  width: 1,
                  height: 16,
                  color: Colors.white.withValues(alpha: 0.15),
                ),
                _buildHighlightItem(
                  icon: Icons.access_time_filled_rounded,
                  label: business.operationalHours.contains('WIB')
                      ? business.operationalHours.replaceAll(' WIB', '')
                      : business.operationalHours,
                ),
                Container(
                  width: 1,
                  height: 16,
                  color: Colors.white.withValues(alpha: 0.15),
                ),
                _buildHighlightItem(
                  icon: Icons.receipt_long_rounded,
                  label: 'PB1 ${business.taxPercentage.toStringAsFixed(0)}%',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── 5. Action Buttons: Edit Profil & Kelola Toko ─────────
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF22C55E),
                      foregroundColor: const Color(0xFF0F172A),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    icon: const Icon(
                      Icons.edit_rounded,
                      size: 15,
                      color: Color(0xFF0F172A),
                    ),
                    label: Text(
                      'Edit Profil',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    onPressed: onEditProfile,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.10),
                      side: BorderSide(
                        color: Colors.white.withValues(alpha: 0.22),
                        width: 1.2,
                      ),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    icon: const Icon(
                      Icons.storefront_rounded,
                      size: 15,
                      color: Colors.white,
                    ),
                    label: Text(
                      'Kelola Toko',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: Colors.white,
                      ),
                    ),
                    onPressed: onManageStore,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHighlightItem({
    required IconData icon,
    required String label,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: const Color(0xFF22C55E)),
        const SizedBox(width: 5),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.white.withValues(alpha: 0.85),
          ),
        ),
      ],
    );
  }

  Widget _buildFallbackAvatar(String initials) {
    return Container(
      width: 82,
      height: 82,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF22C55E),
            Color(0xFF16A34A),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          initials,
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 26,
            letterSpacing: 1.0,
          ),
        ),
      ),
    );
  }
}
