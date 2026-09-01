import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
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
        MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFCBD5E1),
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

          // Title
          Text(
            transaction.title,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.darkText,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),

          // Big Amount
          Text(
            transaction.formattedAmountWithSign,
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: isIncome ? AppColors.successText : const Color(0xFFEF4444),
            ),
          ),
          const SizedBox(height: 20),

          // Details Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                _buildInfoRow('Tipe Transaksi',
                    isIncome ? 'Pemasukan (+)' : 'Pengeluaran (-)'),
                const Divider(height: 20, color: Color(0xFFE2E8F0)),
                _buildInfoRow('Kategori', transaction.category.label),
                const Divider(height: 20, color: Color(0xFFE2E8F0)),
                _buildInfoRow('Sumber', transaction.source.label),
                const Divider(height: 20, color: Color(0xFFE2E8F0)),
                _buildInfoRow('Waktu Transaksi', transaction.formattedDateString),
                if (transaction.notes != null) ...[
                  const Divider(height: 20, color: Color(0xFFE2E8F0)),
                  _buildInfoRow('Catatan', transaction.notes!),
                ],
              ],
            ),
          ),

          const SizedBox(height: 24),

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
                      side: const BorderSide(color: Color(0xFFFECACA)),
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
            color: const Color(0xFF64748B),
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
