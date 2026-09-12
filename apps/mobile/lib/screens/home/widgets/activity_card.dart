import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/finance_model.dart';
import '../../../models/product.dart';

/// Represents a ranked best-selling product item.
class TopMenuItem {
  final int rank;
  final String name;
  final String salesDescription;
  final String totalRevenueFormatted;
  final String imageUrl;
  final bool isTopPerformer;

  const TopMenuItem({
    required this.rank,
    required this.name,
    required this.salesDescription,
    required this.totalRevenueFormatted,
    required this.imageUrl,
    this.isTopPerformer = false,
  });
}

/// "Menu Terlaris" section matching modern retail POS standards:
/// - Ranked items with rank badge (Gold #1, Silver #2, Bronze #3)
/// - Authentic product images and units (cup for drinks, pcs for bakery)
/// - Sales count and total revenue generated
class ActivityCard extends StatelessWidget {
  const ActivityCard({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        FinanceRepository.instance,
        ProductRepository.instance,
      ]),
      builder: (context, _) {
        final topProductsData = FinanceRepository.instance.getTopProducts();
        final allProducts = ProductRepository.instance.products;

        final topItems = topProductsData.asMap().entries.map((entry) {
          final idx = entry.key;
          final prod = entry.value;

          final matchedProduct = allProducts
              .where((p) => p.name.toLowerCase().trim() == prod.name.toLowerCase().trim())
              .firstOrNull;

          final unit = matchedProduct?.unit ??
              (prod.name.toLowerCase().contains('croissant') ||
                      prod.name.toLowerCase().contains('muffin') ||
                      prod.name.toLowerCase().contains('pie')
                  ? 'pcs'
                  : 'cup');

          final imageUrl = matchedProduct?.imageUrl ??
              (prod.name.toLowerCase().contains('croissant')
                  ? 'https://images.unsplash.com/photo-1555507036-ab1f4038808a?w=400&auto=format&fit=crop&q=80'
                  : prod.name.toLowerCase().contains('matcha')
                      ? 'https://images.unsplash.com/photo-1536256263959-770b48d82b0a?w=400&auto=format&fit=crop&q=80'
                      : 'https://images.unsplash.com/photo-1517701550927-30cf4ba1dba5?w=400&auto=format&fit=crop&q=80');

          return TopMenuItem(
            rank: idx + 1,
            name: prod.name,
            salesDescription: '${prod.soldQuantity} $unit',
            totalRevenueFormatted: FinanceRepository.formatRupiah(prod.totalRevenue),
            imageUrl: imageUrl,
            isTopPerformer: idx == 0,
          );
        }).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Section Header ───────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Menu Terlaris',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                Text(
                  'Top 3 Produk',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    color: const Color(0xFF64748B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // ── Top Products Card List ───────────────────────────────────
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                children: [
                  for (int i = 0; i < topItems.length; i++) ...[
                    _buildMenuItemRow(topItems[i]),
                    if (i < topItems.length - 1)
                      const Divider(
                        height: 18,
                        thickness: 1,
                        color: Color(0xFFF1F5F9),
                      ),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMenuItemRow(TopMenuItem item) {
    Color rankBadgeBg;
    Color rankBadgeText;

    if (item.rank == 1) {
      rankBadgeBg = const Color(0xFFF59E0B); // Gold
      rankBadgeText = Colors.white;
    } else if (item.rank == 2) {
      rankBadgeBg = const Color(0xFF94A3B8); // Silver
      rankBadgeText = Colors.white;
    } else {
      rankBadgeBg = const Color(0xFFE2E8F0); // Bronze / Slate
      rankBadgeText = const Color(0xFF475569);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          // Rank Badge + Thumbnail with overlay
          Stack(
            clipBehavior: Clip.none,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  item.imageUrl,
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.restaurant_rounded,
                      color: Color(0xFF94A3B8),
                      size: 22,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: -5,
                left: -5,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: rankBadgeBg,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      '${item.rank}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: rankBadgeText,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(width: 14),

          // Title & Description
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      item.salesDescription,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: const Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (item.isTopPerformer) ...[
                      const SizedBox(width: 6),
                      Container(
                        width: 4,
                        height: 4,
                        decoration: const BoxDecoration(
                          color: Color(0xFF16A34A),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Terlaris',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5,
                          color: const Color(0xFF16A34A),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // Total Revenue
          Text(
            item.totalRevenueFormatted,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }
}
