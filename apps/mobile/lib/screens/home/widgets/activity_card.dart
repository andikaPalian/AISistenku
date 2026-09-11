import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/finance_model.dart';

/// Represents a ranked best-selling product item.
class TopMenuItem {
  final int rank;
  final String name;
  final String salesDescription;
  final String totalRevenueFormatted;
  final String unitPriceFormatted;
  final String imageUrl;
  final bool isTopPerformer;

  const TopMenuItem({
    required this.rank,
    required this.name,
    required this.salesDescription,
    required this.totalRevenueFormatted,
    required this.unitPriceFormatted,
    required this.imageUrl,
    this.isTopPerformer = false,
  });
}

/// "Menu Terlaris Hari Ini" section matching the reference UI:
/// - Header with flame icon + "Top 3 item"
/// - Ranked items with rank badge, product image, sales count, and revenue
/// - Bottom sync status banner ("Sinkronisasi Kasir Cabang 1 & 2 Aktif • Realtime")
class ActivityCard extends StatelessWidget {
  const ActivityCard({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: FinanceRepository.instance,
      builder: (context, _) {
        final topProductsData = FinanceRepository.instance.getTopProducts();
        final topItems = topProductsData.asMap().entries.map((entry) {
          final idx = entry.key;
          final prod = entry.value;
          return TopMenuItem(
            rank: idx + 1,
            name: prod.name,
            salesDescription: '${prod.soldQuantity} cup',
            totalRevenueFormatted: FinanceRepository.formatRupiah(prod.totalRevenue),
            unitPriceFormatted: '', // Alternatively compute unit price if available
            imageUrl: 'https://images.unsplash.com/photo-1517701550927-30cf4ba1dba5?w=200&auto=format&fit=crop&q=80',
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
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.darkText,
              ),
            ),
            Text(
              'Top 3',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.mutedText,
                fontWeight: FontWeight.w500,
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
                    height: 20,
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
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: AppColors.neutralSubCard,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.coffee_rounded,
                      color: AppColors.primaryTeal,
                      size: 24,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: -6,
                left: -6,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: item.rank == 1
                        ? const Color(0xFFB45309) // Warm bronze gold for #1
                        : const Color(0xFFF1F5F9), // Subtle slate for #2 and #3
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      '${item.rank}',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: item.rank == 1 ? Colors.white : AppColors.darkText,
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
                  style: GoogleFonts.poppins(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.darkText,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    if (item.isTopPerformer) ...[
                      Text(
                        '42 cup',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.mutedText,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        width: 3,
                        height: 3,
                        decoration: const BoxDecoration(
                          color: Color(0xFF16A34A),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Terlaris',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFF16A34A),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ] else
                      Text(
                        item.salesDescription,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.mutedText,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),

          // Revenue & Unit Price
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                item.totalRevenueFormatted,
                style: GoogleFonts.poppins(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.darkText,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                item.unitPriceFormatted,
                style: GoogleFonts.inter(
                  fontSize: 11.5,
                  color: AppColors.mutedText,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
