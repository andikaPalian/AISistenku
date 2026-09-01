import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/finance_model.dart';
import 'transaction_detail_modal.dart';

/// Section showing recent transactions with All/Income/Expense filter pills
/// matching the reference UI mockup.
class RecentTransactionsSection extends StatefulWidget {
  final List<FinanceTransaction> transactions;
  final VoidCallback? onViewAllTap;
  final Function(FinanceTransaction)? onTransactionTap;

  const RecentTransactionsSection({
    super.key,
    required this.transactions,
    this.onViewAllTap,
    this.onTransactionTap,
  });

  @override
  State<RecentTransactionsSection> createState() =>
      _RecentTransactionsSectionState();
}

class _RecentTransactionsSectionState
    extends State<RecentTransactionsSection> {
  TransactionType? _typeFilter; // null = All, income = Income, expense = Expense

  @override
  Widget build(BuildContext context) {
    final displayedTransactions = widget.transactions.where((tx) {
      if (_typeFilter == null) return true;
      return tx.type == _typeFilter;
    }).take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Section Header & Filter Pills ───────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent\nTransactions',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.darkText,
                height: 1.15,
              ),
            ),
            Row(
              children: [
                _buildFilterPill('All', null),
                const SizedBox(width: 6),
                _buildFilterPill('Income', TransactionType.income),
                const SizedBox(width: 6),
                _buildFilterPill('Expense', TransactionType.expense),
              ],
            ),
          ],
        ),

        const SizedBox(height: 14),

        // ── Transactions Container ──────────────────────────────────
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFFCCFBF1).withOpacity(0.8),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              if (displayedTransactions.isEmpty) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.receipt_long_outlined,
                          size: 40,
                          color: AppColors.mutedText.withOpacity(0.5),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Belum ada transaksi di periode ini',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppColors.mutedText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ] else ...[
                ...displayedTransactions.asMap().entries.map((entry) {
                  final index = entry.key;
                  final tx = entry.value;
                  final isLast = index == displayedTransactions.length - 1;

                  return Column(
                    children: [
                      _buildTransactionItem(context, tx),
                      if (!isLast)
                        const Divider(
                          height: 1,
                          thickness: 1,
                          indent: 68,
                          endIndent: 16,
                          color: Color(0xFFF1F5F9),
                        ),
                    ],
                  );
                }),
              ],

              // ── "Lihat Semua Transaksi" Button ─────────────────────
              const Divider(height: 1, color: Color(0xFFE2E8F0)),
              InkWell(
                onTap: widget.onViewAllTap,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(20),
                ),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  alignment: Alignment.center,
                  child: Text(
                    'Lihat Semua Transaksi',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.darkText,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFilterPill(String label, TransactionType? type) {
    final isSelected = _typeFilter == type;
    return GestureDetector(
      onTap: () {
        setState(() {
          _typeFilter = type;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0F766E) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF0F766E) : const Color(0xFFCBD5E1),
            width: 1.1,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.darkText,
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionItem(BuildContext context, FinanceTransaction tx) {
    final isIncome = tx.type == TransactionType.income;

    // Semantic icons matching mockup
    IconData iconData;
    Color iconBg;
    Color iconColor;

    if (isIncome) {
      if (tx.title.toLowerCase().contains('pos')) {
        iconData = Icons.storefront_rounded;
      } else {
        iconData = Icons.point_of_sale_rounded;
      }
      iconBg = const Color(0xFFDCFCE7);
      iconColor = const Color(0xFF15803D);
    } else {
      if (tx.category == FinanceCategory.ingredients) {
        if (tx.title.toLowerCase().contains('sugar') ||
            tx.title.toLowerCase().contains('gula')) {
          iconData = Icons.store_rounded;
          iconBg = const Color(0xFFFFEDD5);
          iconColor = const Color(0xFFEA580C);
        } else {
          iconData = Icons.shopping_cart_outlined;
          iconBg = const Color(0xFFFEE2E2);
          iconColor = const Color(0xFFDC2626);
        }
      } else if (tx.category == FinanceCategory.utility) {
        iconData = Icons.bolt_rounded;
        iconBg = const Color(0xFFFEF3C7);
        iconColor = const Color(0xFFD97706);
      } else {
        iconData = Icons.receipt_long_rounded;
        iconBg = const Color(0xFFE2E8F0);
        iconColor = const Color(0xFF475569);
      }
    }

    return InkWell(
      onTap: () {
        if (widget.onTransactionTap != null) {
          widget.onTransactionTap!(tx);
        } else {
          TransactionDetailModal.show(
            context,
            transaction: tx,
            onDelete: tx.source == TransactionSource.manual
                ? () {
                    FinanceRepository.instance.deleteTransaction(tx.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Transaksi berhasil dihapus'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                : null,
          );
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            // Circular Avatar Icon
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: iconBg,
                shape: BoxShape.circle,
              ),
              child: Icon(
                iconData,
                color: iconColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),

            // Title & Subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tx.title,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.darkText,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    tx.listSubtitle,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 10),

            // Amount (+/-)
            Text(
              tx.formattedAmountWithSign,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isIncome
                    ? const Color(0xFF10B981)
                    : const Color(0xFFEF4444),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
