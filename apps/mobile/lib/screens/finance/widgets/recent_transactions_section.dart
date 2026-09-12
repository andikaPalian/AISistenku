import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/finance_model.dart';
import 'transaction_detail_modal.dart';

/// Section showing recent transactions with All/Income/Expense filter pills
/// matching Neo-Clean design system.
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
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Transaksi Terbaru',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F172A),
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Aktivitas finansial mutakhir',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                _buildFilterPill('Semua', null),
                const SizedBox(width: 5),
                _buildFilterPill('Masuk', TransactionType.income),
                const SizedBox(width: 5),
                _buildFilterPill('Keluar', TransactionType.expense),
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
              color: const Color(0xFFE2E8F0),
              width: 1.2,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x060F172A),
                blurRadius: 14,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              if (displayedTransactions.isEmpty) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 36),
                  child: Center(
                    child: Column(
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: const BoxDecoration(
                            color: Color(0xFFF1F5F9),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.receipt_long_outlined,
                            size: 24,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Belum ada transaksi di periode ini',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF64748B),
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
              const Divider(height: 1, color: Color(0xFFF1F5F9)),
              InkWell(
                onTap: widget.onViewAllTap,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(20),
                ),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Lihat Semua Transaksi',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(width: 5),
                      const Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 11,
                        color: Color(0xFF0F172A),
                      ),
                    ],
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
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF111111) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF111111) : const Color(0xFFE2E8F0),
            width: 1.0,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            color: isSelected ? Colors.white : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionItem(BuildContext context, FinanceTransaction tx) {
    final isIncome = tx.type == TransactionType.income;

    // Semantic icons matching Neo-Clean mockup
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
      iconColor = const Color(0xFF16A34A);
    } else {
      if (tx.category == FinanceCategory.ingredients) {
        if (tx.title.toLowerCase().contains('sugar') ||
            tx.title.toLowerCase().contains('gula')) {
          iconData = Icons.inventory_2_outlined;
          iconBg = const Color(0xFFFFEDD5);
          iconColor = const Color(0xFFEA580C);
        } else {
          iconData = Icons.shopping_bag_outlined;
          iconBg = const Color(0xFFFEE2E2);
          iconColor = const Color(0xFFDC2626);
        }
      } else if (tx.category == FinanceCategory.utility) {
        iconData = Icons.bolt_rounded;
        iconBg = const Color(0xFFFEF3C7);
        iconColor = const Color(0xFFD97706);
      } else {
        iconData = Icons.receipt_long_rounded;
        iconBg = const Color(0xFFF1F5F9);
        iconColor = const Color(0xFF0F172A);
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: [
            // Circular Avatar Icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                iconData,
                color: iconColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 13),

            // Title & Subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tx.title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0F172A),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    tx.listSubtitle,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
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
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: isIncome
                    ? const Color(0xFF16A34A)
                    : const Color(0xFFDC2626),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
