import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../models/stock_model.dart';
import 'widgets/stock_summary_section.dart';
import 'widgets/stock_card.dart';
import 'widgets/stock_action_sheet.dart';
import 'widgets/stock_filter_sheet.dart';
import 'stock_detail_screen.dart';

/// Main Stock & Inventory overview screen.
class StockScreen extends StatefulWidget {
  const StockScreen({super.key});

  @override
  State<StockScreen> createState() => _StockScreenState();
}

class _StockScreenState extends State<StockScreen> {
  String _searchQuery = '';
  StockStatus? _statusFilter;
  StockCategory _categoryFilter = StockCategory.all;
  bool _lowStockOnly = false;
  StockSortBy _sortBy = StockSortBy.nameAsc;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool get _hasActiveFilters =>
      _statusFilter != null ||
      _categoryFilter != StockCategory.all ||
      _lowStockOnly ||
      _sortBy != StockSortBy.nameAsc;

  int get _activeFilterCount {
    int count = 0;
    if (_statusFilter != null) count++;
    if (_categoryFilter != StockCategory.all) count++;
    if (_lowStockOnly) count++;
    if (_sortBy != StockSortBy.nameAsc) count++;
    return count;
  }

  void _resetAllFilters() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
      _statusFilter = null;
      _categoryFilter = StockCategory.all;
      _lowStockOnly = false;
      _sortBy = StockSortBy.nameAsc;
    });
  }

  Future<void> _openFilterBottomSheet() async {
    final result = await StockFilterSheet.show(
      context,
      currentStatus: _statusFilter,
      currentCategory: _categoryFilter,
      currentLowStockOnly: _lowStockOnly,
      currentSortBy: _sortBy,
    );

    if (result != null) {
      setState(() {
        _statusFilter = result.status;
        _categoryFilter = result.category;
        _lowStockOnly = result.lowStockOnly;
        _sortBy = result.sortBy;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: StockRepository.instance,
      builder: (context, _) {
        final repo = StockRepository.instance;
        final allItems = repo.items;

        // Filter items based on search query, status filter, category filter, and low stock toggle
        final filteredItems = allItems.where((item) {
          final matchesSearch = _searchQuery.isEmpty ||
              item.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              item.supplier.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              (item.note != null && item.note!.toLowerCase().contains(_searchQuery.toLowerCase()));

          final matchesStatus = _statusFilter == null || item.status == _statusFilter;

          final matchesCategory = _categoryFilter == StockCategory.all ||
              item.category == _categoryFilter;

          final matchesLowStock = !_lowStockOnly || item.currentStock <= item.minStock;

          return matchesSearch && matchesStatus && matchesCategory && matchesLowStock;
        }).toList();

        // Apply selected sorting
        switch (_sortBy) {
          case StockSortBy.nameAsc:
            filteredItems.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
            break;
          case StockSortBy.stockAsc:
            filteredItems.sort((a, b) => a.currentStock.compareTo(b.currentStock));
            break;
          case StockSortBy.stockDesc:
            filteredItems.sort((a, b) => b.currentStock.compareTo(a.currentStock));
            break;
          case StockSortBy.valueDesc:
            filteredItems.sort((a, b) => b.totalValue.compareTo(a.totalValue));
            break;
        }

        return Scaffold(
          backgroundColor: AppColors.pageBackground,
          body: SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Top Header Section ─────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryTeal.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.inventory_2_rounded,
                                  color: AppColors.primaryTeal,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Stok Bahan',
                                style: GoogleFonts.poppins(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.darkText,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Kelola Bahan Baku & Inventaris',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: AppColors.mutedText,
                            ),
                          ),
                        ],
                      ),

                      // Quick info pill: Total Asset Value
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.cardBackground,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.lightTealBorder),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.account_balance_wallet_outlined,
                              size: 14,
                              color: AppColors.primaryTeal,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              StockItem.formatRupiah(repo.totalInventoryValue),
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primaryTeal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const Divider(height: 1, color: AppColors.lightTealBorder),

                // ── Scrollable Body ─────────────────────────────────────────
                Expanded(
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                    children: [
                      // 1. KPI Summary Stat Cards (Interactive Filter)
                      StockSummarySection(
                        totalCount: repo.totalItemsCount,
                        lowCount: repo.lowStockCount,
                        criticalCount: repo.criticalStockCount,
                        activeFilter: _statusFilter,
                        onFilterChanged: (filter) {
                          setState(() {
                            _statusFilter = filter;
                          });
                        },
                      ),
                      const SizedBox(height: 16),

                      // 2. Unified Search Bar + Filter Container Row
                      Row(
                        children: [
                          // Search Input Container
                          Expanded(
                            child: Container(
                              height: 48,
                              decoration: BoxDecoration(
                                color: AppColors.cardBackground,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: AppColors.lightTealBorder),
                                boxShadow: const [
                                  BoxShadow(
                                    color: AppColors.cardShadow,
                                    blurRadius: 8,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: TextField(
                                controller: _searchController,
                                onChanged: (val) => setState(() => _searchQuery = val),
                                style: GoogleFonts.inter(fontSize: 14),
                                decoration: InputDecoration(
                                  hintText: 'Cari bahan baku...',
                                  hintStyle: GoogleFonts.inter(
                                    fontSize: 14,
                                    color: AppColors.mutedText,
                                  ),
                                  prefixIcon: const Icon(
                                    Icons.search_rounded,
                                    color: AppColors.primaryTeal,
                                    size: 22,
                                  ),
                                  suffixIcon: _searchQuery.isNotEmpty
                                      ? IconButton(
                                          icon: const Icon(Icons.close_rounded, size: 18),
                                          onPressed: () {
                                            _searchController.clear();
                                            setState(() => _searchQuery = '');
                                          },
                                        )
                                      : null,
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 12,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),

                          // Filter Container Button
                          InkWell(
                            key: const Key('stock_filter_button'),
                            onTap: _openFilterBottomSheet,
                            borderRadius: BorderRadius.circular(14),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              height: 48,
                              padding: const EdgeInsets.symmetric(horizontal: 14),
                              decoration: BoxDecoration(
                                color: _hasActiveFilters
                                    ? AppColors.primaryTeal
                                    : AppColors.cardBackground,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: _hasActiveFilters
                                      ? AppColors.primaryTeal
                                      : AppColors.lightTealBorder,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: _hasActiveFilters
                                        ? AppColors.primaryTeal.withValues(alpha: 0.25)
                                        : AppColors.cardShadow,
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.tune_rounded,
                                    size: 19,
                                    color: _hasActiveFilters
                                        ? Colors.white
                                        : AppColors.primaryTeal,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Filter',
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: _hasActiveFilters
                                          ? Colors.white
                                          : AppColors.darkText,
                                    ),
                                  ),
                                  if (_activeFilterCount > 0) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.25),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        _activeFilterCount.toString(),
                                        style: GoogleFonts.inter(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),

                      // 3. Active Filters Chips Row (Clean Quick Dismissals)
                      if (_hasActiveFilters) ...[
                        const SizedBox(height: 12),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          child: Row(
                            children: [
                              if (_statusFilter != null)
                                _buildActiveTag(
                                  label: 'Status: ${_statusFilter!.label}',
                                  onDeleted: () => setState(() => _statusFilter = null),
                                ),
                              if (_categoryFilter != StockCategory.all)
                                _buildActiveTag(
                                  label: 'Kategori: ${_categoryFilter.label}',
                                  onDeleted: () => setState(() => _categoryFilter = StockCategory.all),
                                ),
                              if (_lowStockOnly)
                                _buildActiveTag(
                                  label: 'Menipis Saja',
                                  onDeleted: () => setState(() => _lowStockOnly = false),
                                ),
                              if (_sortBy != StockSortBy.nameAsc)
                                _buildActiveTag(
                                  label: _sortBy.label,
                                  onDeleted: () => setState(() => _sortBy = StockSortBy.nameAsc),
                                ),
                              InkWell(
                                onTap: _resetAllFilters,
                                borderRadius: BorderRadius.circular(8),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  child: Text(
                                    'Reset Semua',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primaryTeal,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 16),

                      // 4. Stock Items List Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Daftar Bahan (${filteredItems.length})',
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.darkText,
                            ),
                          ),
                          if (_hasActiveFilters || _searchQuery.isNotEmpty)
                            InkWell(
                              onTap: _resetAllFilters,
                              child: Text(
                                'Reset Filter',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primaryTeal,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // 5. Stock Items Cards
                      if (filteredItems.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(32),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppColors.cardBackground,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: AppColors.lightTealBorder),
                          ),
                          child: Column(
                            children: [
                              const Icon(
                                Icons.search_off_rounded,
                                size: 48,
                                color: AppColors.mutedText,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Tidak ada bahan baku yang cocok',
                                style: GoogleFonts.poppins(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.darkText,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Coba ubah kata kunci pencarian atau atur ulang filter',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: AppColors.mutedText,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _resetAllFilters,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryTeal,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text('Reset Semua Filter'),
                              ),
                            ],
                          ),
                        )
                      else
                        ...filteredItems.map((item) {
                          return StockCard(
                            item: item,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => StockDetailScreen(
                                    stockId: item.id,
                                  ),
                                ),
                              );
                            },
                          );
                        }),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Sticky Floating Action Button ──────────────────────────────
          floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
          floatingActionButton: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () => StockActionSheet.show(context),
                icon: const Icon(Icons.add_rounded, size: 22, color: Colors.white),
                label: Text(
                  'Tambah Stok +',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryTeal,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(26),
                  ),
                  elevation: 4,
                  shadowColor: AppColors.primaryTeal.withValues(alpha: 0.35),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildActiveTag({
    required String label,
    required VoidCallback onDeleted,
  }) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primaryTeal.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primaryTeal.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryTeal,
            ),
          ),
          const SizedBox(width: 4),
          InkWell(
            onTap: onDeleted,
            borderRadius: BorderRadius.circular(10),
            child: const Icon(
              Icons.close_rounded,
              size: 14,
              color: AppColors.primaryTeal,
            ),
          ),
        ],
      ),
    );
  }
}
