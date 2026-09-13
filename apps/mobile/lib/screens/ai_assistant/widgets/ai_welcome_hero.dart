import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/profile_model.dart';

/// Modern welcome and empty state canvas introducing AIsisten to the business owner.
class AiWelcomeHero extends StatelessWidget {
  final String? userName;
  final ValueChanged<String>? onSelectPrompt;

  const AiWelcomeHero({
    super.key,
    this.userName,
    this.onSelectPrompt,
  });

  static const _prompts = [
    (
      Icons.trending_up_rounded,
      'Performa Penjualan',
      'Bagaimana performa penjualan dan laba saya hari ini?',
    ),
    (
      Icons.receipt_long_rounded,
      'Catat Belanja Bahan',
      'Saya baru saja beli 10kg gula pasir dengan harga total 170rb',
    ),
    (
      Icons.inventory_2_outlined,
      'Cek Stok Menipis',
      'Cek stok bahan baku apa yang perlu di-restock sekarang?',
    ),
    (
      Icons.campaign_outlined,
      'Ide Caption Promo',
      'Buatkan caption Instagram menarik untuk promo Kopi Susu sore ini',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final rawName = userName?.trim();
    final displayName = (rawName != null && rawName.isNotEmpty && rawName.toLowerCase() != 'owner')
        ? (rawName.contains(' ') ? rawName.split(' ').first : rawName)
        : ProfileRepository.instance.user.firstName;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 12),

          // Official Logo in Solid Black Rounded Square
          Container(
            width: 58,
            height: 58,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF111111),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Image.asset(
              'assets/icons/logoAisitenku.png',
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 16),

          // Title & Greeting
          Text(
            'Halo, $displayName 👋',
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0F172A),
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Asisten pintar untuk analisa penjualan, pencatatan otomatis, dan strategi promosi tokomu.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF64748B),
                height: 1.45,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Starter Action Cards (2 Columns)
          Column(
            children: [
              Row(
                children: [
                  Expanded(child: _buildStarterCard(_prompts[0])),
                  const SizedBox(width: 10),
                  Expanded(child: _buildStarterCard(_prompts[1])),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: _buildStarterCard(_prompts[2])),
                  const SizedBox(width: 10),
                  Expanded(child: _buildStarterCard(_prompts[3])),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStarterCard((IconData, String, String) prompt) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onSelectPrompt?.call(prompt.$3),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: Color(0xFFF1F5F9),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  prompt.$1,
                  size: 16,
                  color: const Color(0xFF111111),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                prompt.$2,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                prompt.$3,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF64748B),
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
