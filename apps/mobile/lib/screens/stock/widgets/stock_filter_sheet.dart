import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/stock_model.dart';

/// Filter criteria container returned from [StockFilterSheet].
class StockFilterResult {
  final StockStatus? status;
  final StockCategory category;
  final bool lowStockOnly;
  final StockSortBy sortBy;

  const StockFilterResult({
    required this.status,
    required this.category,
    required this.lowStockOnly,
    required this.sortBy,
  });

  bool get hasActiveFilters =>
      status != null ||
      category != StockCategory.all ||
      lowStockOnly ||
      sortBy != StockSortBy.nameAsc;

  int get activeFilterCount {
    int count = 0;
    if (status != null) count++;
    if (category != StockCategory.all) count++;
    if (lowStockOnly) count++;
    if (sortBy != StockSortBy.nameAsc) count++;
    return count;
  }
}

/// Modern Bottom Sheet filter for stock items.
///
/// Designed to follow the Neo-Clean design system:
/// - Docked to bottom with smooth slide transition and rounded top border
/// - Drag handle for natural mobile gestures
/// - Segmented pill tabs with active indicators
/// - Rich status options with real counts and semantic color cues
/// - Category chips with item count badges
/// - Sort options with explanatory subtitles
/// - Prominent alert toggle for low/critical stock
/// - High-contrast action buttons docked in the primary thumb zone
class StockFilterSheet extends StatefulWidget {
  final StockStatus? initialStatus;
  final StockCategory initialCategory;
  final bool initialLowStockOnly;
  final StockSortBy initialSortBy;

  const StockFilterSheet({
    super.key,
    this.initialStatus,
    this.initialCategory = StockCategory.all,
    this.initialLowStockOnly = false,
    this.initialSortBy = StockSortBy.nameAsc,
  });

  /// Show the filter sheet as a modern modal bottom sheet.
  static Future<StockFilterResult?> show(
    BuildContext context, {
    StockStatus? currentStatus,
    StockCategory currentCategory = StockCategory.all,
    bool currentLowStockOnly = false,
    StockSortBy currentSortBy = StockSortBy.nameAsc,
  }) {
    return showModalBottomSheet<StockFilterResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (context) {
        return StockFilterSheet(
          initialStatus: currentStatus,
          initialCategory: currentCategory,
          initialLowStockOnly: currentLowStockOnly,
          initialSortBy: currentSortBy,
        );
      },
    );
  }

  @override
  State<StockFilterSheet> createState() => _StockFilterSheetState();
}

