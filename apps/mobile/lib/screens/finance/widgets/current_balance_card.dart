import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/finance_model.dart';

/// Hero card showing the current balance, last updated indicator,
/// and quick cashflow health badge in Neo-Clean obsidian styling.
class CurrentBalanceCard extends StatelessWidget {
  final double balance;
  final double netProfit;
  final VoidCallback? onTap;

  const CurrentBalanceCard({
    super.key,
    required this.balance,
    required this.netProfit,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isProfitable = netProfit >= 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
          width: 1,
        ),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'SALDO KAS UTAMA',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF94A3B8),
                  letterSpacing: 1.4,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
                decoration: BoxDecoration(
                  color: isProfitable
                      ? const Color(0xFFDCFCE7)
                      : const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isProfitable
                          ? Icons.trending_up_rounded
                          : Icons.trending_down_rounded,
                      size: 13,
                      color: isProfitable
                          ? const Color(0xFF16A34A)
                          : const Color(0xFFDC2626),
                    ),
                    const SizedBox(width: 4.5),
                    Text(
                      isProfitable ? 'Surplus' : 'Defisit',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: isProfitable
                            ? const Color(0xFF16A34A)
                            : const Color(0xFFDC2626),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Big Formatted Balance ─────────────────────────────────
          Text(
            FinanceRepository.formatRupiah(balance),
            style: GoogleFonts.plusJakartaSans(
              fontSize: 34,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.8,
              height: 1.1,
            ),
          ),

          const SizedBox(height: 16),

          // ── Update Time & Subtitle ────────────────────────────────
          Row(
            children: [
              const Icon(
                Icons.access_time_rounded,
                size: 13,
                color: Color(0xFF94A3B8),
              ),
              const SizedBox(width: 5),
              Text(
                'Diperbarui hari ini',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF94A3B8),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Laba Bersih: ${FinanceRepository.formatRupiah(netProfit)}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: isProfitable
                        ? const Color(0xFF22C55E)
                        : const Color(0xFFF87171),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
