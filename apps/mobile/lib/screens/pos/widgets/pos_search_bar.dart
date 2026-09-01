import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';

/// Search bar for filtering menu items by name.
class PosSearchBar extends StatelessWidget {
  final ValueChanged<String> onChanged;

  const PosSearchBar({super.key, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: TextField(
        onChanged: onChanged,
        style: GoogleFonts.inter(
          fontSize: 14,
          color: AppColors.darkText,
        ),
        decoration: InputDecoration(
          hintText: 'Search menu...',
          hintStyle: GoogleFonts.inter(
            fontSize: 14,
            color: AppColors.mutedText,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: AppColors.mutedText,
            size: 22,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }
}
