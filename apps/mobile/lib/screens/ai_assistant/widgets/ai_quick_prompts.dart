import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';

class QuickPromptItem {
  final String iconEmoji;
  final String label;
  final String promptQuery;

  const QuickPromptItem({
    required this.iconEmoji,
    required this.label,
    required this.promptQuery,
  });
}

/// Horizontal scrollable chips for fast one-tap AI prompt generation.
class AiQuickPrompts extends StatelessWidget {
  final ValueChanged<String> onSelectPrompt;

  const AiQuickPrompts({
    super.key,
    required this.onSelectPrompt,
  });

  static const List<QuickPromptItem> prompts = [
    QuickPromptItem(
      iconEmoji: '🧾',
      label: 'Catatan Pengeluaran',
      promptQuery:
          'Saya baru saja beli 10kg gula pasir dengan harga total 170rb',
    ),
    QuickPromptItem(
      iconEmoji: '📦',
      label: 'Cek Stok',
      promptQuery: 'Cek stok bahan baku apa yang perlu di-restock sekarang?',
    ),
    QuickPromptItem(
      iconEmoji: '💰',
      label: 'Analisis Omzet',
      promptQuery: 'Bagaimana performa penjualan dan laba saya hari ini?',
    ),
    QuickPromptItem(
      iconEmoji: '📸',
      label: 'Buat Caption Sosmed',
      promptQuery:
          'Buatkan caption Instagram menarik untuk promo Kopi Susu Gula Aren sore ini',
    ),
    QuickPromptItem(
      iconEmoji: '💡',
      label: 'Ide Promo Bisnis',
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
            child: GestureDetector(
              onTap: () => onSelectPrompt(item.promptQuery),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: const Color(0xFFE2E8F0),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      item.iconEmoji,
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(width: 6),
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
          );
        }).toList(),
      ),
    );
  }
}
