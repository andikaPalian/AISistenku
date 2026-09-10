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
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.lightTealBorder, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
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
