import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/widgets/action_success_modal.dart';
import '../../models/finance_model.dart';
import 'widgets/transaction_detail_modal.dart';
import 'add_transaction_screen.dart';

/// Full transaction history screen with search, category filtering, and export capability in Neo-Clean style.
class AllTransactionsScreen extends StatefulWidget {
  const AllTransactionsScreen({super.key});

  @override
  State<AllTransactionsScreen> createState() => _AllTransactionsScreenState();
}

class _AllTransactionsScreenState extends State<AllTransactionsScreen> {
  String _searchQuery = '';
  String _activeFilter = 'all'; // 'all', 'income', 'expense', 'refund'
  FinanceCategory? _categoryFilter;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: FinanceRepository.instance,
      builder: (context, _) {
        final repo = FinanceRepository.instance;
        final allTx = repo.transactions;

        final filtered = allTx.where((tx) {
          bool matchesType = true;
          if (_activeFilter == 'income') {
            matchesType = tx.type == TransactionType.income;
          } else if (_activeFilter == 'expense') {
            matchesType = tx.type == TransactionType.expense &&
                tx.category != FinanceCategory.refund;
          } else if (_activeFilter == 'refund') {
            matchesType = tx.category == FinanceCategory.refund;
          }

          final matchesCat =
              _categoryFilter == null || tx.category == _categoryFilter;
          final matchesQuery = _searchQuery.isEmpty ||
              tx.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              tx.category.label.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              (tx.notes != null &&
                  tx.notes!.toLowerCase().contains(_searchQuery.toLowerCase()));

          return matchesType && matchesCat && matchesQuery;
        }).toList();

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back_rounded,
                color: Color(0xFF0F172A),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              'Riwayat Transaksi',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0F172A),
                letterSpacing: -0.2,
              ),
            ),
            centerTitle: true,
            bottom: const PreferredSize(
              preferredSize: Size.fromHeight(1),
              child: Divider(
                height: 1,
                thickness: 1,
                color: Color(0xFFE2E8F0),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(
                  Icons.file_download_outlined,
                  color: Color(0xFF0F172A),
                ),
                tooltip: 'Export Laporan',
                onPressed: () {
                  ActionSuccessModal.show(
                    context,
                    title: 'Laporan Keuangan Siap',
                    subtitle: 'Rekap pembukuan arus kas & transaksi siap diunduh dalam format Excel (.xlsx) & PDF.',
                    itemName: 'Laporan Pembukuan Kas',
                    itemCategory: 'Dokumen Keuangan',
                    quantityChange: 'Format XLSX & PDF',
                    financialImpact: 'Periode: Bulan Ini',
                    statusBadge: 'Tersedia',
                    itemIcon: Icons.table_chart_rounded,
                  );
                },
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddTransactionScreen(),
                ),
              );
            },
            backgroundColor: const Color(0xFF111111),
            elevation: 3,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            icon: const Icon(Icons.add_rounded, color: Colors.white),
            label: Text(
              'Tambah Transaksi',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
                color: Colors.white,
                fontSize: 13.5,
              ),
            ),
          ),
          body: SafeArea(
            child: Column(
              children: [
                // ── Search & Filter Controls ─────────────────────────
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                  child: Column(
                    children: [
                      // Search Bar
                      Container(
                        height: 44,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFFE2E8F0),
                            width: 1.0,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.search_rounded,
                              color: Color(0xFF64748B),
                              size: 19,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  color: const Color(0xFF0F172A),
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Cari transaksi, menu, atau catatan...',
                                  hintStyle: GoogleFonts.plusJakartaSans(
                                    fontSize: 13,
                                    color: const Color(0xFF94A3B8),
                                  ),
                                  border: InputBorder.none,
                                  isDense: true,
                                ),
                                onChanged: (val) {
                                  setState(() {
                                    _searchQuery = val;
                                  });
                                },
                              ),
                            ),
                            if (_searchQuery.isNotEmpty)
                              GestureDetector(
                                onTap: () {
                                  _searchController.clear();
                                  setState(() {
                                    _searchQuery = '';
                                  });
                                },
                                child: const Icon(
                                  Icons.close_rounded,
                                  color: Color(0xFF64748B),
                                  size: 18,
                                ),
                              ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Filter Type Pills
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: Row(
                          children: [
                            _buildPill('Semua', 'all'),
                            const SizedBox(width: 6),
                            _buildPill('Pemasukan', 'income'),
                            const SizedBox(width: 6),
                            _buildPill('Pengeluaran', 'expense'),
                            const SizedBox(width: 6),
                            _buildPill('Refund / Retur', 'refund'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const Divider(height: 1, color: Color(0xFFE2E8F0)),

                // ── Transaction List ────────────────────────────────
                Expanded(
                  child: filtered.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.receipt_long_outlined,
                                size: 54,
                                color: Color(0xFFCBD5E1),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Tidak ada transaksi yang cocok',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                          itemCount: filtered.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final tx = filtered[index];
                            final isIncome = tx.type == TransactionType.income;
                            final isRefund = tx.category == FinanceCategory.refund;

                            final isAlreadyRefunded = tx.isRefundedOrder ||
                                FinanceRepository.instance.isOrderAlreadyRefunded(
                                  orderId: tx.orderId,
                                  orderCode: tx.orderCode,
                                  title: tx.title,
                                  notes: tx.notes,
                                );

                            Color avatarBg;
                            Color iconColor;
                            Color iconBorder;
                            IconData avatarIcon;

                            if (isRefund) {
                              avatarBg = const Color(0xFFFFF1F2);
                              iconColor = const Color(0xFFE11D48);
                              iconBorder = const Color(0xFFFECDD3);
                              avatarIcon = Icons.assignment_return_rounded;
                            } else if (isIncome) {
                              avatarBg = isAlreadyRefunded ? const Color(0xFFF8FAFC) : const Color(0xFFECFDF5);
                              iconColor = isAlreadyRefunded ? const Color(0xFF64748B) : const Color(0xFF059669);
                              iconBorder = isAlreadyRefunded ? const Color(0xFFE2E8F0) : const Color(0xFFA7F3D0);
                              avatarIcon = Icons.storefront_rounded;
                            } else {
                              if (tx.category == FinanceCategory.ingredients) {
                                avatarBg = const Color(0xFFFFFBEB);
                                iconColor = const Color(0xFFD97706);
                                iconBorder = const Color(0xFFFDE68A);
                                avatarIcon = Icons.inventory_2_outlined;
                              } else if (tx.category == FinanceCategory.utility) {
                                avatarBg = const Color(0xFFFEF3C7);
                                iconColor = const Color(0xFFEA580C);
                                iconBorder = const Color(0xFFFDE047);
                                avatarIcon = Icons.bolt_rounded;
                              } else if (tx.category == FinanceCategory.salary) {
                                avatarBg = const Color(0xFFF5F3FF);
                                iconColor = const Color(0xFF7C3AED);
                                iconBorder = const Color(0xFFDDD6FE);
                                avatarIcon = Icons.badge_outlined;
                              } else {
                                avatarBg = const Color(0xFFF8FAFC);
                                iconColor = const Color(0xFF475569);
                                iconBorder = const Color(0xFFE2E8F0);
                                avatarIcon = Icons.receipt_long_rounded;
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

                            return Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: const Color(0xFFE2E8F0),
                                  width: 1.1,
                                ),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x060F172A),
                                    blurRadius: 10,
                                    offset: Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: ListTile(
                                onTap: () {
                                  TransactionDetailModal.show(
                                    context,
                                    transaction: tx,
                                    onDelete: tx.source ==
                                            TransactionSource.manual
                                        ? () {
                                            repo.deleteTransaction(tx.id);
                                          }
                                        : null,
                                  );
                                },
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 6,
                                ),
                                leading: Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    color: avatarBg,
                                    borderRadius: BorderRadius.circular(13),
                                    border: Border.all(color: iconBorder, width: 1.0),
                                  ),
                                  child: Icon(
                                    avatarIcon,
                                    color: iconColor,
                                    size: 20,
                                  ),
                                ),
                                title: Row(
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
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 3),
                                  child: Row(
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
                                ),
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
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
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPill(String label, String key) {
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
}
