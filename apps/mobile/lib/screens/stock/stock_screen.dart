import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../models/stock_model.dart';
import 'widgets/stock_summary_section.dart';
import 'widgets/stock_card.dart';
import 'widgets/stock_action_sheet.dart';
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
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: StockRepository.instance,
      builder: (context, _) {
        final repo = StockRepository.instance;
        final allItems = repo.items;

        // Filter items based on search query, status filter, and category filter
        final filteredItems = allItems.where((item) {
          final matchesSearch = _searchQuery.isEmpty ||
              item.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              item.supplier.toLowerCase().contains(_searchQuery.toLowerCase());

          final matchesStatus = _statusFilter == null || item.status == _statusFilter;

          final matchesCategory = _categoryFilter == StockCategory.all ||
              item.category == _categoryFilter;

          return matchesSearch && matchesStatus && matchesCategory;
        }).toList();

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
                                  color: AppColors.primaryTeal.withOpacity(0.12),
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

                      // Quick info pill
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.cardBackground,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.cardBorder),
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

                const Divider(height: 1, color: AppColors.border),

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

                      // 2. Search Bar
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.cardBackground,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.cardBorder),
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
                              horizontal: 16,
                              vertical: 14,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // 3. Status Filter Pills (Semua, Baik, Rendah, Kritis)
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: Row(
                          children: [
                            _buildStatusPill(
                              label: 'Semua',
                              status: null,
                              count: repo.totalItemsCount,
                            ),
                            const SizedBox(width: 8),
                            _buildStatusPill(
                              label: 'Aman',
                              status: StockStatus.baik,
                              count: repo.safeStockCount,
                              activeColor: AppColors.successGreen,
                            ),
                            const SizedBox(width: 8),
                            _buildStatusPill(
                              label: 'Rendah',
                              status: StockStatus.rendah,
                              count: repo.lowStockCount,
                              activeColor: AppColors.warningOrange,
                            ),
                            const SizedBox(width: 8),
                            _buildStatusPill(
                              label: 'Kritis',
                              status: StockStatus.kritis,
                              count: repo.criticalStockCount,
                              activeColor: AppColors.destructive,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),

                      // 4. Category Filter Horizontal Chips
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: Row(
                          children: StockCategory.values.map((cat) {
                            final isSelected = _categoryFilter == cat;
                            return Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: ChoiceChip(
                                label: Text(cat.label),
                                selected: isSelected,
                                onSelected: (_) {
                                  setState(() => _categoryFilter = cat);
                                },
                                labelStyle: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                  color: isSelected ? Colors.white : AppColors.mutedText,
                                ),
                                selectedColor: AppColors.primaryTeal,
                                backgroundColor: AppColors.cardBackground,
                                side: BorderSide(
                                  color: isSelected
                                      ? AppColors.primaryTeal
                                      : AppColors.cardBorder,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 5. Stock Items List Header
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
                          if (_statusFilter != null || _categoryFilter != StockCategory.all || _searchQuery.isNotEmpty)
                            InkWell(
                              onTap: () {
                                _searchController.clear();
                                setState(() {
                                  _searchQuery = '';
                                  _statusFilter = null;
                                  _categoryFilter = StockCategory.all;
                                });
                              },
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

                      // 6. Stock Items Cards
                      if (filteredItems.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(32),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppColors.cardBackground,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: AppColors.cardBorder),
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
                                'Coba ubah kata kunci pencarian atau reset filter',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: AppColors.mutedText,
                                ),
                                textAlign: TextAlign.center,
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
                  backgroundColor: const Color(0xFF134E4A), // Rich Deep Teal CTA matching screenshot
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(26),
                  ),
                  elevation: 6,
                  shadowColor: const Color(0xFF134E4A).withOpacity(0.4),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusPill({
    required String label,
    required StockStatus? status,
    required int count,
    Color activeColor = const Color(0xFF134E4A),
  }) {
    final isSelected = _statusFilter == status;
    return InkWell(
      onTap: () {
        setState(() {
          _statusFilter = status;
        });
      },
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : AppColors.cardBackground,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? activeColor : AppColors.cardBorder,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: activeColor.withOpacity(0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? Colors.white : AppColors.darkText,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withOpacity(0.25)
                    : AppColors.surface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                count.toString(),
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? Colors.white : AppColors.mutedText,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
