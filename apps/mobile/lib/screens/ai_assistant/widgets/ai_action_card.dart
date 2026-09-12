import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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

  String _formatQty(double? qty) {
    if (qty == null) return '1';
    return (qty % 1 == 0) ? qty.toInt().toString() : qty.toString();
  }

  @override
  Widget build(BuildContext context) {
    final isConfirmed = payload.status == AiActionStatus.confirmed;

    if (isConfirmed) {
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.only(top: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF0FDF4),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFBBF7D0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  color: Color(0xFF16A34A),
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  'Tercatat di Stok & Keuangan',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF15803D),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    '${payload.itemName ?? 'Bahan'} (+${_formatQty(payload.quantity)} ${payload.unit ?? 'kg'})',
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1E293B),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (payload.expenseAmount != null) ...[
                  const SizedBox(width: 8),
                  Text(
                    FinanceRepository.formatRupiah(payload.expenseAmount!),
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.receipt_long_rounded,
                color: Color(0xFF111111),
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'Konfirmasi Pembelian Bahan',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '${payload.itemName ?? 'Bahan'} (+${_formatQty(payload.quantity)} ${payload.unit ?? 'kg'})',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF334155),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (payload.expenseAmount != null) ...[
                const SizedBox(width: 8),
                Text(
                  FinanceRepository.formatRupiah(payload.expenseAmount!),
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFE11D48),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton.icon(
              onPressed: onConfirm,
              icon: const Icon(
                Icons.check_circle_outline_rounded,
                size: 16,
                color: Colors.white,
              ),
              label: Text(
                'Konfirmasi & Catat Transaksi',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF111111),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
