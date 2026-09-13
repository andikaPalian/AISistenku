import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/services/offline_sync_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/finance_model.dart';
import '../../finance/widgets/transaction_detail_modal.dart';
import 'add_edit_product_modal.dart';
import 'offline_sync_modal.dart';

/// POS screen header with title, subtitle, "+ Menu Baru" button, and transaction history button.
/// Strictly uses authentic brand colors (#0D9488, #CCFBF1, #F8FFFE, #0F172A).
class PosHeader extends StatelessWidget {
  const PosHeader({super.key});

  void _showOrderHistory(BuildContext context) {
    int selectedFilter = 0; // 0: Semua Pesanan, 1: Selesai, 2: Refund, 3: Semua Transaksi

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (bottomSheetCtx, setSheetState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.78,
              minChildSize: 0.45,
              maxChildSize: 0.94,
              expand: false,
              builder: (_, scrollController) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 44,
                          height: 4,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE2E8F0), // Clean slate handle
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Header Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryTeal.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.receipt_long_rounded,
                                  color: AppColors.primaryTeal,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Riwayat Pesanan Kasir',
                                    style: GoogleFonts.poppins(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.darkText,
                                    ),
                                  ),
                                  Text(
                                    'Pantau transaksi & kelola refund pesanan',
                                    style: GoogleFonts.inter(
                                      fontSize: 11.5,
                                      color: AppColors.mutedText,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, color: AppColors.mutedText),
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Quick Metrics Summary Banner
                      ListenableBuilder(
                        listenable: FinanceRepository.instance,
                        builder: (context, _) {
                          final allTx = FinanceRepository.instance.transactions;
                          final posOrders = allTx.where((t) =>
                              t.source == TransactionSource.posAutomatic ||
                              t.category == FinanceCategory.sales ||
                              t.category == FinanceCategory.refund).toList();

                          final totalCompletedOrders = posOrders
                              .where((t) => t.type == TransactionType.income)
                              .length;
                          final totalOmset = posOrders
                              .where((t) => t.type == TransactionType.income)
                              .fold<double>(0.0, (sum, t) => sum + t.amount);

                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: AppColors.successBg,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(
                                        Icons.payments_outlined,
                                        size: 16,
                                        color: AppColors.successText,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Omset Kasir Terkini',
                                          style: GoogleFonts.inter(
                                            fontSize: 11,
                                            color: AppColors.mutedText,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        Text(
                                          FinanceRepository.formatRupiah(totalOmset),
                                          style: GoogleFonts.poppins(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.darkText,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0F172A),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    '$totalCompletedOrders Pesanan Selesai',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 12),

                      // Segmented Filter Pills
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: Row(
                          children: [
                            _buildFilterPill(
                              label: 'Semua Pesanan',
                              isSelected: selectedFilter == 0,
                              onTap: () => setSheetState(() => selectedFilter = 0),
                            ),
                            const SizedBox(width: 8),
                            _buildFilterPill(
                              label: 'Selesai',
                              isSelected: selectedFilter == 1,
                              onTap: () => setSheetState(() => selectedFilter = 1),
                            ),
                            const SizedBox(width: 8),
                            _buildFilterPill(
                              label: 'Refund / Batal',
                              isSelected: selectedFilter == 2,
                              onTap: () => setSheetState(() => selectedFilter = 2),
                            ),
                            const SizedBox(width: 8),
                            _buildFilterPill(
                              label: 'Semua Transaksi',
                              isSelected: selectedFilter == 3,
                              onTap: () => setSheetState(() => selectedFilter = 3),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      // List of Transactions
                      Expanded(
                        child: ListenableBuilder(
                          listenable: FinanceRepository.instance,
                          builder: (context, _) {
                            final allTx = FinanceRepository.instance.transactions;
                            if (allTx.isEmpty) {
                              return _buildEmptyState(
                                'Belum Ada Transaksi',
                                'Transaksi kasir yang telah selesai akan tercatat di sini.',
                              );
                            }

                            List<FinanceTransaction> filteredList;
                            if (selectedFilter == 0) {
                              filteredList = allTx.where((t) =>
                                  t.source == TransactionSource.posAutomatic ||
                                  t.category == FinanceCategory.sales ||
                                  t.category == FinanceCategory.refund).toList();
                            } else if (selectedFilter == 1) {
                              filteredList = allTx.where((t) =>
                                  t.type == TransactionType.income &&
                                  (t.source == TransactionSource.posAutomatic || t.category == FinanceCategory.sales)).toList();
                            } else if (selectedFilter == 2) {
                              filteredList = allTx.where((t) => t.category == FinanceCategory.refund).toList();
                            } else {
                              filteredList = allTx.toList();
                            }

                            if (filteredList.isEmpty) {
                              return _buildEmptyState(
                                'Tidak Ada Data',
                                selectedFilter == 2
                                    ? 'Belum ada pesanan kasir yang dibatalkan / refund.'
                                    : 'Tidak ada transaksi dengan filter ini.',
                              );
                            }

                            final reversedList = filteredList.reversed.toList();
                            return ListView.builder(
                              controller: scrollController,
                              physics: const BouncingScrollPhysics(),
                              itemCount: reversedList.length,
                              itemBuilder: (context, index) {
                                final tx = reversedList[index];
                                return _buildHistoryCard(
                                  context: context,
                                  parentCtx: ctx,
                                  tx: tx,
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildFilterPill({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String title, String subtitle) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 44,
              color: AppColors.mutedText.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.darkText,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.mutedText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryCard({
    required BuildContext context,
    required BuildContext parentCtx,
    required FinanceTransaction tx,
  }) {
    final isIncome = tx.type == TransactionType.income;
    final isRefund = tx.category == FinanceCategory.refund;

    // Clean Order / Transaction ID resolution
    String displayId;
    final ordRegex = RegExp(r'ORD-\d{8}-\d{3}|ORD-\d+');
    final matchInTitle = ordRegex.firstMatch(tx.title);
    final matchInNotes = tx.notes != null ? ordRegex.firstMatch(tx.notes!) : null;

    if (matchInTitle != null) {
      displayId = '#${matchInTitle.group(0)}';
    } else if (matchInNotes != null) {
      displayId = '#${matchInNotes.group(0)}';
    } else if (tx.orderId != null && tx.orderId!.isNotEmpty) {
      final clean = tx.orderId!.replaceAll('#', '');
      displayId = '#${clean.length > 12 ? clean.substring(0, 10).toUpperCase() : clean}';
    } else if (tx.id.length > 12) {
      displayId = '#${tx.id.substring(0, 8).toUpperCase()}';
    } else {
      displayId = '#${tx.id.toUpperCase()}';
    }

    // Clean Title and Subtitle formatting
    String mainTitle = tx.title;
    String? subTitle = tx.notes;

    if (mainTitle.startsWith('Penjualan Kasir ORD-')) {
      if (tx.notes != null && tx.notes!.isNotEmpty) {
        mainTitle = tx.notes!;
        subTitle = 'Kasir POS Otomatis';
      } else {
        mainTitle = 'Penjualan Kasir';
      }
    }

    // Determine Order Tag (Dine In / Take Away / etc)
    String? orderTag;
    final lowerNotes = (tx.notes ?? '').toLowerCase();
    final lowerTitle = tx.title.toLowerCase();
    if (lowerNotes.contains('takeaway') || lowerNotes.contains('take away') || lowerTitle.contains('takeaway')) {
      orderTag = 'Take Away';
    } else if (lowerNotes.contains('dinein') || lowerNotes.contains('dine in') || lowerTitle.contains('dinein')) {
      final tableMatch = RegExp(r'meja\s*(\w+)', caseSensitive: false).firstMatch(tx.notes ?? '');
      if (tableMatch != null) {
        orderTag = 'Dine In • Meja ${tableMatch.group(1)}';
      } else {
        orderTag = 'Dine In';
      }
    } else if (tx.source == TransactionSource.posAutomatic) {
      orderTag = 'POS';
    }

    final isOrderRefunded = isRefund ||
        tx.isRefundedOrder ||
        FinanceRepository.instance.isOrderAlreadyRefunded(
          orderId: tx.orderId,
          orderCode: tx.orderCode,
          title: tx.title,
          notes: tx.notes,
        );

    final badgeText = isOrderRefunded
        ? 'Dibatalkan'
        : (isIncome ? 'Selesai' : tx.category.label);
    final badgeBg = isOrderRefunded
        ? const Color(0xFFFFF1F2)
        : (isIncome ? AppColors.successBg : const Color(0xFFF1F5F9));
    final badgeColor = isOrderRefunded
        ? const Color(0xFFE11D48)
        : (isIncome ? AppColors.successText : const Color(0xFF475569));

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.pop(parentCtx);
          TransactionDetailModal.show(context, transaction: tx);
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFF1F5F9), width: 1.1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 14,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top ID & Badges Row (Guarded against overflow)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            displayId,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.darkText,
                            ),
                          ),
                        ),
                        if (orderTag != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              orderTag,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF475569),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                    decoration: BoxDecoration(
                      color: badgeBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      badgeText,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: badgeColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Title
              Text(
                mainTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 13.5,
                  color: AppColors.darkText,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (subTitle != null && subTitle.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  subTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.mutedText,
                  ),
                ),
              ],
              const SizedBox(height: 10),

              // Footer with Date and Amount
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(
                          Icons.access_time_rounded,
                          size: 13,
                          color: AppColors.mutedText,
                        ),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            tx.formattedDateString,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppColors.mutedText,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        tx.formattedAmountWithSign,
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: isRefund
                              ? AppColors.destructive
                              : (isIncome ? AppColors.darkText : AppColors.destructive),
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.chevron_right_rounded,
                        size: 16,
                        color: AppColors.mutedText,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Store info row with Rating Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tiga Angkatan - Kartasura',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.darkText,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Outlet Utama • Siap Saji 15 Menit',
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        color: AppColors.mutedText,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              // Rating Badge Pill (★ 4.9) matching Screen 2
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFF111111), // Dark Pill
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star_rounded, color: Color(0xFFFBBF24), size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '4.9',
                      style: GoogleFonts.poppins(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Action row (+ Menu Baru, Riwayat, & Offline Sync)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                // + Menu Baru pill button
                GestureDetector(
                  onTap: () => AddEditProductModal.show(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: const Color(0xFF111111),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.add_rounded, color: Colors.white, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          'Tambah Menu',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Riwayat Transaksi pill button
                GestureDetector(
                  onTap: () => _showOrderHistory(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.history_rounded, color: Color(0xFF0F172A), size: 16),
                        const SizedBox(width: 4),
                        Text(
                          'Riwayat Hari Ini',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Offline Sync Status Indicator Pill
                ListenableBuilder(
                  listenable: OfflineSyncService.instance,
                  builder: (context, _) {
                    final sync = OfflineSyncService.instance;
                    final pending = sync.pendingCount;
                    final isOnline = sync.isOnline;
                    final isSyncing = sync.isSyncing;

                    Color bg = const Color(0xFFF0FDF4);
                    Color fg = const Color(0xFF16A34A);
                    IconData icon = Icons.cloud_done_rounded;
                    String label = 'Tersinkron';

                    if (isSyncing) {
                      bg = const Color(0xFFE0F2FE);
                      fg = const Color(0xFF0369A1);
                      icon = Icons.sync_rounded;
                      label = 'Sinkron...';
                    } else if (pending > 0) {
                      bg = const Color(0xFFFEF9C3);
                      fg = const Color(0xFF854D0E);
                      icon = Icons.cloud_upload_rounded;
                      label = '$pending Offline';
                    } else if (!isOnline) {
                      bg = const Color(0xFFFEF2F2);
                      fg = const Color(0xFFDC2626);
                      icon = Icons.wifi_off_rounded;
                      label = 'Offline';
                    }

                    return GestureDetector(
                      onTap: () => OfflineSyncModal.show(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: bg,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: pending > 0
                                ? const Color(0xFFFDE047)
                                : (!isOnline ? const Color(0xFFFECACA) : const Color(0xFFBBF7D0)),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(icon, color: fg, size: 15),
                            const SizedBox(width: 5),
                            Text(
                              label,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: fg,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
