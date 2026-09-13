import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/action_success_modal.dart';
import '../../../models/finance_model.dart';

/// Modal bottom sheet displaying detailed breakdown of a transaction.
class TransactionDetailModal extends StatelessWidget {
  final FinanceTransaction transaction;
  final VoidCallback? onDelete;

  const TransactionDetailModal({
    super.key,
    required this.transaction,
    this.onDelete,
  });

  static Future<void> show(
    BuildContext context, {
    required FinanceTransaction transaction,
    VoidCallback? onDelete,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TransactionDetailModal(
        transaction: transaction,
        onDelete: onDelete,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.type == TransactionType.income;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        16,
        24,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
          // Drag handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.lightTealBorder,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          // Icon avatar badge
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: isIncome ? AppColors.successBg : AppColors.dangerBg,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isIncome ? transaction.category.icon : Icons.shopping_bag_outlined,
              color: isIncome ? AppColors.successText : AppColors.dangerText,
              size: 28,
            ),
          ),
          const SizedBox(height: 12),

          // Order ID Pill & Title
          Builder(
            builder: (context) {
              final ordRegex = RegExp(r'ORD-\d{8}-\d{3}|ORD-\d+');
              final match = ordRegex.firstMatch(transaction.title) ??
                  (transaction.notes != null ? ordRegex.firstMatch(transaction.notes!) : null);
              final orderCode = match?.group(0) ??
                  (transaction.orderId != null && transaction.orderId!.isNotEmpty
                      ? (transaction.orderId!.startsWith('#') ? transaction.orderId! : '#${transaction.orderId}')
                      : null);

              final displayTitle = transaction.title.startsWith('Penjualan Kasir ORD-')
                  ? 'Penjualan Kasir POS'
                  : transaction.title;

              final isAlreadyRefunded = transaction.isRefundedOrder ||
                  FinanceRepository.instance.isOrderAlreadyRefunded(
                    orderId: transaction.orderId,
                    orderCode: transaction.orderCode,
                    title: transaction.title,
                    notes: transaction.notes,
                  );

              return Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (orderCode != null) ...[
                        Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            orderCode.startsWith('#') ? orderCode : '#$orderCode',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                        ),
                      ],
                      if (isAlreadyRefunded) ...[
                        const SizedBox(width: 8),
                        Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF1F2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFFECDD3), width: 1),
                          ),
                          child: Text(
                            'Di-refund',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFFE11D48),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  Text(
                    displayTitle,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.darkText,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 4),

