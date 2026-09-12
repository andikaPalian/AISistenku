import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/stock_model.dart';
import '../../../models/finance_model.dart';
import '../../shell_screen.dart';

/// Modern Neo-Clean Quick Restock Bottom Sheet Modal.
///
/// Features:
/// - Overflow-proof header with quick link to full inventory management.
/// - Live search bar & category/status filter pills (Semua, Perlu Restock, Aman).
/// - High-contrast cards with dynamic health status (safe vs critical).
/// - Interactive quantity adjustment dialog with stepper (+ / -), quick presets (+1, +5, +10),
///   and automatic synchronization with Finance & Stock repositories.
class QuickRestockSheet extends StatefulWidget {
  const QuickRestockSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const QuickRestockSheet(),
    );
  }

  @override
  State<QuickRestockSheet> createState() => _QuickRestockSheetState();
}

class _QuickRestockSheetState extends State<QuickRestockSheet> {
  final TextEditingController _searchController = TextEditingController();
  int _filterIndex = 0; // 0 = Semua, 1 = Perlu Restock, 2 = Aman
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showRestockQuantityDialog(BuildContext context, StockItem item) {
    double qty = item.unit.toLowerCase() == 'g'
        ? 500.0
        : (item.unit.toLowerCase() == 'kg'
            ? 5.0
            : (item.unit.toLowerCase() == 'l' ? 5.0 : 10.0));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            final estimatedCost = (qty * item.costPerUnit).round();
            final formattedCost = FinanceRepository.formatRupiah(estimatedCost);

            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 16,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 28,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Handle
                  Center(
                    child: Container(
                      width: 38,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFCBD5E1),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Title & Item Name
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(item.icon, color: const Color(0xFF0F172A), size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.name,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Stok saat ini: ${item.formattedCurrentStock} (Min: ${item.formattedMinStock})',
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 11.5,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Divider(height: 1, color: Color(0xFFF1F5F9)),
                  const SizedBox(height: 20),

                  // Quantity Stepper
                  Text(
                    'JUMLAH PENAMBAHAN',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF64748B),
                      letterSpacing: 0.6,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          onPressed: qty > 1
                              ? () => setDialogState(() {
                                    final step = item.unit.toLowerCase() == 'g' ? 100.0 : 1.0;
                                    qty = (qty - step).clamp(1.0, 9999.0);
                                  })
                              : null,
                          icon: const Icon(Icons.remove_circle_outline_rounded),
                          color: const Color(0xFF0F172A),
                          iconSize: 26,
                        ),
                        Text(
                          '${qty % 1 == 0 ? qty.toInt() : qty.toStringAsFixed(1)} ${item.unit}',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        IconButton(
                          onPressed: () => setDialogState(() {
                            final step = item.unit.toLowerCase() == 'g' ? 100.0 : 1.0;
                            qty += step;
                          }),
                          icon: const Icon(Icons.add_circle_outline_rounded),
                          color: const Color(0xFF0F172A),
                          iconSize: 26,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Quick Preset Chips
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      if (item.unit.toLowerCase() == 'g') ...[
                        _buildPresetChip('+250 g', 250, () => setDialogState(() => qty += 250)),
                        _buildPresetChip('+500 g', 500, () => setDialogState(() => qty += 500)),
                        _buildPresetChip('+1000 g', 1000, () => setDialogState(() => qty += 1000)),
                      ] else ...[
                        _buildPresetChip('+1 ${item.unit}', 1, () => setDialogState(() => qty += 1)),
                        _buildPresetChip('+5 ${item.unit}', 5, () => setDialogState(() => qty += 5)),
                        _buildPresetChip('+10 ${item.unit}', 10, () => setDialogState(() => qty += 10)),
                        _buildPresetChip('+20 ${item.unit}', 20, () => setDialogState(() => qty += 20)),
                      ],
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Estimated Cost Summary
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Estimasi Biaya Beli:',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF475569),
                          ),
                        ),
                        Text(
                          formattedCost,
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Submit Button (Solid Obsidian)
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF111111),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () {
                        StockRepository.instance.restockItem(
                          stockId: item.id,
                          quantity: qty,
                          costPerUnit: item.costPerUnit,
                          note: 'Restock Cepat via Beranda',
                        );

                        // Sync with Finance expense recording
                        if (estimatedCost > 0) {
                          FinanceRepository.instance.addTransaction(
                            title: 'Restock ${item.name} (${qty % 1 == 0 ? qty.toInt() : qty} ${item.unit})',
                            type: TransactionType.expense,
                            category: FinanceCategory.ingredients,
                            amount: estimatedCost.toDouble(),
                            source: TransactionSource.manual,
                            notes: 'Pembelian bahan operasional toko',
                            timestamp: DateTime.now(),
                          );
                        }

                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '✅ Berhasil menambah +${qty % 1 == 0 ? qty.toInt() : qty} ${item.unit} ${item.name} (Tercatat di Beban Bahan)',
                            ),
                            backgroundColor: const Color(0xFF111111),
                            duration: const Duration(seconds: 3),
                          ),
                        );
                      },
                      child: Text(
                        'Konfirmasi Restock',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPresetChip(String label, double amount, VoidCallback onTap) {
    return ActionChip(
      label: Text(label),
      onPressed: onTap,
      backgroundColor: Colors.white,
      side: const BorderSide(color: Color(0xFFE2E8F0)),
      labelStyle: GoogleFonts.jetBrainsMono(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF0F172A),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: StockRepository.instance,
      builder: (context, _) {
        final allItems = StockRepository.instance.items;

        final filteredItems = allItems.where((item) {
          final matchesSearch = _searchQuery.isEmpty ||
              item.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              item.category.label.toLowerCase().contains(_searchQuery.toLowerCase());

          final isLow = item.status == StockStatus.kritis || item.status == StockStatus.rendah;
          if (_filterIndex == 1 && !isLow) return false;
          if (_filterIndex == 2 && isLow) return false;

          return matchesSearch;
        }).toList();

        final lowCount = allItems.where((i) => i.status == StockStatus.kritis || i.status == StockStatus.rendah).length;

        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Handle Bar ──────────────────────────────────────────
              const SizedBox(height: 12),
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // ── Header (Overflow-proof) ─────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Restock Cepat',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 19,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF0F172A),
                                  letterSpacing: -0.3,
                                ),
                              ),
                              if (lowCount > 0) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFF1F2),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: const Color(0xFFFDA4AF)),
                                  ),
                                  child: Text(
                                    '$lowCount Menipis',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFFE11D48),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Pilih bahan baku untuk menambah persediaan',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () {
                        Navigator.pop(context);
                        ShellScreen.switchTab(context, 3);
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Kelola Stok',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.arrow_forward_rounded, size: 13, color: Color(0xFF0F172A)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Search Bar ──────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                child: Container(
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) => setState(() => _searchQuery = val.trim()),
                    style: GoogleFonts.plusJakartaSans(fontSize: 13, color: const Color(0xFF0F172A)),
                    decoration: InputDecoration(
                      hintText: 'Cari bahan baku (gula, susu, kopi)...',
                      hintStyle: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: const Color(0xFF94A3B8)),
                      prefixIcon: const Icon(Icons.search_rounded, size: 19, color: Color(0xFF64748B)),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 16),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ),

              // ── Filter Chips ────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 6, 20, 10),
                child: Row(
                  children: [
                    _buildFilterChip('Semua (${allItems.length})', 0),
                    const SizedBox(width: 8),
                    _buildFilterChip('Perlu Restock ($lowCount)', 1),
                    const SizedBox(width: 8),
                    _buildFilterChip('Aman (${allItems.length - lowCount})', 2),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0xFFF1F5F9)),

              // ── Ingredient List / Empty State ───────────────────────
              Flexible(
                child: filteredItems.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(40),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.search_off_rounded, size: 40, color: Color(0xFF94A3B8)),
                            const SizedBox(height: 10),
                            Text(
                              'Bahan tidak ditemukan',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Coba kata kunci pencarian lain.',
                              style: GoogleFonts.plusJakartaSans(fontSize: 12, color: const Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
                        physics: const BouncingScrollPhysics(),
                        itemCount: filteredItems.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final item = filteredItems[index];
                          final isLow = item.status == StockStatus.kritis || item.status == StockStatus.rendah;

                          return Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: isLow ? const Color(0xFFFECDD3) : const Color(0xFFE2E8F0),
                                width: isLow ? 1.3 : 1.0,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.02),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                // Icon
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: isLow ? const Color(0xFFFFF1F2) : const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: isLow ? const Color(0xFFFDA4AF) : const Color(0xFFE2E8F0),
                                    ),
                                  ),
                                  child: Icon(
                                    item.icon,
                                    size: 20,
                                    color: isLow ? const Color(0xFFE11D48) : const Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(width: 14),

                                // Item Details
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Flexible(
                                            child: Text(
                                              item.name,
                                              style: GoogleFonts.plusJakartaSans(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w700,
                                                color: const Color(0xFF0F172A),
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                            decoration: BoxDecoration(
                                              color: isLow ? const Color(0xFFFFF1F2) : const Color(0xFFF0FDF4),
                                              borderRadius: BorderRadius.circular(5),
                                            ),
                                            child: Text(
                                              isLow ? 'Kritis' : 'Aman',
                                              style: GoogleFonts.plusJakartaSans(
                                                fontSize: 9.5,
                                                fontWeight: FontWeight.w800,
                                                color: isLow ? const Color(0xFFE11D48) : const Color(0xFF16A34A),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        'Sisa: ${item.formattedCurrentStock} • Min: ${item.formattedMinStock}',
                                        style: GoogleFonts.jetBrainsMono(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w500,
                                          color: isLow ? const Color(0xFFE11D48) : const Color(0xFF64748B),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 10),

                                // Action Button
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF111111),
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  onPressed: () => _showRestockQuantityDialog(context, item),
                                  child: Text(
                                    '+ Restock',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterChip(String label, int index) {
    final isSelected = _filterIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _filterIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF111111) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(9),
          border: Border.all(
            color: isSelected ? const Color(0xFF111111) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            color: isSelected ? Colors.white : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }
}
