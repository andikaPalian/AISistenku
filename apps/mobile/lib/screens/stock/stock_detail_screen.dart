import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/stock_model.dart';
import 'widgets/restock_modal.dart';
import 'widgets/adjust_stock_modal.dart';
import 'widgets/add_stock_modal.dart';

/// Comprehensive Stock Detail and Movement History Screen.
///
/// Designed to eliminate "AI slop" and replace fragmented 2x2 boxes with
/// an executive-grade specification sheet and tactile control actions.
class StockDetailScreen extends StatefulWidget {
  final String stockId;

  const StockDetailScreen({
    super.key,
    required this.stockId,
  });

  @override
  State<StockDetailScreen> createState() => _StockDetailScreenState();
}

class _StockDetailScreenState extends State<StockDetailScreen> {
  StockLogType? _historyFilter;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: StockRepository.instance,
      builder: (context, _) {
        final item = StockRepository.instance.getItemById(widget.stockId);
        if (item == null) {
          return Scaffold(
            backgroundColor: const Color(0xFFF8FAFC),
            appBar: AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A)),
                onPressed: () => Navigator.pop(context),
              ),
              title: Text(
                'Bahan Baku',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ),
            body: Center(
              child: Text(
                'Data bahan baku tidak ditemukan',
                style: GoogleFonts.plusJakartaSans(
                  color: const Color(0xFF64748B),
                ),
              ),
            ),
          );
        }

        final allLogs = StockRepository.instance.getLogsForStock(item.id);
        final filteredLogs = _historyFilter == null
            ? allLogs
            : allLogs.where((l) => l.type == _historyFilter).toList();

        final status = item.status;
        String statusLabel;
        Color statusBg;
        Color statusText;
        IconData statusIcon;
        Color progressColor;

        switch (status) {
          case StockStatus.kritis:
            statusLabel = 'Kritis';
            statusBg = const Color(0xFFFEE2E2);
            statusText = const Color(0xFFDC2626);
            statusIcon = Icons.error_outline_rounded;
            progressColor = const Color(0xFFEF4444);
            break;
          case StockStatus.rendah:
            statusLabel = 'Rendah';
            statusBg = const Color(0xFFFEF3C7);
            statusText = const Color(0xFFD97706);
            statusIcon = Icons.warning_amber_rounded;
            progressColor = const Color(0xFFF59E0B);
            break;
          case StockStatus.baik:
            statusLabel = 'Aman';
            statusBg = const Color(0xFFDCFCE7);
            statusText = const Color(0xFF16A34A);
            statusIcon = Icons.check_circle_outline_rounded;
            progressColor = const Color(0xFF22C55E);
            break;
        }

        final stockNumStr = item.currentStock == item.currentStock.roundToDouble()
            ? item.currentStock.toInt().toString()
            : item.currentStock.toStringAsFixed(1);

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            surfaceTintColor: Colors.transparent,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A)),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              item.name,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
              ),
            ),
            centerTitle: true,
            actions: [
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded, color: Color(0xFF0F172A)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                onSelected: (value) {
                  if (value == 'edit') {
                    AddStockModal.show(context, itemToEdit: item);
                  } else if (value == 'adjust') {
                    AdjustStockModal.show(context, item: item);
                  } else if (value == 'delete') {
                    _confirmDelete(context, item);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined, size: 18, color: Color(0xFF0F172A)),
                        SizedBox(width: 10),
                        Text('Ubah Detail Bahan'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'adjust',
                    child: Row(
                      children: [
                        Icon(Icons.tune_rounded, size: 18, color: Color(0xFF3B82F6)),
                        SizedBox(width: 10),
                        Text('Penyesuaian Opname'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFFEF4444)),
                        SizedBox(width: 10),
                        Text('Hapus Bahan', style: TextStyle(color: Color(0xFFEF4444))),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          body: SafeArea(
            bottom: false,
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── 1. Hero Obsidian Executive Card ──────────────────
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFF111111),
                            borderRadius: BorderRadius.circular(22),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.16),
                                blurRadius: 18,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Top Row: Category Pill & Status Badge
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: Colors.white.withValues(alpha: 0.12),
                                        width: 0.8,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          item.icon,
                                          size: 13,
                                          color: const Color(0xFFCBD5E1),
                                        ),
                                        const SizedBox(width: 5),
                                        Text(
                                          item.category.label,
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w600,
                                            color: const Color(0xFFCBD5E1),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
                                    decoration: BoxDecoration(
                                      color: statusBg,
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(statusIcon, color: statusText, size: 13),
                                        const SizedBox(width: 4.5),
                                        Text(
                                          statusLabel,
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w700,
                                            color: statusText,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 18),

                              // STOK SAAT INI (test critical label)
                              Text(
                                'STOK SAAT INI',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF94A3B8),
                                  letterSpacing: 1.4,
                                ),
                              ),
                              const SizedBox(height: 4),

                              // Big Stock Number + Unit + Valuation Tag
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  Text(
                                    stockNumStr,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 40,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                      letterSpacing: -1,
                                      height: 1.05,
                                    ),
                                  ),
                                  const SizedBox(width: 7),
                                  Text(
                                    item.unit,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF94A3B8),
                                    ),
                                  ),
                                  const Spacer(),
                                  // Valuation Tag Pill
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          'Estimasi Nilai',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w500,
                                            color: const Color(0xFF94A3B8),
                                          ),
                                        ),
                                        Text(
                                          item.formattedTotalValue,
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 18),

                              // Health & Threshold Gauge
                              ClipRRect(
                                borderRadius: BorderRadius.circular(3),
                                child: LinearProgressIndicator(
                                  value: item.minThresholdRatio,
                                  minHeight: 5.5,
                                  backgroundColor: Colors.white.withValues(alpha: 0.12),
                                  valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    item.status == StockStatus.baik
                                        ? '✓ Stok Aman (${item.minThresholdPercentage}% dari min)'
                                        : (item.status == StockStatus.rendah
                                            ? '⚠ Stok Menipis (${item.minThresholdPercentage}% dari min)'
                                            : '✕ Kritis (${item.minThresholdPercentage}% dari min)'),
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: progressColor,
                                    ),
                                  ),
                                  Text(
                                    'Batas Min: ${item.formattedMinStock}',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFFCBD5E1),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // ── 2. Executive Specification Sheet (Inset Grouped) ──
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFE2E8F0), width: 1.1),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF0F172A).withValues(alpha: 0.03),
                                blurRadius: 12,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              _buildSpecRow(
                                icon: Icons.hourglass_top_rounded,
                                title: 'Stok Minimum',
                                value: item.formattedMinStock,
                                subtitle: 'Batas peringatan restock',
                                isFirst: true,
                              ),
                              const Divider(height: 1, color: Color(0xFFF1F5F9), indent: 62),
                              _buildSpecRow(
                                icon: Icons.payments_outlined,
                                title: 'Estimasi Nilai Stok',
                                value: item.formattedTotalValue,
                                subtitle: '@ ${item.formattedCostPerUnit} / ${item.unit}',
                              ),
                              const Divider(height: 1, color: Color(0xFFF1F5F9), indent: 62),
                              _buildSpecRow(
                                icon: Icons.local_shipping_outlined,
                                title: 'Supplier Utama',
                                value: item.supplier.isNotEmpty ? item.supplier : 'Tidak Ditentukan',
                                subtitle: 'Mitra pengadaan terdaftar',
                              ),
                              const Divider(height: 1, color: Color(0xFFF1F5F9), indent: 62),
                              _buildSpecRow(
                                icon: Icons.schedule_rounded,
                                title: 'Terakhir Diperbarui',
                                value: _formatLastUpdated(item.lastUpdated),
                                subtitle: 'Pencatatan sinkronisasi otomatis',
                                isLast: true,
                              ),
                            ],
                          ),
                        ),

                        // ── 3. Linked Menu Section ────────────────────────────
                        if (item.linkedProducts.isNotEmpty) ...[
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(7),
                                ),
                                child: const Icon(
                                  Icons.restaurant_menu_rounded,
                                  size: 14,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Digunakan pada Menu (${item.linkedProducts.length})',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF0F172A),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: item.linkedProducts.map((menu) {
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
                                  boxShadow: [
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
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF22C55E),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 7),
                                    Text(
                                      menu,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF0F172A),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ],

                        const SizedBox(height: 22),

                        // ── 4. Riwayat Stok Section ───────────────────────────
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Riwayat Stok',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 16.5,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${filteredLogs.length} transaksi',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Filter Chips (Pills)
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          clipBehavior: Clip.none,
                          child: Row(
                            children: [
                              _buildFilterChip('Semua', null),
                              const SizedBox(width: 8),
                              _buildFilterChip('POS (Keluar)', StockLogType.out),
                              const SizedBox(width: 8),
                              _buildFilterChip('Restock', StockLogType.inStock),
                              const SizedBox(width: 8),
                              _buildFilterChip('Opname', StockLogType.adjustment),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Logs List / Clean Empty State
                        if (filteredLogs.isEmpty)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 26, horizontal: 20),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.02),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
                                  ),
                                  child: const Icon(
                                    Icons.receipt_long_outlined,
                                    size: 20,
                                    color: Color(0xFF94A3B8),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'Belum Ada Riwayat Stok',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Aktivitas penjualan kasir atau restock bahan akan otomatis tercatat di sini',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11.5,
                                    color: const Color(0xFF64748B),
                                    height: 1.3,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          )
                        else
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.02),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: filteredLogs.length,
                              separatorBuilder: (context, index) => const Divider(
                                height: 1,
                                color: Color(0xFFF1F5F9),
                                indent: 62,
                              ),
                              itemBuilder: (context, index) {
                                final log = filteredLogs[index];
                                return _buildLogTile(log);
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                // ── 5. Sticky Bottom Action Bar with SafeArea ──────────
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: const Border(
                      top: BorderSide(color: Color(0xFFE2E8F0), width: 1),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 14,
                        offset: const Offset(0, -3),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                      child: Row(
                        children: [
                          // Opname Button
                          Expanded(
                            flex: 2,
                            child: SizedBox(
                              height: 48,
                              child: OutlinedButton.icon(
                                onPressed: () => AdjustStockModal.show(context, item: item),
                                icon: const Icon(Icons.tune_rounded, size: 17),
                                label: const Text('Opname'),
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: const Color(0xFF0F172A),
                                  side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.1),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  textStyle: GoogleFonts.plusJakartaSans(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),

                          // Restock CTA (Solid Black)
                          Expanded(
                            flex: 3,
                            child: SizedBox(
                              height: 48,
                              child: ElevatedButton.icon(
                                onPressed: () => RestockModal.show(context, initialItem: item),
                                icon: const Icon(Icons.add_rounded, size: 18, color: Color(0xFF22C55E)),
                                label: const Text('Tambah Stok'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF111111),
                                  foregroundColor: Colors.white,
                                  elevation: 2,
                                  shadowColor: Colors.black.withValues(alpha: 0.2),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  textStyle: GoogleFonts.plusJakartaSans(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFilterChip(String label, StockLogType? type) {
    final isSelected = _historyFilter == type;
    return InkWell(
      onTap: () => setState(() => _historyFilter = type),
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF111111) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFF111111) : const Color(0xFFE2E8F0),
            width: 1,
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
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }

  Widget _buildSpecRow({
    required IconData icon,
    required String title,
    required String value,
    required String subtitle,
    bool isFirst = false,
    bool isLast = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Squircle icon container
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(11),
              border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
            ),
            child: Icon(icon, size: 18, color: const Color(0xFF0F172A)),
          ),
          const SizedBox(width: 12),

          // Title and Subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  subtitle,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Value
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 150),
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogTile(StockLog log) {
    IconData icon;
    Color iconBg;
    Color iconColor;
    Color deltaColor;

    switch (log.type) {
      case StockLogType.out:
        icon = Icons.arrow_downward_rounded;
        iconBg = const Color(0xFFFEE2E2);
        iconColor = const Color(0xFFDC2626);
        deltaColor = const Color(0xFFDC2626);
        break;
      case StockLogType.inStock:
        icon = Icons.arrow_upward_rounded;
        iconBg = const Color(0xFFDCFCE7);
        iconColor = const Color(0xFF16A34A);
        deltaColor = const Color(0xFF16A34A);
        break;
      case StockLogType.adjustment:
        icon = Icons.tune_rounded;
        iconBg = const Color(0xFFE0F2FE);
        iconColor = const Color(0xFF0284C7);
        deltaColor = const Color(0xFF0284C7);
        break;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Squircle Icon
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 12),

          // Source and Time
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      log.source,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    if (log.referenceCode != null) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          log.referenceCode!,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${log.formattedDate} • ${log.operatorName}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5,
                    color: const Color(0xFF64748B),
                  ),
                ),
                if (log.note != null && log.note!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    log.note!,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Delta amount
          Text(
            log.formattedQuantity,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
              color: deltaColor,
            ),
          ),
        ],
      ),
    );
  }

  String _formatLastUpdated(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 60) {
      return '${diff.inMinutes} mnt lalu';
    } else if (diff.inHours < 24 && now.day == dt.day) {
      final h = dt.hour.toString().padLeft(2, '0');
      final m = dt.minute.toString().padLeft(2, '0');
      return 'Hari ini, $h:$m';
    } else {
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
      final h = dt.hour.toString().padLeft(2, '0');
      final m = dt.minute.toString().padLeft(2, '0');
      return '${dt.day} ${months[dt.month - 1]}, $h:$m';
    }
  }

  void _confirmDelete(BuildContext context, StockItem item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          'Hapus Bahan Baku?',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Bahan ${item.name} beserta seluruh riwayat stoknya akan dihapus permanen.',
          style: GoogleFonts.plusJakartaSans(color: const Color(0xFF475569)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Batal',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w600,
                color: const Color(0xFF64748B),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              StockRepository.instance.deleteStockItem(item.id);
              Navigator.pop(ctx);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Bahan ${item.name} berhasil dihapus'),
                  backgroundColor: const Color(0xFFEF4444),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }
}
