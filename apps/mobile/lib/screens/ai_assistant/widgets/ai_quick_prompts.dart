import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: prompts.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final item = prompts[index];
          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => onSelectPrompt(item.promptQuery),
              borderRadius: BorderRadius.circular(19),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(19),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      item.icon,
                      size: 13,
                      color: const Color(0xFF111111),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      item.label,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