          // Big Amount
          Text(
            transaction.formattedAmountWithSign,
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: isIncome ? AppColors.successText : AppColors.destructive,
            ),
          ),
          const SizedBox(height: 20),

          // Details Card
          Builder(
            builder: (context) {
              final cleanNotes = (transaction.notes ?? '')
                  .replaceAll(RegExp(r'Meja\s+Meja', caseSensitive: false), 'Meja')
                  .trim();

              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.tealBackgrounds,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.lightTealBorder, width: 1.1),
                ),
                child: Column(
                  children: [
                    _buildInfoRow('Tipe Transaksi',
                        isIncome ? 'Pemasukan (+)' : 'Pengeluaran (-)'),
                    Divider(
                      height: 20,
                      color: AppColors.lightTealBorder.withValues(alpha: 0.8),
                    ),
                    _buildInfoRow('Kategori', transaction.category.label),
                    Divider(
                      height: 20,
                      color: AppColors.lightTealBorder.withValues(alpha: 0.8),
                    ),
                    _buildInfoRow('Sumber', transaction.source.label),
                    Divider(
                      height: 20,
                      color: AppColors.lightTealBorder.withValues(alpha: 0.8),
                    ),
                    _buildInfoRow('Waktu Transaksi', transaction.formattedDateString),
                    if (cleanNotes.isNotEmpty) ...[
                      Divider(
                        height: 20,
                        color: AppColors.lightTealBorder.withValues(alpha: 0.8),
                      ),
                      _buildInfoRow('Catatan', cleanNotes),
                    ],
                  ],
                ),
              );
            },
          ),

          const SizedBox(height: 24),

          // Refund / Rollback Action Button (For POS Sales orders)
          Builder(
            builder: (context) {
              final isAlreadyRefunded = transaction.isRefundedOrder ||
                  FinanceRepository.instance.isOrderAlreadyRefunded(
                    orderId: transaction.orderId,
                    orderCode: transaction.orderCode,
                    title: transaction.title,
                    notes: transaction.notes,
                  );

              if (isAlreadyRefunded) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF1F2),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFFECDD3), width: 1.1),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFE4E6),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.check_circle_rounded,
                            color: Color(0xFFE11D48),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Pesanan Ini Sudah Di-Refund',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF9F1239),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Jurnal balik & rollback stok telah dicatat. Transaksi ini tidak dapat di-refund kembali.',
                                style: GoogleFonts.inter(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFFBE123C),
                                  height: 1.3,
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

              if ((transaction.orderId != null || transaction.source == TransactionSource.posAutomatic) &&
                  transaction.category != FinanceCategory.refund &&
                  transaction.type == TransactionType.income) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.assignment_return_rounded, size: 18),
                      label: Text(
                        'Batalkan & Refund Pesanan Ini',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFEF2F2),
                        foregroundColor: const Color(0xFFDC2626),
                        elevation: 0,
                        side: const BorderSide(color: Color(0xFFFECACA), width: 1.2),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () => _showRefundConfirmation(context),
                    ),
                  ),
                );
              }

              return const SizedBox.shrink();
            },
          ),

          // Action buttons
          Row(
            children: [
              if (onDelete != null) ...[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      onDelete?.call();
                    },
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      color: AppColors.destructive,
                      size: 18,
                    ),
                    label: Text(
                      'Hapus',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.destructive,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(
                        color: AppColors.destructive.withValues(alpha: 0.3),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryTeal,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    'Tutup',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

  void _showRefundConfirmation(BuildContext context) {
    final reasonController = TextEditingController();
    bool isProcessing = false;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setModalState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF1F2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.assignment_return_rounded, color: Color(0xFFE11D48), size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Batalkan Pesanan POS?',
                  style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pembatalan transaksi ini secara otomatis akan:',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildBullet('Mengembalikan kuantitas stok bahan resep ke inventaris.'),
                    _buildBullet('Mencatat jurnal balik pengeluaran (refund) di pembukuan.'),
                    _buildBullet('Mengubah status transaksi menjadi REFUNDED.'),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Alasan Pembatalan (Opsional)',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF475569),
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: reasonController,
                style: GoogleFonts.inter(fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Misal: Pelanggan salah pesan / batalkan',
                  hintStyle: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF94A3B8)),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF0D9488), width: 1.4),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isProcessing ? null : () => Navigator.pop(dialogCtx),
              child: Text(
                'Batal',
                style: GoogleFonts.inter(color: const Color(0xFF64748B), fontWeight: FontWeight.w600),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: isProcessing
                  ? null
                  : () async {
                      setModalState(() => isProcessing = true);
                      final targetOrderId = transaction.orderId ?? transaction.id;
                      try {
                        final success = await FinanceRepository.instance.refundOrder(
                          orderId: targetOrderId,
                          reason: reasonController.text.trim(),
                        );

                        if (context.mounted) {
                          Navigator.pop(dialogCtx);
                          Navigator.pop(context);

                          if (success) {
                            ActionSuccessModal.show(
                              context,
                              title: 'Transaksi Berhasil Dibatalkan',
                              subtitle: 'Stok bahan baku otomatis dikembalikan ke inventaris & jurnal pembalik kas berhasil dicatat.',
                              itemName: targetOrderId,
                              itemCategory: 'No. Pesanan',
                              quantityChange: 'Refund: ${transaction.formattedAmount}',
                              financialImpact: 'Kategori: Kasir POS',
                              statusBadge: 'Status: Dibatalkan',
                              itemIcon: Icons.receipt_long_rounded,
                            );
                          } else {
                            ActionSuccessModal.showNotice(
                              context,
                              title: 'Gagal Memproses Refund',
                              subtitle: 'Terjadi kendala saat menghubungi server atau memperbarui data pembukuan.',
                              itemName: targetOrderId,
                              itemCategory: 'No. Pesanan',
                              isError: true,
                            );
                          }
                        }
                      } catch (e) {
                        setModalState(() => isProcessing = false);
                        if (context.mounted) {
                          final errStr = e.toString().replaceAll('Exception: ', '');
                          final isAlreadyRefunded = errStr.contains('ORDER_ALREADY_REFUNDED') ||
                              errStr.toLowerCase().contains('sudah direfund') ||
                              errStr.toLowerCase().contains('sudah dibatalkan');
                          final message = isAlreadyRefunded
                              ? 'Pesanan ini sudah pernah di-refund sebelumnya. Tidak dapat di-refund ulang agar pembukuan tidak double.'
                              : 'Gagal memproses refund: $errStr';

                          Navigator.pop(dialogCtx);
                          ActionSuccessModal.showNotice(
                            context,
                            title: isAlreadyRefunded ? 'Pesanan Sudah Direfund' : 'Gagal Refund Pesanan',
                            subtitle: message,
                            itemName: targetOrderId,
                            itemCategory: 'No. Pesanan',
                            detailText: isAlreadyRefunded ? 'Sudah Diproses' : 'Gagal',
                            isError: true,
                          );
                        }
                      }
                    },
              child: isProcessing
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text('Konfirmasi Refund', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildBullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(color: Color(0xFF16A34A), fontWeight: FontWeight.bold)),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF475569)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            color: AppColors.mutedText,
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.darkText,
            ),
          ),
        ),
      ],
    );
  }
}
