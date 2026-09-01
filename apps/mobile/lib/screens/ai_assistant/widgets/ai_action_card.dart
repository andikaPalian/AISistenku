import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/ai_chat_model.dart';
import '../../../models/finance_model.dart';

/// Card for detected purchase/expense actions with one-tap confirmation.
///
/// Seamlessly updates both Stock and Finance modules upon confirmation.
class AiActionCard extends StatelessWidget {
  final AiActionPayload payload;
  final VoidCallback? onConfirm;

  const AiActionCard({
    super.key,
    required this.payload,
    this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final isConfirmed = payload.status == AiActionStatus.confirmed;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isConfirmed ? const Color(0xFFF0FDF4) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isConfirmed
              ? const Color(0xFF86EFAC)
              : const Color(0xFF99F6E4),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Icon
          Row(
            children: [
              Icon(
                isConfirmed
                    ? Icons.check_circle_rounded
                    : Icons.receipt_long_rounded,
                color: isConfirmed
                    ? AppColors.successText
                    : AppColors.darkText,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                isConfirmed ? 'Aksi Berhasil' : 'Pembelian dideteksi',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: isConfirmed
                      ? AppColors.successText
                      : AppColors.darkText,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Data Detail Box
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isConfirmed ? Colors.white : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isConfirmed
                    ? const Color(0xFFDCFCE7)
                    : const Color(0xFFE2E8F0),
              ),
            ),
            child: Column(
              children: [
                if (payload.itemName != null) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Item',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                      Text(
                        '${payload.itemName} +${payload.quantity?.toStringAsFixed(0) ?? '1'} ${payload.unit ?? 'kg'}',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.darkText,
                        ),
                      ),
                    ],
                  ),
                ],
                if (payload.expenseAmount != null) ...[
                  const Divider(height: 14, color: Color(0xFFE2E8F0)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Expense',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                      Text(
                        FinanceRepository.formatRupiah(
                          payload.expenseAmount!,
                        ),
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFEF4444),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Action Button or Confirmation Note
          if (!isConfirmed) ...[
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                onPressed: onConfirm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F766E),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Confirm Record',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ] else ...[
            Row(
              children: [
                const Icon(
                  Icons.sync_rounded,
                  size: 14,
                  color: AppColors.successText,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Stok bertambah dan pengeluaran tercatat di Keuangan.',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.successText,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
