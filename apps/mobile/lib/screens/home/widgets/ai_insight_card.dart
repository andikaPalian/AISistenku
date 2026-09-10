import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../ai_assistant/ai_assistant_screen.dart';
import '../../../core/widgets/ai_portal_route.dart';
import '../../../core/widgets/bouncing_press.dart';

/// Hero dark emerald card for proactive business intelligence.
///
/// Matches the reference UI with:
/// - Dark forest teal gradient background (`#064E3B` to `#065F46`)
/// - Mint header with sparkle icon: "AI BUSINESS INSIGHT • Live Suggestion"
/// - Rich formatted text with product highlights
/// - Two distinct tactile buttons:
///   1. `[ 💬 Tanya AIsistenku ]` (White button)
///   2. `[ ⚡ Buat Promo Sore ]` (Terracotta button)
class AiInsightCard extends StatelessWidget {
  final String? customMessage;

  const AiInsightCard({
    super.key,
    this.customMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF064E3B), // Deep forest emerald
            Color(0xFF065F46), // Muted dark teal
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF047857).withValues(alpha: 0.6),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF064E3B).withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header: Sparkle Icon + Title + Live Suggestion Badge ──────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.auto_awesome,
                      color: Color(0xFF34D399),
                      size: 14,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'AI BUSINESS INSIGHT',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: const Color(0xFF34D399),
                    ),
                  ),
                ],
              ),
              Text(
                'Live Suggestion',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: const Color(0xFFA7F3D0),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // ── Formatted Insight Copy ────────────────────────────────────
          RichText(
            text: TextSpan(
              style: GoogleFonts.inter(
                fontSize: 13.5,
                color: const Color(0xFFECFDF5),
                height: 1.55,
              ),
              children: const [
                TextSpan(text: 'Penjualan pagi ini sangat lancar! '),
                TextSpan(
                  text: 'Kopi Susu Gula Aren',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                TextSpan(text: ' memimpin dengan '),
                TextSpan(
                  text: '42 cup',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                TextSpan(text: '. Perhatian: stok '),
                TextSpan(
                  text: 'Gula Pasir & Susu Segar',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    decoration: TextDecoration.underline,
                    decorationColor: Color(0xFF34D399),
                  ),
                ),
                TextSpan(
                  text:
                      ' mendekati batas aman, rekomendasikan restock sebelum jam ramai sore pukul 15:30.',
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // ── Two Action Buttons Row ────────────────────────────────────
          Row(
            children: [
              // Button 1: Tanya AIsistenku (White Pill Button)
              Expanded(
                child: SizedBox(
                  height: 44, // WCAG minimum touch target
                  child: BouncingPress(
                    onTap: () {
                      Navigator.push(
                        context,
                        AiAssistantPortalRoute(
                          builder: (context) => const AiAssistantScreen(),
                        ),
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.chat_bubble_outline_rounded,
                            size: 16,
                            color: Color(0xFF0D9488),
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              'Tanya AIsistenku',
                              style: GoogleFonts.inter(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF0F172A),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 10),

              // Button 2: Buat Promo Sore (Terracotta Pill Button)
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: BouncingPress(
                    onTap: () {
                      // Navigate to AI screen with pre-filled promo theme
                      Navigator.push(
                        context,
                        AiAssistantPortalRoute(
                          builder: (context) => const AiAssistantScreen(),
                        ),
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFC2410C), // Terracotta
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.bolt_rounded,
                            size: 17,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              'Buat Promo Sore',
                              style: GoogleFonts.inter(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
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
}
