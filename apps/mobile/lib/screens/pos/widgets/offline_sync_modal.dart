import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/services/offline_sync_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/action_success_modal.dart';
import '../../../models/product.dart';

/// Modal bottom sheet to inspect offline cached orders, monitor sync status,
/// and manually flush pending transactions when cafe Wi-Fi is restored.
class OfflineSyncModal extends StatefulWidget {
  const OfflineSyncModal({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const OfflineSyncModal(),
    );
  }

  @override
  State<OfflineSyncModal> createState() => _OfflineSyncModalState();
}

class _OfflineSyncModalState extends State<OfflineSyncModal> {
  final OfflineSyncService _syncService = OfflineSyncService.instance;

  @override
  void initState() {
    super.initState();
    _syncService.addListener(_onStateChanged);
    // Probe server connection upon opening modal
    _syncService.checkConnectivityAndAutoFlush();
  }

  @override
  void dispose() {
    _syncService.removeListener(_onStateChanged);
    super.dispose();
  }

  void _onStateChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _handleManualSync() async {
    final res = await _syncService.flushPendingOrders(force: true);
    if (!mounted) return;

    if (res.syncedCount > 0) {
      ActionSuccessModal.show(
        context,
        title: 'Sinkronisasi Berhasil',
        subtitle: '${res.syncedCount} transaksi offline kasir berhasil diunggah dan diverifikasi di server cloud.',
        itemName: '${res.syncedCount} Pesanan Kasir',
        itemCategory: 'Antrean Offline',
        quantityChange: 'Tersinkron',
        financialImpact: 'Server Cloud Aktif',
        statusBadge: 'Status 200 OK',
        itemIcon: Icons.cloud_done_rounded,
      );
    } else {
      ActionSuccessModal.showNotice(
        context,
        title: 'Status Sinkronisasi',
        subtitle: res.message,
        itemCategory: 'Offline Sync',
        isError: false,
        heroIcon: Icons.cloud_sync_rounded,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final allOrders = _syncService.allOrders;
    final pendingCount = _syncService.pendingCount;
    final isOnline = _syncService.isOnline;
    final isSyncing = _syncService.isSyncing;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Drag handle
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 8),
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header Row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF111111),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.cloud_sync_rounded, color: Colors.white, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Antrean Pesanan Offline',
                                style: GoogleFonts.poppins(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.darkText,
                                ),
                              ),
                              Text(
                                'Penyimpanan lokal Hive & auto-sync',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: AppColors.mutedText,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 22),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE2E8F0)),

            // Scrollable Content
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // 1. Connection Status Banner
                  _buildConnectionBanner(isOnline, isSyncing),
                  const SizedBox(height: 16),

                  // 2. Summary KPI Counter Cards
                  _buildKpiRow(pendingCount, _syncService.syncedOrders.length),
                  const SizedBox(height: 20),

                  // 3. Section Title & Action
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Daftar Transaksi Tersimpan (${allOrders.length})',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.darkText,
                        ),
                      ),
                      if (_syncService.syncedOrders.isNotEmpty)
                        InkWell(
                          onTap: () async {
                            await _syncService.clearSyncedOrders();
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            child: Text(
                              'Bersihkan Riwayat',
                              style: GoogleFonts.inter(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF64748B),
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // 4. List of Orders or Empty State
                  if (allOrders.isEmpty)
                    _buildEmptyState()
                  else
                    ...allOrders.map((item) => _buildOrderCard(item)),
                ],
              ),
            ),

            // Bottom Actions: Flush Now
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    offset: const Offset(0, -4),
                    blurRadius: 16,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: (isSyncing || pendingCount == 0) ? null : _handleManualSync,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF111111),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: const Color(0xFFE2E8F0),
                        disabledForegroundColor: const Color(0xFF94A3B8),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      icon: isSyncing
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.cloud_upload_rounded, size: 20),
                      label: Text(
                        isSyncing
                            ? 'Menyinkronkan ke Server...'
                            : pendingCount > 0
                                ? 'Sinkronkan $pendingCount Pesanan Sekarang'
                                : 'Semua Pesanan Sudah Tersinkron',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
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
  }

  Widget _buildConnectionBanner(bool isOnline, bool isSyncing) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isOnline ? const Color(0xFFF0FDF4) : const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isOnline ? const Color(0xFFBBF7D0) : const Color(0xFFFECACA),
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isOnline ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isOnline ? Icons.wifi_rounded : Icons.wifi_off_rounded,
              size: 20,
              color: isOnline ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isOnline ? 'Server Backend Terhubung' : 'Wi-Fi / Internet Terputus (Offline)',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isOnline ? const Color(0xFF15803D) : const Color(0xFFB91C1C),
                  ),
                ),
                Text(
                  isOnline
                      ? (isSyncing ? 'Sedang melakukan background sync...' : 'Pesanan baru langsung tersinkron secara realtime')
                      : 'Transaksi kasir disimpan lokal di Hive dan dicetak via thermal Bluetooth',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: isOnline ? const Color(0xFF166534) : const Color(0xFF991B1B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiRow(int pendingCount, int syncedCount) {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: pendingCount > 0 ? const Color(0xFFFEF9C3) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: pendingCount > 0 ? const Color(0xFFFDE047) : const Color(0xFFE2E8F0),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Menunggu',
                      style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF854D0E)),
                    ),
                    Icon(Icons.hourglass_top_rounded, size: 16, color: pendingCount > 0 ? const Color(0xFFCA8A04) : const Color(0xFF94A3B8)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '$pendingCount Pesanan',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: pendingCount > 0 ? const Color(0xFF713F12) : const Color(0xFF334155),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFBBF7D0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Tersinkron',
                      style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF166534)),
                    ),
                    const Icon(Icons.cloud_done_rounded, size: 16, color: Color(0xFF16A34A)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '$syncedCount Pesanan',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF14532D),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      alignment: Alignment.center,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.inventory_2_outlined, size: 36, color: Color(0xFF94A3B8)),
          ),
          const SizedBox(height: 14),
          Text(
            'Belum Ada Antrean Offline',
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.darkText,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Jika koneksi Wi-Fi terputus saat transaksi, pesanan kasir akan otomatis tercatat rapi di sini.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 12, color: AppColors.mutedText),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(OfflineOrder item) {
    final order = item.orderRecord;
    final isSynced = item.isSynced;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSynced ? const Color(0xFFE2E8F0) : const Color(0xFFFDE047),
          width: isSynced ? 1 : 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order Code & Status Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    item.syncStatus.icon,
                    size: 16,
                    color: item.syncStatus.color,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    order.orderCode,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.darkText,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: item.syncStatus.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  item.syncStatus.label,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: item.syncStatus.color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Items summary
          Text(
            order.items.map((it) => '${it.quantity}x ${it.product.name}').join(', '),
            style: GoogleFonts.inter(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: AppColors.darkText,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),

          // Details row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${order.paymentMethod.label} • ${order.orderType.label}${order.tableNumber != null ? " (${order.tableNumber})" : ""}',
                style: GoogleFonts.inter(fontSize: 11.5, color: AppColors.mutedText),
              ),
              Text(
                Product.formatRupiah(order.total),
                style: GoogleFonts.poppins(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.darkText,
                ),
              ),
            ],
          ),

          if (item.lastError != null && !isSynced) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded, size: 14, color: Color(0xFFDC2626)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Percobaan #${item.retryCount}: ${_formatErrorMessage(item.lastError)}',
                      style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF991B1B)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatErrorMessage(String? raw) {
    if (raw == null) return 'Terjadi kesalahan jaringan';
    if (raw.contains('message:')) {
      final match = RegExp(r'message:\s*([^,}]+)').firstMatch(raw);
      if (match != null && match.group(1) != null) {
        return match.group(1)!.trim();
      }
    }
    return raw.replaceAll('Exception: ', '').trim();
  }
}
