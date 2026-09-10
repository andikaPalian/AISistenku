import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/stock_model.dart';
import 'restock_modal.dart';

/// Interactive stock item card matching reference styling with rich UX additions.
class StockCard extends StatelessWidget {
  final StockItem item;
  final VoidCallback onTap;

  const StockCard({
    super.key,
    required this.item,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final status = item.status;

    Color accentColor;
    Color badgeBg;
    Color badgeText;
    String badgeLabel;

    switch (status) {
      case StockStatus.kritis:
        accentColor = AppColors.destructive;
        badgeBg = AppColors.dangerBg;
        badgeText = AppColors.dangerText;
        badgeLabel = 'Kritis';
        break;
      case StockStatus.rendah:
        accentColor = AppColors.warningOrange;
        badgeBg = AppColors.warningBg;
        badgeText = AppColors.warningText;
        badgeLabel = 'Rendah';
        break;
      case StockStatus.baik:
        accentColor = AppColors.successGreen;
        badgeBg = AppColors.successBg;
        badgeText = AppColors.successText;
        badgeLabel = 'Aman';
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.lightTealBorder),
        boxShadow: const [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            splashColor: AppColors.primaryTeal.withValues(alpha: 0.08),
            highlightColor: AppColors.primaryTeal.withValues(alpha: 0.04),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Left status color bar indicator (3px)
                  Container(
                    width: 4,
                    color: accentColor,
                  ),

                  // Main Content
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Top row: Icon, Name + Category, and Current Stock + Badge
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Icon container
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: AppColors.tealBackgrounds,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.lightTealBorder),
                                ),
                                child: Icon(
                                  item.icon,
                                  color: AppColors.primaryTeal,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 12),

                              // Name & Min Stock
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.name,
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.darkText,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Min ${item.formattedMinStock}',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: AppColors.mutedText,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Current Stock Quantity & Status Badge
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    item.formattedCurrentStock,
                                    style: GoogleFonts.poppins(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.darkText,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: badgeBg,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      badgeLabel,
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: badgeText,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),

                          const SizedBox(height: 10),

                          // Mini Progress Gauge & Quick Restock Row
                          Row(
                            children: [
                              // Progress Bar
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: item.healthRatio,
                                    minHeight: 5,
                                    backgroundColor: AppColors.tealBackgrounds,
                                    valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),

                              // Value text
                              Text(
                                item.formattedTotalValue,
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.mutedText,
                                ),
                              ),
                              const SizedBox(width: 8),

                              // Quick restock button
                              InkWell(
                                onTap: () => RestockModal.show(context, initialItem: item),
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppColors.tealBackgrounds,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: AppColors.lightTealBorder),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.add_rounded,
                                        size: 14,
                                        color: AppColors.primaryTeal,
                                      ),
                                      const SizedBox(width: 2),
                                      Text(
                                        'Restock',
                                        style: GoogleFonts.inter(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.primaryTeal,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
