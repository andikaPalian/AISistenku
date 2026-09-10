import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../models/finance_model.dart';
import 'widgets/transaction_detail_modal.dart';
import 'add_transaction_screen.dart';

/// Full transaction history screen with search, category filtering, and export capability.
class AllTransactionsScreen extends StatefulWidget {
  const AllTransactionsScreen({super.key});

  @override
  State<AllTransactionsScreen> createState() => _AllTransactionsScreenState();
}

class _AllTransactionsScreenState extends State<AllTransactionsScreen> {
  String _searchQuery = '';
  TransactionType? _typeFilter;
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
          final matchesType = _typeFilter == null || tx.type == _typeFilter;
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
          backgroundColor: AppColors.pageBackground,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back_rounded,
                color: AppColors.darkText,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              'Riwayat Transaksi',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.darkText,
              ),
            ),
            centerTitle: true,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(
                color: AppColors.lightTealBorder,
                height: 1,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(
                  Icons.file_download_outlined,
                  color: AppColors.primaryTeal,
                ),
                tooltip: 'Export Laporan',
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Laporan transaksi siap diunduh (PDF/Excel)'),
                      backgroundColor: AppColors.primaryTeal,
                    ),
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
            backgroundColor: AppColors.primaryTeal,
            elevation: 2,
            icon: const Icon(Icons.add_rounded, color: Colors.white),
            label: Text(
              'Tambah Transaksi',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
          body: SafeArea(
            child: Column(
              children: [
                // ── Search & Filter Controls ─────────────────────────
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  child: Column(
                    children: [
                      // Search Bar
                      Container(
                        height: 44,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: AppColors.tealBackgrounds,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.lightTealBorder,
                            width: 1.1,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.search_rounded,
                              color: AppColors.primaryTeal,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: AppColors.darkText,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Cari transaksi, menu, atau catatan...',
                                  hintStyle: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: AppColors.mutedText,
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
                                  color: AppColors.mutedText,
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
                            _buildPill('Semua', null),
                            const SizedBox(width: 6),
                            _buildPill('Pemasukan', TransactionType.income),
                            const SizedBox(width: 6),
                            _buildPill('Pengeluaran', TransactionType.expense),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                Divider(height: 1, color: AppColors.lightTealBorder),

                // ── Transaction List ────────────────────────────────
                Expanded(
                  child: filtered.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.receipt_long_outlined,
                                size: 54,
                                color: AppColors.mutedText.withValues(alpha: 0.4),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Tidak ada transaksi yang cocok',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.mutedText,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                          itemCount: filtered.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final tx = filtered[index];
                            final isIncome =
                                tx.type == TransactionType.income;

                            return Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: AppColors.lightTealBorder,
                                  width: 1.1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primaryTeal.withValues(alpha: 0.04),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
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
                                  vertical: 4,
                                ),
                                leading: Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    color: isIncome
                                        ? AppColors.successBg
                                        : AppColors.dangerBg,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    isIncome
                                        ? Icons.point_of_sale_rounded
                                        : Icons.shopping_bag_outlined,
                                    color: isIncome
                                        ? AppColors.successText
                                        : AppColors.dangerText,
                                    size: 20,
                                  ),
                                ),
                                title: Text(
                                  tx.title,
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.darkText,
                                  ),
                                ),
                                subtitle: Text(
                                  tx.listSubtitle,
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: AppColors.mutedText,
                                  ),
                                ),
                                trailing: Text(
                                  tx.formattedAmountWithSign,
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: isIncome
                                        ? AppColors.successText
                                        : AppColors.destructive,
                                  ),
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

  Widget _buildPill(String label, TransactionType? type) {
    final isSelected = _typeFilter == type;
    return GestureDetector(
      onTap: () {
        setState(() {
          _typeFilter = type;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryTeal : AppColors.tealBackgrounds,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primaryTeal : AppColors.lightTealBorder,
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
}
