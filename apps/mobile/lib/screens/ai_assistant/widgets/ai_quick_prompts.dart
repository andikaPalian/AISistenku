import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';

class QuickPromptItem {
  final IconData icon;
  final String label;
  final String promptQuery;

  const QuickPromptItem({
    required this.icon,
    required this.label,
    required this.promptQuery,
  });
}

/// Horizontal scrollable chips for fast one-tap AI prompt generation without emoji slop.
class AiQuickPrompts extends StatelessWidget {
  final ValueChanged<String> onSelectPrompt;

  const AiQuickPrompts({
    super.key,
    required this.onSelectPrompt,
  });

  static const List<QuickPromptItem> prompts = [
    QuickPromptItem(
      icon: Icons.receipt_long_rounded,
      label: 'Catat Belanja Bahan',
      promptQuery:
          'Saya baru saja beli 10kg gula pasir dengan harga total 170rb',
    ),
    QuickPromptItem(
      icon: Icons.inventory_2_outlined,
      label: 'Cek Stok Menipis',
      promptQuery: 'Cek stok bahan baku apa yang perlu di-restock sekarang?',
    ),
    QuickPromptItem(
      icon: Icons.trending_up_rounded,
      label: 'Analisis Omzet',
      promptQuery: 'Bagaimana performa penjualan dan laba saya hari ini?',
    ),
    QuickPromptItem(
      icon: Icons.campaign_outlined,
      label: 'Buat Caption Promo',
      promptQuery:
          'Buatkan caption Instagram menarik untuk promo Kopi Susu Gula Aren sore ini',
    ),
    QuickPromptItem(
      icon: Icons.lightbulb_outline_rounded,
      label: 'Ide Promo Bundling',
      promptQuery:
          'Berikan rekomendasi ide promo bundling hemat untuk mendongkrak penjualan',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: prompts.map((item) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => onSelectPrompt(item.promptQuery),
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: AppColors.lightTealBorder,
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryTeal.withValues(alpha: 0.04),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.tealBackgrounds,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          item.icon,
                          size: 13,
                          color: AppColors.primaryTeal,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        item.label,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.darkText,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

