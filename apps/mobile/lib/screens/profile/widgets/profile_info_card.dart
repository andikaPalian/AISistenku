import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Clean card container with crisp borders and soft elevation.
class ProfileCard extends StatelessWidget {
  final List<Widget> children;
  final EdgeInsetsGeometry? padding;

  const ProfileCard({
    super.key,
    required this.children,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

/// Section header with an emerald squircle icon box.
class ProfileSectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;

  const ProfileSectionHeader({
    super.key,
    required this.title,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: const Color(0xFFF0FDF4),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: const Color(0xFFBBF7D0),
              width: 1,
            ),
          ),
          child: Icon(
            icon,
            size: 16,
            color: const Color(0xFF16A34A),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0F172A),
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }
}

/// Subtle divider for info tiles.
class ProfileDivider extends StatelessWidget {
  const ProfileDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return const Divider(
      height: 1,
      thickness: 1,
      color: Color(0xFFF1F5F9),
    );
  }
}

/// Modern info tile with squircle icon, clear label, bold value, and interactive actions.
class ProfileInfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Widget? subtitleWidget;
  final Widget? trailing;
  final String? trailingChipText;
  final Color? trailingChipColor;
  final Color? trailingChipBg;
  final VoidCallback? onTap;

  const ProfileInfoTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.subtitleWidget,
    this.trailing,
    this.trailingChipText,
    this.trailingChipColor,
    this.trailingChipBg,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              // Icon Squircle
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(
                    color: const Color(0xFFE2E8F0),
                    width: 1,
                  ),
                ),
                child: Icon(
                  icon,
                  size: 18,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(width: 14),

              // Texts
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    if (subtitleWidget != null) ...[
                      const SizedBox(height: 4),
                      subtitleWidget!,
                    ],
                  ],
                ),
              ),

              // Trailing action
              if (trailingChipText != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: trailingChipBg ?? const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (trailingChipText == 'Terverifikasi') ...[
                        const Icon(
                          Icons.check_circle_rounded,
                          size: 12,
                          color: Color(0xFF16A34A),
                        ),
                        const SizedBox(width: 4),
                      ],
                      Text(
                        trailingChipText!,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: trailingChipColor ?? const Color(0xFF16A34A),
                        ),
                      ),
                    ],
                  ),
                )
              else if (trailing != null)
                trailing!
              else if (onTap != null)
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: const Icon(
                    Icons.edit_rounded,
                    size: 14,
                    color: Color(0xFF0F172A),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Switch tile for hardware & application preferences.
class ProfileSwitchTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const ProfileSwitchTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(11),
              border: Border.all(
                color: const Color(0xFFE2E8F0),
                width: 1,
              ),
            ),
            child: Icon(
              icon,
              size: 18,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Switch.adaptive(
            value: value,
            activeThumbColor: const Color(0xFF22C55E),
            activeTrackColor: const Color(0xFFDCFCE7),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
