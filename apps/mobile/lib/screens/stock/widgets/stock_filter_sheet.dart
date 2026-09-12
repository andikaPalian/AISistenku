import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/stock_model.dart';

/// Filter criteria container returned from [StockFilterPopup].
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

/// Modern floating popup filter for stock items.
///
/// Shown as a centered dialog with backdrop blur and scale animation,
/// inspired by modern e-commerce and F&B apps (Shopee, Gojek, Grab).
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

  /// Show the filter popup as a dialog overlay with animation.
  static Future<StockFilterResult?> show(
    BuildContext context, {
    StockStatus? currentStatus,
    StockCategory currentCategory = StockCategory.all,
    bool currentLowStockOnly = false,
    StockSortBy currentSortBy = StockSortBy.nameAsc,
  }) {
    return showGeneralDialog<StockFilterResult>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Filter',
      barrierColor: Colors.black.withValues(alpha: 0.35),
      transitionDuration: const Duration(milliseconds: 300),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curve = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return FadeTransition(
          opacity: curve,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.92, end: 1.0).animate(curve),
            alignment: Alignment.topRight,
            child: child,
          ),
        );
      },
      pageBuilder: (context, animation, secondaryAnimation) {
        return SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.only(top: 160, left: 16, right: 16),
              child: StockFilterSheet(
                initialStatus: currentStatus,
                initialCategory: currentCategory,
                initialLowStockOnly: currentLowStockOnly,
                initialSortBy: currentSortBy,
              ),
            ),
          ),
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

  // Sections: 0 = Status, 1 = Kategori, 2 = Urutkan
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

    return Material(
      color: Colors.transparent,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.62,
          maxWidth: 420,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          // No border
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 32,
              offset: const Offset(0, 8),
              spreadRadius: 2,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Header ────────────────────────────────────────
              _buildHeader(),

              // ── Tab Bar ───────────────────────────────────────
              _buildTabBar(),

              // ── Tab Body ──────────────────────────────────────
              Flexible(
                child: AnimatedBuilder(
                  animation: _tabController,
                  builder: (context, _) {
                    return AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeIn,
                      child: _buildTabContent(
                        _tabController.index,
                        repo,
                      ),
                    );
                  },
                ),
              ),

              // ── Low stock toggle ──────────────────────────────
              _buildLowStockToggle(repo),

              // ── Bottom Actions ────────────────────────────────
              _buildActionBar(matchingCount),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  HEADER
  // ═══════════════════════════════════════════════════════════════
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 12, 0),
      child: Row(
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF111111),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.tune_rounded,
              color: Color(0xFF22C55E),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          // Title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Filter & Urutkan Stok',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF111111),
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  'Temukan bahan baku lebih cepat',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          // Reset button
          if (_hasFilters)
            TextButton.icon(
              onPressed: _resetFilters,
              icon: const Icon(Icons.refresh_rounded, size: 15),
              label: Text(
                'Reset',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFEF4444),
                padding: const EdgeInsets.symmetric(horizontal: 10),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
            ),
          // Close
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.close_rounded, size: 16, color: Color(0xFF64748B)),
            ),
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
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
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
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
        labelColor: const Color(0xFF111111),
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
            height: 36,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(child: Text(t, overflow: TextOverflow.ellipsis)),
                if (hasActive) ...[
                  const SizedBox(width: 4),
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Color(0xFF22C55E),
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
        return _buildCategoryTab();
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
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildOptionTile(
            icon: Icons.apps_rounded,
            label: 'Semua Status',
            subtitle: ' bahan',
            isSelected: _selectedStatus == null,
            accentColor: const Color(0xFF111111),
            onTap: () => setState(() => _selectedStatus = null),
          ),
          const SizedBox(height: 8),
          _buildOptionTile(
            icon: Icons.check_circle_outline_rounded,
            label: 'Stok Aman',
            subtitle: ' bahan',
            isSelected: _selectedStatus == StockStatus.baik,
            accentColor: const Color(0xFF22C55E),
            onTap: () => setState(() => _selectedStatus = StockStatus.baik),
          ),
          const SizedBox(height: 8),
          _buildOptionTile(
            icon: Icons.warning_amber_rounded,
            label: 'Stok Rendah',
            subtitle: ' bahan',
            isSelected: _selectedStatus == StockStatus.rendah,
            accentColor: const Color(0xFFF59E0B),
            onTap: () => setState(() => _selectedStatus = StockStatus.rendah),
          ),
          const SizedBox(height: 8),
          _buildOptionTile(
            icon: Icons.error_outline_rounded,
            label: 'Stok Kritis',
            subtitle: ' bahan — perlu restock!',
            isSelected: _selectedStatus == StockStatus.kritis,
            accentColor: const Color(0xFFEF4444),
            onTap: () => setState(() => _selectedStatus = StockStatus.kritis),
          ),
        ],
      ),
    );
  }

  // ── Category Tab ───────────────────────────────────────────────
  Widget _buildCategoryTab() {
    return SingleChildScrollView(
      key: const ValueKey('category_tab'),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: StockCategory.values.map((cat) {
          final isSelected = _selectedCategory == cat;
          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _selectedCategory = cat);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF111111)
                    : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF111111)
                      : const Color(0xFFE2E8F0),
                  width: isSelected ? 1.5 : 1,
                ),
                boxShadow: isSelected
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
                  if (isSelected) ...[
                    const Icon(
                      Icons.check_rounded,
                      size: 15,
                      color: Color(0xFF22C55E),
                    ),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    cat.label,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? Colors.white : const Color(0xFF111111),
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
    return SingleChildScrollView(
      key: const ValueKey('sort_tab'),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      child: Column(
        children: StockSortBy.values.map((sort) {
          final isSelected = _selectedSortBy == sort;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _buildOptionTile(
              icon: sort.icon,
              label: sort.label,
              isSelected: isSelected,
              accentColor: const Color(0xFF111111),
              onTap: () => setState(() => _selectedSortBy = sort),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  LOW STOCK TOGGLE
  // ═══════════════════════════════════════════════════════════════
  Widget _buildLowStockToggle(StockRepository repo) {
    final alertCount = repo.lowStockCount + repo.criticalStockCount;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: _lowStockOnly
            ? const Color(0xFFFEF3C7)
            : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _lowStockOnly ? const Color(0xFFF59E0B).withValues(alpha: 0.3) : const Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            _lowStockOnly
                ? Icons.notifications_active_rounded
                : Icons.notifications_none_rounded,
            size: 18,
            color: _lowStockOnly ? const Color(0xFFD97706) : const Color(0xFF64748B),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hanya Stok Menipis & Kritis',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _lowStockOnly ? const Color(0xFFD97706) : const Color(0xFF111111),
                  ),
                ),
                Text(
                  '$alertCount bahan perlu perhatian',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: const Color(0xFF64748B),
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
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Row(
        children: [
          // Cancel
          Expanded(
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFFF1F5F9),
                foregroundColor: const Color(0xFF111111),
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                'Batal',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF111111),
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
                backgroundColor: const Color(0xFF111111),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 4,
                shadowColor: Colors.black.withValues(alpha: 0.25),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_rounded, size: 18, color: Color(0xFF22C55E)),
                  const SizedBox(width: 6),
                  Text(
                    'Tampilkan $matchingCount Bahan',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
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

  // ═══════════════════════════════════════════════════════════════
  //  REUSABLE OPTION TILE
  // ═══════════════════════════════════════════════════════════════
  Widget _buildOptionTile({
    required IconData icon,
    required String label,
    String? subtitle,
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
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? accentColor.withValues(alpha: 0.08)
              : const Color(0xFFF8FAFC), // Slight slate tint
          borderRadius: BorderRadius.circular(14),
          // No border
        ),
        child: Row(
          children: [
            // Leading icon circle
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected
                    ? accentColor.withValues(alpha: 0.15)
                    : Colors.white, // White circle
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                size: 18,
                color: isSelected ? accentColor : AppColors.mutedText,
              ),
            ),
            const SizedBox(width: 12),
            // Label
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected ? accentColor : AppColors.darkText,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppColors.mutedText,
                      ),
                    ),
                ],
              ),
            ),
            // Check mark
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: isSelected ? accentColor : Colors.transparent,
                borderRadius: BorderRadius.circular(7),
                // No border
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
}
