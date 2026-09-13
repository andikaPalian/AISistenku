import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Card providing AI-driven business and financial advisory for UMKM owners in Neo-Clean design.
class AiFinanceInsightCard extends StatelessWidget {
  final double grossMargin;
  final VoidCallback? onConsultTap;

  const AiFinanceInsightCard({
    super.key,
    required this.grossMargin,
    this.onConsultTap,
  });

  @override
  Widget build(BuildContext context) {
    final isPositive = grossMargin >= 0;
    final badgeBg = isPositive ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2);
    final badgeTextColor = isPositive ? const Color(0xFF16A34A) : const Color(0xFFDC2626);
    final badgeLabel = isPositive
        ? 'Margin: ${grossMargin.toStringAsFixed(1)}%'
        : 'Defisit: ${grossMargin.abs().toStringAsFixed(1)}%';

    final adviceText = isPositive
        ? 'Laba kotor operasional Anda stabil di ${grossMargin.toStringAsFixed(0)}%. Penjualan Iced Latte meningkat signifikan. Disarankan membuat paket bundling "Kopi + Snack" di jam 15:00-17:00 untuk menaikkan rata-rata transaksi (AOV).'
        : 'Pengeluaran bahan baku saat ini melampaui omzet tercatat (pengadaan stok biji kopi). Optimalkan penjualan di jam sibuk sore untuk memulihkan margin laba harian.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        gradient: const LinearGradient(
          colors: [Color(0xFFF0FDFA), Colors.white],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: [0.0, 0.45],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFCCFBF1),
          width: 1.2,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x080D9488),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Image.asset(
                  'assets/icons/logoAisitenku.png',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.auto_awesome_rounded,
                    color: Color(0xFF14B8A6),
                    size: 16,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'AIsisten Rekomendasi Bisnis',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F172A),
                    letterSpacing: -0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  badgeLabel,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: badgeTextColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            adviceText,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF334155),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              onPressed: onConsultTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F172A),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.auto_awesome_rounded,
                    size: 16,
                    color: Color(0xFF2DD4BF),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Konsultasikan dengan AIsisten',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
