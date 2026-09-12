import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      StockRepository.instance.fetchStocksFromBackend();
    });
  }

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
          backgroundColor: const Color(0xFFF8FAFC),
          body: SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Top Sticky Header Section ─────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          if (Navigator.canPop(context)) ...[
                            IconButton(
                              icon: const Icon(
                                Icons.arrow_back_rounded,
                                color: Color(0xFF0F172A),
                                size: 22,
                              ),
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.white,
                                padding: const EdgeInsets.all(8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                                ),
                              ),
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                            const SizedBox(width: 12),
                          ],
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Stok Bahan',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF0F172A),
                                  letterSpacing: -0.6,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Row(
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF22C55E),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    'Total Aset: ${StockItem.formatRupiah(repo.totalInventoryValue)}',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF16A34A),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),

                      // Primary Action: + Tambah (Solid Black Pill)
                      InkWell(
                        onTap: () => StockActionSheet.show(context),
                        borderRadius: BorderRadius.circular(24),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFF111111),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.16),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.add_rounded,
                                size: 16,
                                color: Color(0xFF22C55E),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                'Tambah',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const Divider(height: 1, color: Color(0xFFE2E8F0)),

                // ── Scrollable Body ─────────────────────────────────────────
                Expanded(
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 160),
                    children: [
                      // 1. Sleek Segmented Status Bar (Total Bahan | Rendah | Kritis)
                      StockSummarySection(
                        totalCount: repo.totalItemsCount,
                        lowCount: repo.lowStockCount,
                        criticalCount: repo.criticalStockCount,
                        totalValue: repo.totalInventoryValue,
                        activeFilter: _statusFilter,
                        onFilterChanged: (filter) {
                          setState(() {
                            _statusFilter = filter;
                          });
                        },
                      ),
                      const SizedBox(height: 12),

                      // 2. Unified Search Bar + Filter Button Row
                      Row(
                        children: [
                          // Search Input Container
                          Expanded(
                            child: Container(
                              height: 44,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: const Color(0xFFE2E8F0), width: 1.1),
                              ),
                              child: TextField(
                                controller: _searchController,
                                onChanged: (val) => setState(() => _searchQuery = val),
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF0F172A),
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Cari bahan baku, supplier...',
                                  hintStyle: GoogleFonts.plusJakartaSans(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w400,
                                    color: const Color(0xFF94A3B8),
                                  ),
                                  prefixIcon: const Icon(
                                    Icons.search_rounded,
                                    color: Color(0xFF64748B),
                                    size: 19,
                                  ),
                                  suffixIcon: _searchQuery.isNotEmpty
                                      ? IconButton(
                                          icon: const Icon(Icons.close_rounded, size: 17),
                                          onPressed: () {
                                            _searchController.clear();
                                            setState(() => _searchQuery = '');
                                          },
                                        )
                                      : null,
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 11,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Filter Container Button
                          InkWell(
                            key: const Key('stock_filter_button'),
                            onTap: _openFilterBottomSheet,
                            borderRadius: BorderRadius.circular(14),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              height: 44,
                              padding: const EdgeInsets.symmetric(horizontal: 14),
                              decoration: BoxDecoration(
                                color: _hasActiveFilters ? const Color(0xFF111111) : Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: _hasActiveFilters ? const Color(0xFF111111) : const Color(0xFFE2E8F0),
                                  width: 1.1,
                                ),
                                boxShadow: _hasActiveFilters
                                    ? [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.15),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.tune_rounded,
                                    size: 17,
                                    color: _hasActiveFilters
                                        ? const Color(0xFF22C55E)
                                        : const Color(0xFF0F172A),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Filter',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                      color: _hasActiveFilters
                                          ? Colors.white
                                          : const Color(0xFF0F172A),
                                    ),
                                  ),
                                  if (_activeFilterCount > 0) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 5.5,
                                        vertical: 1.5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF22C55E),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        _activeFilterCount.toString(),
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w800,
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
                      const SizedBox(height: 10),

                      // 3. Direct Category Filter Pill Bar
                      SizedBox(
                        height: 34,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          itemCount: StockCategory.values.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 6),
                          itemBuilder: (context, index) {
                            final cat = StockCategory.values[index];
                            final isSelected = _categoryFilter == cat;
                            return InkWell(
                              onTap: () => setState(() => _categoryFilter = cat),
                              borderRadius: BorderRadius.circular(18),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                                decoration: BoxDecoration(
                                  color: isSelected ? const Color(0xFF111111) : Colors.white,
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: isSelected ? const Color(0xFF111111) : const Color(0xFFE2E8F0),
                                    width: 1.1,
                                  ),
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.12),
                                            blurRadius: 4,
                                            offset: const Offset(0, 1.5),
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Text(
                                  cat.label,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12.5,
                                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                                    color: isSelected ? Colors.white : const Color(0xFF475569),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 4. Active Filters Chips Row (Clean Quick Dismissals)
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
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF111111),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 16),

                      // 5. Stock Items List Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Daftar Bahan (${filteredItems.length})',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF111111),
                            ),
                          ),
                          if (_hasActiveFilters || _searchQuery.isNotEmpty)
                            InkWell(
                              onTap: _resetAllFilters,
                              child: Text(
                                'Reset Filter',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF16A34A),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // 6. Stock Items Cards
                      if (filteredItems.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(32),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
                          ),
                          child: Column(
                            children: [
                              const Icon(
                                Icons.search_off_rounded,
                                size: 48,
                                color: Color(0xFF94A3B8),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Tidak ada bahan baku yang cocok',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF111111),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Coba ubah kata kunci pencarian atau atur ulang filter',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  color: const Color(0xFF64748B),
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _resetAllFilters,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF111111),
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
                        const SizedBox(height: 24),
                    ],
                  ),
                ),
              ],
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
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF111111),
            ),
          ),
          const SizedBox(width: 4),
          InkWell(
            onTap: onDeleted,
            borderRadius: BorderRadius.circular(10),
            child: const Icon(
              Icons.close_rounded,
              size: 14,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }
}
