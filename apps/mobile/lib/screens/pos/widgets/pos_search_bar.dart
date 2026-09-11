import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';

/// Search bar for filtering menu items by name or code.
/// Styled with brand light teal border and clear button.
class PosSearchBar extends StatefulWidget {
  final ValueChanged<String> onChanged;

  const PosSearchBar({super.key, required this.onChanged});

  @override
  State<PosSearchBar> createState() => _PosSearchBarState();
}

class _PosSearchBarState extends State<PosSearchBar> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9), // Clean light slate background
        borderRadius: BorderRadius.circular(12),
        // No hard border, relying on background color for boundary
      ),
      child: TextField(
        controller: _controller,
        onChanged: widget.onChanged,
        style: GoogleFonts.inter(
          fontSize: 13.5,
          color: AppColors.darkText,
        ),
        decoration: InputDecoration(
          hintText: 'Cari menu kopi, makanan, snack...',
          hintStyle: GoogleFonts.inter(
            fontSize: 13,
            color: AppColors.mutedText,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: AppColors.primaryTeal,
            size: 21,
          ),
          suffixIcon: _controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded, size: 18, color: AppColors.mutedText),
                  onPressed: () {
                    _controller.clear();
                    widget.onChanged('');
                    setState(() {});
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 13,
          ),
        ),
      ),
    );
  }
}
