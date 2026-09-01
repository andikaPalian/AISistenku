import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';

/// Welcome banner card introducing AIsisten to the business owner.
class AiWelcomeHero extends StatelessWidget {
  final String userName;

  const AiWelcomeHero({
    super.key,
    this.userName = 'Budi',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDFA),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF99F6E4).withOpacity(0.8),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryTeal.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Hi, $userName',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.darkText,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                '👋',
                style: TextStyle(fontSize: 20),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Aku adalah asisten bisnismu. Silahkan tanya aku untuk analisis penjualan, stock, ide promo, dan caption sosmed outlet kamu!',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF334155),
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}