class _StockFilterSheetState extends State<StockFilterSheet>
    with SingleTickerProviderStateMixin {
  late StockStatus? _selectedStatus;
  late StockCategory _selectedCategory;
  late bool _lowStockOnly;
  late StockSortBy _selectedSortBy;
  late TabController _tabController;

  static const _tabs = ['Status', 'Kategori', 'Urutkan'];

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.initialStatus;
    _selectedCategory = widget.initialCategory;
    _lowStockOnly = widget.initialLowStockOnly;
    _selectedSortBy = widget.initialSortBy;
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _resetFilters() {
    HapticFeedback.lightImpact();
    setState(() {
      _selectedStatus = null;
      _selectedCategory = StockCategory.all;
      _lowStockOnly = false;
      _selectedSortBy = StockSortBy.nameAsc;
    });
  }

  bool get _hasFilters =>
      _selectedStatus != null ||
      _selectedCategory != StockCategory.all ||
      _lowStockOnly ||
      _selectedSortBy != StockSortBy.nameAsc;

  int _calculateMatchingCount() {
    final allItems = StockRepository.instance.items;
    return allItems.where((item) {
      final matchesStatus =
          _selectedStatus == null || item.status == _selectedStatus;
      final matchesCategory = _selectedCategory == StockCategory.all ||
          item.category == _selectedCategory;
      final matchesLowStock =
          !_lowStockOnly || item.currentStock <= item.minStock;
      return matchesStatus && matchesCategory && matchesLowStock;
    }).length;
  }

  int _getCategoryItemCount(StockCategory cat, StockRepository repo) {
    if (cat == StockCategory.all) return repo.totalItemsCount;
    return repo.items.where((item) => item.category == cat).length;
  }

  void _applyAndClose() {
    HapticFeedback.mediumImpact();
    Navigator.pop(
      context,
      StockFilterResult(
        status: _selectedStatus,
        category: _selectedCategory,
        lowStockOnly: _lowStockOnly,
        sortBy: _selectedSortBy,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final repo = StockRepository.instance;
    final matchingCount = _calculateMatchingCount();
    final maxHeight = MediaQuery.of(context).size.height * 0.85;

    return Material(
      color: Colors.transparent,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: maxHeight,
          maxWidth: 520,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
              color: Color(0x1A000000),
              blurRadius: 32,
              offset: Offset(0, -6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag handle
                _buildDragHandle(),

                // Header
                _buildHeader(),

                // Segmented Tab Bar
                _buildTabBar(),

                // Tab Content Body
                Flexible(
                  child: AnimatedBuilder(
                    animation: _tabController,
                    builder: (context, _) {
                      return AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeIn,
                        child: _buildTabContent(_tabController.index, repo),
                      );
                    },
                  ),
                ),

                // Low Stock Alert Toggle Card
                _buildLowStockToggle(repo),

                // Docked Action Bar
                _buildActionBar(matchingCount),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  DRAG HANDLE
  // ═══════════════════════════════════════════════════════════════
  Widget _buildDragHandle() {
    return Center(
      child: Container(
        margin: const EdgeInsets.only(top: 10, bottom: 6),
        width: 40,
        height: 4.5,
        decoration: BoxDecoration(
          color: const Color(0xFFCBD5E1),
          borderRadius: BorderRadius.circular(2.5),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  HEADER
  // ═══════════════════════════════════════════════════════════════
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 8, 16, 4),
      child: Row(
        children: [
          // Icon badge
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.tune_rounded,
              color: Color(0xFF10B981),
              size: 19,
            ),
          ),
          const SizedBox(width: 12),
          // Title & subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Filter & Urutkan Stok',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F172A),
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  'Temukan bahan baku lebih cepat',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          // Reset Button
          if (_hasFilters)
            InkWell(
              onTap: _resetFilters,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.refresh_rounded, size: 13, color: Color(0xFFEF4444)),
                    const SizedBox(width: 3),
                    Text(
                      'Reset',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFEF4444),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          // Close Icon
          InkWell(
            onTap: () => Navigator.pop(context),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close_rounded,
                size: 16,
                color: Color(0xFF64748B),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  TAB BAR
  // ═══════════════════════════════════════════════════════════════
  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(14),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(11),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 6,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: const Color(0xFF0F172A),
        unselectedLabelColor: const Color(0xFF64748B),
        labelStyle: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        tabs: _tabs.map((t) {
          final hasActive = _tabHasActiveFilter(t);
          return Tab(
            height: 38,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(child: Text(t, overflow: TextOverflow.ellipsis)),
                if (hasActive) ...[
                  const SizedBox(width: 5),
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: Color(0xFF10B981),
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  bool _tabHasActiveFilter(String tab) {
    switch (tab) {
      case 'Status':
        return _selectedStatus != null;
      case 'Kategori':
        return _selectedCategory != StockCategory.all;
      case 'Urutkan':
        return _selectedSortBy != StockSortBy.nameAsc;
      default:
        return false;
    }
  }

  // ═══════════════════════════════════════════════════════════════
  //  TAB CONTENT
  // ═══════════════════════════════════════════════════════════════
  Widget _buildTabContent(int index, StockRepository repo) {
    switch (index) {
      case 0:
        return _buildStatusTab(repo);
      case 1:
        return _buildCategoryTab(repo);
      case 2:
        return _buildSortTab();
      default:
        return const SizedBox.shrink();
    }
  }

  // ── Status Tab ─────────────────────────────────────────────────
  Widget _buildStatusTab(StockRepository repo) {
    return SingleChildScrollView(
      key: const ValueKey('status_tab'),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatusTile(
            icon: Icons.layers_outlined,
            label: 'Semua Status',
            subtitle: '${repo.totalItemsCount} total bahan baku terdaftar',
            count: repo.totalItemsCount,
            isSelected: _selectedStatus == null,
            accentColor: const Color(0xFF0F172A),
            onTap: () => setState(() => _selectedStatus = null),
          ),
          const SizedBox(height: 10),
          _buildStatusTile(
            icon: Icons.check_circle_rounded,
            label: 'Stok Aman',
            subtitle: '${repo.safeStockCount} bahan dengan stok mencukupi',
            count: repo.safeStockCount,
            isSelected: _selectedStatus == StockStatus.baik,
            accentColor: const Color(0xFF10B981),
            onTap: () => setState(() => _selectedStatus = StockStatus.baik),
          ),
          const SizedBox(height: 10),
          _buildStatusTile(
            icon: Icons.warning_amber_rounded,
            label: 'Stok Rendah',
            subtitle: '${repo.lowStockCount} bahan mendekati batas minimum',
            count: repo.lowStockCount,
            isSelected: _selectedStatus == StockStatus.rendah,
            accentColor: const Color(0xFFF59E0B),
            onTap: () => setState(() => _selectedStatus = StockStatus.rendah),
          ),
          const SizedBox(height: 10),
          _buildStatusTile(
            icon: Icons.error_outline_rounded,
            label: 'Stok Kritis',
            subtitle: '${repo.criticalStockCount} bahan perlu segera restock!',
            count: repo.criticalStockCount,
            isSelected: _selectedStatus == StockStatus.kritis,
            accentColor: const Color(0xFFEF4444),
            onTap: () => setState(() => _selectedStatus = StockStatus.kritis),
          ),
        ],
      ),
    );
  }

  // ── Category Tab ───────────────────────────────────────────────
  Widget _buildCategoryTab(StockRepository repo) {
    return SingleChildScrollView(
      key: const ValueKey('category_tab'),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      child: Wrap(
        spacing: 8,
        runSpacing: 10,
        children: StockCategory.values.map((cat) {
          final isSelected = _selectedCategory == cat;
          final count = _getCategoryItemCount(cat, repo);
          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _selectedCategory = cat);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF0F172A) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF0F172A)
                      : (count > 0 ? const Color(0xFFE2E8F0) : const Color(0xFFF1F5F9)),
                  width: isSelected ? 1.5 : 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: const Color(0xFF0F172A).withValues(alpha: 0.2),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isSelected) ...[
                    const Icon(
                      Icons.check_rounded,
                      size: 15,
                      color: Color(0xFF10B981),
                    ),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    cat.label,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected
                          ? Colors.white
                          : (count > 0 ? const Color(0xFF0F172A) : const Color(0xFF94A3B8)),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.white.withValues(alpha: 0.2)
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$count',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isSelected ? Colors.white : const Color(0xFF64748B),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Sort Tab ───────────────────────────────────────────────────
  Widget _buildSortTab() {
    final sortMeta = {
      StockSortBy.nameAsc: (
        icon: Icons.sort_by_alpha_rounded,
        subtitle: 'Urutan alfabetik A ke Z',
        color: const Color(0xFF0F172A),
      ),
      StockSortBy.stockAsc: (
        icon: Icons.priority_high_rounded,
        subtitle: 'Prioritas restock bahan menipis & segera habis',
        color: const Color(0xFFF59E0B),
      ),
      StockSortBy.stockDesc: (
        icon: Icons.inventory_2_outlined,
        subtitle: 'Bahan dengan volume ketersediaan fisik terbanyak',
        color: const Color(0xFF0284C7),
      ),
      StockSortBy.valueDesc: (
        icon: Icons.monetization_on_outlined,
        subtitle: 'Bahan dengan total nilai modal/inventaris tertinggi',
        color: const Color(0xFF10B981),
      ),
    };

    return SingleChildScrollView(
      key: const ValueKey('sort_tab'),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      child: Column(
        children: StockSortBy.values.map((sort) {
          final isSelected = _selectedSortBy == sort;
          final meta = sortMeta[sort]!;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _selectedSortBy = sort);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? meta.color.withValues(alpha: 0.07)
                      : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected
                        ? meta.color.withValues(alpha: 0.5)
                        : const Color(0xFFE2E8F0),
                    width: isSelected ? 1.5 : 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: meta.color.withValues(alpha: 0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? meta.color.withValues(alpha: 0.15)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? meta.color.withValues(alpha: 0.3)
                              : const Color(0xFFE2E8F0),
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        meta.icon,
                        size: 19,
                        color: isSelected ? meta.color : const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            sort.label,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13.5,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                              color: isSelected ? const Color(0xFF0F172A) : const Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            meta.subtitle,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11.5,
                              color: isSelected
                                  ? meta.color.withValues(alpha: 0.9)
                                  : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: isSelected ? meta.color : Colors.transparent,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? meta.color : const Color(0xFFCBD5E1),
                          width: 1.5,
                        ),
                      ),
                      child: isSelected
                          ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
                          : null,
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  STATUS TILE
  // ═══════════════════════════════════════════════════════════════
  Widget _buildStatusTile({
    required IconData icon,
    required String label,
    required String subtitle,
    required int count,
    required bool isSelected,
    required Color accentColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? accentColor.withValues(alpha: 0.07)
              : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? accentColor.withValues(alpha: 0.5)
                : const Color(0xFFE2E8F0),
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: accentColor.withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: isSelected
                    ? accentColor.withValues(alpha: 0.15)
                    : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? accentColor.withValues(alpha: 0.3)
                      : const Color(0xFFE2E8F0),
                  width: 1,
                ),
              ),
              child: Icon(
                icon,
                size: 19,
                color: isSelected ? accentColor : const Color(0xFF64748B),
              ),
            ),
            const SizedBox(width: 12),
            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13.5,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                      color: isSelected ? const Color(0xFF0F172A) : const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w400,
                      color: isSelected
                          ? accentColor.withValues(alpha: 0.9)
                          : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Count pill badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: isSelected
                    ? accentColor.withValues(alpha: 0.15)
                    : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? accentColor : const Color(0xFF64748B),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Checkmark indicator
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: isSelected ? accentColor : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? accentColor : const Color(0xFFCBD5E1),
                  width: 1.5,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  LOW STOCK TOGGLE
  // ═══════════════════════════════════════════════════════════════
  Widget _buildLowStockToggle(StockRepository repo) {
    final alertCount = repo.lowStockCount + repo.criticalStockCount;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: _lowStockOnly
            ? const Color(0xFFFFFBEB)
            : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _lowStockOnly
              ? const Color(0xFFF59E0B).withValues(alpha: 0.4)
              : const Color(0xFFE2E8F0),
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: _lowStockOnly
                  ? const Color(0xFFF59E0B).withValues(alpha: 0.15)
                  : Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              _lowStockOnly
                  ? Icons.notifications_active_rounded
                  : Icons.notifications_none_rounded,
              size: 18,
              color: _lowStockOnly ? const Color(0xFFD97706) : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hanya Stok Menipis & Kritis',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: _lowStockOnly ? const Color(0xFFB45309) : const Color(0xFF0F172A),
                  ),
                ),
                Text(
                  '$alertCount bahan perlu perhatian restock',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: _lowStockOnly ? const Color(0xFFD97706) : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          Transform.scale(
            scale: 0.85,
            child: Switch.adaptive(
              value: _lowStockOnly,
              onChanged: (val) {
                HapticFeedback.selectionClick();
                setState(() => _lowStockOnly = val);
              },
              activeTrackColor: const Color(0xFFF59E0B),
              activeThumbColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  BOTTOM ACTION BAR
  // ═══════════════════════════════════════════════════════════════
  Widget _buildActionBar(int matchingCount) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
      child: Row(
        children: [
          // Cancel
          Expanded(
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFFF1F5F9),
                foregroundColor: const Color(0xFF0F172A),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                'Batal',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF475569),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Apply
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _applyAndClose,
              style: ElevatedButton.styleFrom(
                backgroundColor: matchingCount > 0
                    ? const Color(0xFF0F172A)
                    : const Color(0xFF94A3B8),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: matchingCount > 0 ? 3 : 0,
                shadowColor: Colors.black.withValues(alpha: 0.25),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    matchingCount > 0 ? Icons.check_rounded : Icons.search_off_rounded,
                    size: 18,
                    color: matchingCount > 0 ? const Color(0xFF10B981) : Colors.white70,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    matchingCount > 0
                        ? 'Tampilkan $matchingCount Bahan'
                        : 'Tidak Ada Bahan',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13.5,
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
    );
  }
}
