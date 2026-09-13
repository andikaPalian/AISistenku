import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/widgets/action_success_modal.dart';
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
  String _activeFilter = 'all'; // 'all', 'income', 'expense', 'refund'

  @override
  Widget build(BuildContext context) {
    final displayedTransactions = widget.transactions.where((tx) {
      if (_activeFilter == 'all') return true;
      if (_activeFilter == 'income') return tx.type == TransactionType.income;
      if (_activeFilter == 'expense') {
        return tx.type == TransactionType.expense &&
            tx.category != FinanceCategory.refund;
      }
      if (_activeFilter == 'refund') return tx.category == FinanceCategory.refund;
      return true;
    }).take(6).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Section Header & View All Action ───────────────────────────
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
            if (widget.onViewAllTap != null)
              GestureDetector(
                onTap: widget.onViewAllTap,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Lihat Semua',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0D9488),
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 11,
                        color: Color(0xFF0D9488),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),

        const SizedBox(height: 12),

        // ── Filter Pills in Dedicated Row ───────────────────────────
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              _buildFilterPill('Semua', 'all'),
              const SizedBox(width: 6),
              _buildFilterPill('Pemasukan', 'income'),
              const SizedBox(width: 6),
              _buildFilterPill('Pengeluaran', 'expense'),
              const SizedBox(width: 6),
              _buildFilterPill('Refund', 'refund'),
            ],
          ),
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
                          indent: 70,
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

  Widget _buildFilterPill(String label, String key) {
    final isSelected = _activeFilter == key;
    return GestureDetector(
      onTap: () {
        setState(() {
          _activeFilter = key;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
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
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            color: isSelected ? Colors.white : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionItem(BuildContext context, FinanceTransaction tx) {
    final isIncome = tx.type == TransactionType.income;
    final isRefund = tx.category == FinanceCategory.refund;

    final isAlreadyRefunded = tx.isRefundedOrder ||
        FinanceRepository.instance.isOrderAlreadyRefunded(
          orderId: tx.orderId,
          orderCode: tx.orderCode,
          title: tx.title,
          notes: tx.notes,
        );

    // Semantic icons matching Neo-Clean mockup
    IconData iconData;
    Color iconBg;
    Color iconColor;
    Color iconBorder;

    if (isRefund) {
      iconData = Icons.assignment_return_rounded;
      iconBg = const Color(0xFFFFF1F2);
      iconColor = const Color(0xFFE11D48);
      iconBorder = const Color(0xFFFECDD3);
    } else if (isIncome) {
      iconData = Icons.storefront_rounded;
      iconBg = isAlreadyRefunded ? const Color(0xFFF8FAFC) : const Color(0xFFECFDF5);
      iconColor = isAlreadyRefunded ? const Color(0xFF64748B) : const Color(0xFF059669);
      iconBorder = isAlreadyRefunded ? const Color(0xFFE2E8F0) : const Color(0xFFA7F3D0);
    } else {
      if (tx.category == FinanceCategory.ingredients) {
        iconData = Icons.inventory_2_outlined;
        iconBg = const Color(0xFFFFFBEB);
        iconColor = const Color(0xFFD97706);
        iconBorder = const Color(0xFFFDE68A);
      } else if (tx.category == FinanceCategory.utility) {
        iconData = Icons.bolt_rounded;
        iconBg = const Color(0xFFFEF3C7);
        iconColor = const Color(0xFFEA580C);
        iconBorder = const Color(0xFFFDE047);
      } else if (tx.category == FinanceCategory.salary) {
        iconData = Icons.badge_outlined;
        iconBg = const Color(0xFFF5F3FF);
        iconColor = const Color(0xFF7C3AED);
        iconBorder = const Color(0xFFDDD6FE);
      } else {
        iconData = Icons.receipt_long_rounded;
        iconBg = const Color(0xFFF8FAFC);
        iconColor = const Color(0xFF475569);
        iconBorder = const Color(0xFFE2E8F0);
      }
    }

    // 1. Order Code Resolution
    final ordRegex = RegExp(r'ORD-\d{8}-\d{3}|ORD-\d+');
    final matchInTitle = ordRegex.firstMatch(tx.title);
    final matchInNotes = tx.notes != null ? ordRegex.firstMatch(tx.notes!) : null;
    final rawOrderCode = tx.orderCode ?? matchInTitle?.group(0) ?? matchInNotes?.group(0);

    String? displayOrderCode;
    if (rawOrderCode != null) {
      displayOrderCode = '#$rawOrderCode';
    } else if (tx.orderId != null && tx.orderId!.isNotEmpty) {
      final clean = tx.orderId!.replaceAll('#', '');
      displayOrderCode = '#${clean.length > 10 ? clean.substring(0, 8).toUpperCase() : clean.toUpperCase()}';
    }

    // 2. Title and Context Parsing
    String mainTitle = tx.title;
    String? orderTag;

    if (tx.notes != null && tx.notes!.isNotEmpty) {
      final cleanNotes = tx.notes!.replaceAll(RegExp(r'Meja\s+Meja', caseSensitive: false), 'Meja');
      final lowerNotes = cleanNotes.toLowerCase();
      final tableMatch = RegExp(r'meja\s*(\w+)', caseSensitive: false).firstMatch(cleanNotes);

      if (lowerNotes.contains('takeaway') || lowerNotes.contains('take away')) {
        orderTag = 'Take Away';
      } else if (tableMatch != null) {
        orderTag = 'Dine In • Meja ${tableMatch.group(1)}';
      } else if (lowerNotes.contains('dinein') || lowerNotes.contains('dine in')) {
        orderTag = 'Dine In';
      }
    }

    if (isRefund) {
      mainTitle = 'Refund Pesanan';
    } else if (mainTitle.startsWith('Penjualan Kasir ORD-') || mainTitle.startsWith('Penjualan Kasir')) {
      mainTitle = 'Penjualan Kasir POS';
    }

    // 3. Subtitle Formatting
    String subtitle;
    if (isRefund) {
      final reasonMatch = RegExp(r'Alasan:\s*([^\)]+)', caseSensitive: false).firstMatch(tx.notes ?? '');
      final reason = reasonMatch != null ? reasonMatch.group(1)?.trim() : null;
      if (reason != null && reason.isNotEmpty) {
        subtitle = '$reason • ${tx.formattedDateString}';
      } else {
        subtitle = 'Jurnal Balik • ${tx.formattedDateString}';
      }
    } else if (orderTag != null) {
      subtitle = '$orderTag • ${tx.formattedDateString}';
    } else {
      subtitle = tx.listSubtitle;
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
                    ActionSuccessModal.show(
                      context,
                      title: 'Transaksi Berhasil Dihapus',
                      subtitle: 'Catatan transaksi telah dihapus dari pembukuan kas outlet.',
                      itemName: tx.title,
                      itemCategory: 'Catatan Keuangan',
                      quantityChange: tx.formattedAmount,
                      financialImpact: 'Pembukuan Kas Diperbarui',
                      statusBadge: 'Dihapus',
                      itemIcon: Icons.delete_outline_rounded,
                      heroIcon: Icons.delete_forever_rounded,
                      heroColor: const Color(0xFFEF4444),
                      heroHaloColor: const Color(0xFFFEE2E2),
                    );
                  }
                : null,
          );
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Circular Avatar Icon
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(13),
                border: Border.all(color: iconBorder, width: 1.0),
              ),
              child: Icon(
                iconData,
                color: iconColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),

            // Title & Subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          mainTitle,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: isAlreadyRefunded && !isRefund
                                ? const Color(0xFF64748B)
                                : const Color(0xFF0F172A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (displayOrderCode != null) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFE2E8F0), width: 0.8),
                          ),
                          child: Text(
                            displayOrderCode,
                            style: GoogleFonts.inter(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF334155),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          subtitle,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF64748B),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isAlreadyRefunded && !isRefund) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF1F2),
                            borderRadius: BorderRadius.circular(5),
                            border: Border.all(color: const Color(0xFFFECDD3), width: 0.8),
                          ),
                          child: Text(
                            'Di-refund',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFFE11D48),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 10),

            // Amount (+/-)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  tx.formattedAmountWithSign,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: isRefund
                        ? const Color(0xFFE11D48)
                        : (isIncome
                            ? (isAlreadyRefunded
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF16A34A))
                            : const Color(0xFFDC2626)),
                    decoration: (isAlreadyRefunded && !isRefund)
                        ? TextDecoration.lineThrough
                        : null,
                  ),
                ),
                if (isAlreadyRefunded && !isRefund) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Dibatalkan',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFE11D48),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
