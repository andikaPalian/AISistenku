import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../models/stock_model.dart';
import 'widgets/restock_modal.dart';
import 'widgets/adjust_stock_modal.dart';
import 'widgets/add_stock_modal.dart';

/// Comprehensive Stock Detail and Movement History Screen.
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
            appBar: AppBar(title: const Text('Bahan Baku')),
            body: const Center(child: Text('Data bahan baku tidak ditemukan')),
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

        switch (status) {
          case StockStatus.kritis:
            statusLabel = 'Kritis';
            statusBg = Colors.white;
            statusText = AppColors.destructive;
            statusIcon = Icons.error_outline_rounded;
            break;
          case StockStatus.rendah:
            statusLabel = 'Rendah';
            statusBg = Colors.white;
            statusText = AppColors.warningOrange;
            statusIcon = Icons.warning_amber_rounded;
            break;
          case StockStatus.baik:
            statusLabel = 'Aman';
            statusBg = Colors.white;
            statusText = AppColors.successGreen;
            statusIcon = Icons.check_circle_outline_rounded;
            break;
        }

        return Scaffold(
          backgroundColor: AppColors.pageBackground,
          appBar: AppBar(
            backgroundColor: AppColors.background,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: AppColors.darkText),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              item.name,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.darkText,
              ),
            ),
            centerTitle: true,
            actions: [
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded, color: AppColors.darkText),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
                        Icon(Icons.edit_outlined, size: 18, color: AppColors.darkText),
                        SizedBox(width: 10),
                        Text('Ubah Detail Bahan'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'adjust',
                    child: Row(
                      children: [
                        Icon(Icons.tune_rounded, size: 18, color: AppColors.infoBlue),
                        SizedBox(width: 10),
                        Text('Penyesuaian Opname'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.destructive),
                        SizedBox(width: 10),
                        Text('Hapus Bahan', style: TextStyle(color: AppColors.destructive)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── 1. Hero Teal Card (Matching Reference Design) ──
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFF115E59), // Rich Deep Teal
                                Color(0xFF0F766E),
                                Color(0xFF134E4A),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF0D9488).withValues(alpha: 0.3),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                'STOK SAAT INI',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFFCCFBF1),
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                item.formattedCurrentStock,
                                style: GoogleFonts.poppins(
                                  fontSize: 42,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  height: 1.1,
                                ),
                              ),
                              const SizedBox(height: 14),

                              // Status Badge
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                decoration: BoxDecoration(
                                  color: statusBg,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.12),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(statusIcon, color: statusText, size: 16),
                                    const SizedBox(width: 6),
                                    Text(
                                      statusLabel,
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: statusText,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 16),

                              // AI Depletion Insight Callout
                              if (status != StockStatus.baik)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.white.withValues(alpha: 0.2),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.auto_awesome,
                                        color: Color(0xFF5EEAD4),
                                        size: 16,
                                      ),
                                      const SizedBox(width: 8),
                                      Flexible(
                                        child: Text(
                                          status == StockStatus.kritis
                                              ? 'Perkiraan habis dlm ~1 hari. Perlu restock segera!'
                                              : 'Perkiraan cukup untuk ~2 hari ke depan.',
                                          style: GoogleFonts.inter(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
                                            color: const Color(0xFFF0FDFA),
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),

                        // ── 2. Metric Sub-Cards Grid (2x2) ──
                        Row(
                          children: [
                            Expanded(
                              child: _buildInfoCard(
                                icon: Icons.hourglass_top_rounded,
                                title: 'Stok Minimum',
                                value: item.formattedMinStock,
                                subtitle: 'Batas peringatan',
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildInfoCard(
                                icon: Icons.schedule_rounded,
                                title: 'Terakhir Diperbarui',
                                value: _formatLastUpdated(item.lastUpdated),
                                subtitle: 'Update otomatis',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildInfoCard(
                                icon: Icons.payments_outlined,
                                title: 'Estimasi Nilai Stok',
                                value: item.formattedTotalValue,
                                subtitle: '@ ${item.formattedCostPerUnit}/${item.unit}',
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildInfoCard(
                                icon: Icons.local_shipping_outlined,
                                title: 'Supplier Utama',
                                value: item.supplier,
                                subtitle: 'Mitra langganan',
                                isSingleLine: true,
                              ),
                            ),
                          ],
                        ),

                        // ── 3. Linked Menu / Recipes Section ──
                        if (item.linkedProducts.isNotEmpty) ...[
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              const Icon(Icons.coffee_maker_rounded, size: 18, color: AppColors.primaryTeal),
                              const SizedBox(width: 8),
                              Text(
                                'Digunakan pada Menu POS',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.darkText,
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
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9), // Slate 100
                                  borderRadius: BorderRadius.circular(10),
                                  // No border
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.check_circle,
                                      size: 14,
                                      color: AppColors.primaryTeal,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      menu,
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.darkText,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ],

                        const SizedBox(height: 26),

                        // ── 4. Riwayat Stok Section (Stock Movement History) ──
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Riwayat Stok',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: AppColors.darkText,
                              ),
                            ),
                            Text(
                              '${filteredLogs.length} transaksi',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AppColors.mutedText,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // History Filter Chips
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _buildFilterChip('Semua', null),
                              const SizedBox(width: 8),
                              _buildFilterChip('Keluar (POS)', StockLogType.out),
                              const SizedBox(width: 8),
                              _buildFilterChip('Masuk (Restock)', StockLogType.inStock),
                              const SizedBox(width: 8),
                              _buildFilterChip('Penyesuaian', StockLogType.adjustment),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Logs List Container
                        if (filteredLogs.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(28),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              // No border
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.03),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                const Icon(
                                  Icons.history_toggle_off_rounded,
                                  size: 36,
                                  color: AppColors.mutedText,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Belum ada riwayat untuk filter ini',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: AppColors.mutedText,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              // No border
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: filteredLogs.length,
                              separatorBuilder: (context, index) => const Divider(
                                height: 1,
                                color: Color(0xFFE2E8F0),
                                indent: 64,
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

                // ── 5. Sticky Bottom Action Bar ──
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 16,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Opname Button
                      Expanded(
                        flex: 2,
                        child: SizedBox(
                          height: 50,
                          child: TextButton.icon(
                            onPressed: () => AdjustStockModal.show(context, item: item),
                            icon: const Icon(Icons.tune_rounded, size: 18),
                            label: const Text('Opname'),
                            style: TextButton.styleFrom(
                              backgroundColor: const Color(0xFFF1F5F9), // Slate
                              foregroundColor: AppColors.darkText,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              textStyle: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Restock CTA
                      Expanded(
                        flex: 3,
                        child: SizedBox(
                          height: 50,
                          child: ElevatedButton.icon(
                            onPressed: () => RestockModal.show(context, initialItem: item),
                            icon: const Icon(Icons.add_rounded, size: 20, color: Colors.white),
                            label: const Text('Tambah Stok'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0F172A), // Dark Slate
                              foregroundColor: Colors.white,
                              elevation: 6,
                              shadowColor: const Color(0xFF0F172A).withValues(alpha: 0.4),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              textStyle: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
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

  Widget _buildFilterChip(String label, StockLogType? type) {
    final isSelected = _historyFilter == type;
    return InkWell(
      onTap: () => setState(() => _historyFilter = type),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryTeal : const Color(0xFFF1F5F9), // Slate 100
          borderRadius: BorderRadius.circular(20),
          // No border
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

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
    required String subtitle,
    bool isSingleLine = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        // No border
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: AppColors.primaryTeal),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.mutedText,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.darkText,
            ),
            maxLines: isSingleLine ? 1 : 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: AppColors.mutedText,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
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
        icon = Icons.point_of_sale_rounded;
        iconBg = AppColors.dangerBg;
        iconColor = AppColors.destructive;
        deltaColor = AppColors.destructive;
        break;
      case StockLogType.inStock:
        icon = Icons.inventory_2_rounded;
        iconBg = AppColors.successBg;
        iconColor = AppColors.successGreen;
        deltaColor = AppColors.successGreen;
        break;
      case StockLogType.adjustment:
        icon = Icons.tune_rounded;
        iconBg = AppColors.infoBg;
        iconColor = AppColors.infoBlue;
        deltaColor = AppColors.infoText;
        break;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          // Icon Circle
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBg,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 14),

          // Source and Time
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      log.source,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.darkText,
                      ),
                    ),
                    if (log.referenceCode != null) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          log.referenceCode!,
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: AppColors.mutedText,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${log.formattedDate} • ${log.operatorName}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.mutedText,
                  ),
                ),
                if (log.note != null && log.note!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    log.note!,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                      color: AppColors.mutedText,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Delta amount
          Text(
            log.formattedQuantity,
            style: GoogleFonts.poppins(
              fontSize: 15,
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
        title: const Text('Hapus Bahan Baku?'),
        content: Text(
          'Bahan ${item.name} beserta seluruh riwayat stoknya akan dihapus permanen.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              StockRepository.instance.deleteStockItem(item.id);
              Navigator.pop(ctx);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Bahan ${item.name} berhasil dihapus'),
                  backgroundColor: AppColors.destructive,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.destructive),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }
}
