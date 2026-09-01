import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import 'widgets/header_section.dart';
import 'widgets/revenue_card.dart';
import 'widgets/ai_insight_card.dart';
import 'widgets/stock_alert_section.dart';
import 'widgets/activity_card.dart';

/// Main home screen / dashboard showing business overview.
///
/// Displays today's revenue, AI insights, low-stock alerts,
/// and daily activity with best seller information.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const HeaderSection(),
              const SizedBox(height: 28),

              // ── Bisnis Hari Ini ───────────────────────────────
              Text(
                'Bisnis Hari Ini',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.darkText,
                ),
              ),
              const SizedBox(height: 14),
              const RevenueCard(),
              const SizedBox(height: 28),

              // ── AI Insight ────────────────────────────────────
              Row(
                children: [
                  const Icon(
                    Icons.auto_awesome,
                    color: AppColors.primaryTeal,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'AI Insight',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.darkText,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const AiInsightCard(),
              const SizedBox(height: 28),

              // ── Perlu Diperhatikan ────────────────────────────
              const StockAlertSection(),
              const SizedBox(height: 28),

              // ── Aktivitas Hari ini ────────────────────────────
              const ActivityCard(),
            ],
          ),
        ),
      ),
    );
  }
}
