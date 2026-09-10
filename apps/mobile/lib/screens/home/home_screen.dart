import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/stock_model.dart';
import '../../../models/product.dart';
import 'widgets/header_section.dart';
import 'widgets/revenue_card.dart';
import 'widgets/ai_insight_card.dart';
import 'widgets/stock_alert_section.dart';
import 'widgets/activity_card.dart';

/// Main home dashboard screen for Tiga Angkatan / AIsistenku mobile app.
///
/// Designed strictly to match the verified production reference UI:
/// 1. Top Bar with Store Switcher, Notification bell, and User Avatar.
/// 2. Greeting Row with live "Toko Buka" status pill and operational hours.
/// 3. "BISNIS HARI INI" Card with Gross Revenue, 7-day mini bar chart, and sub-metrics.
/// 4. "AI BUSINESS INSIGHT" Deep forest emerald card with dual action buttons.
/// 5. "Perlu Diperhatikan" Stock alerts with linear progress bars and "Restock Cepat".
/// 6. "Menu Terlaris Hari Ini" Top 3 ranked items and realtime sync status bar.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Future<void> _handleRefresh() async {
    // Refresh backend data and local repositories
    try {
      await Future.wait([
        ProductRepository.instance.fetchProductsFromBackend(),
        StockRepository.instance.fetchStocksFromBackend(),
      ]);
    } catch (_) {
      // Fallback silently if offline
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _handleRefresh,
          color: AppColors.primaryTeal,
          backgroundColor: Colors.white,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── 1. Top Bar & Greeting Header ───────────────────────
                HeaderSection(),
                SizedBox(height: 20),

                // ── 2. Bisnis Hari Ini (Revenue & Mini Bar Chart) ──────
                RevenueCard(),
                SizedBox(height: 20),

                // ── 3. AI Business Insight (Hero Dark Emerald Card) ────
                AiInsightCard(),
                SizedBox(height: 24),

                // ── 4. Perlu Diperhatikan (Stock Alert Section) ────────
                StockAlertSection(),
                SizedBox(height: 24),

                // ── 5. Menu Terlaris Hari Ini & Realtime Sync ──────────
                ActivityCard(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
