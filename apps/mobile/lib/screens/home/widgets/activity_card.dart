import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';

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
    const topItems = [
      TopMenuItem(
        rank: 1,
        name: 'Kopi Susu Aren',
        salesDescription: '42 cup • Terlaris',
        totalRevenueFormatted: 'Rp756.000',
        unitPriceFormatted: '@ Rp18.000',
        imageUrl:
            'https://images.unsplash.com/photo-1517701550927-30cf4ba1dba5?w=200&auto=format&fit=crop&q=80',
        isTopPerformer: true,
      ),
      TopMenuItem(
        rank: 2,
        name: 'Iced Cafe Latte',
        salesDescription: '24 cup • Kategori Kopi',
        totalRevenueFormatted: 'Rp480.000',
        unitPriceFormatted: '@ Rp20.000',
        imageUrl:
            'https://images.unsplash.com/photo-1572442388796-11668a67e53d?w=200&auto=format&fit=crop&q=80',
      ),
      TopMenuItem(
        rank: 3,
        name: 'Croissant Butter',
        salesDescription: '15 pcs • Pastry',
        totalRevenueFormatted: 'Rp225.000',
        unitPriceFormatted: '@ Rp15.000',
        imageUrl:
            'https://images.unsplash.com/photo-1555507036-ab1f4038808a?w=200&auto=format&fit=crop&q=80',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Section Header ───────────────────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.local_fire_department_rounded,
                  color: Color(0xFF0F172A),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Menu Terlaris Hari Ini',
                  style: GoogleFonts.poppins(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.darkText,
                  ),
                ),
              ],
            ),
            Text(
              'Top 3 item',
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
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.lightTealBorder, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
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
                    color: AppColors.lightTealBorder,
                  ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 20),

        // ── Sync Status Pill Banner ──────────────────────────────────
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border, width: 1),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.sync_rounded,
                    size: 18,
                    color: Color(0xFF64748B),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Sinkronisasi Kasir Cabang 1 & 2 Aktif',
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      color: AppColors.darkText,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              Text(
                'Realtime',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF16A34A),
                ),
              ),
            ],
          ),
        ),
      ],
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
