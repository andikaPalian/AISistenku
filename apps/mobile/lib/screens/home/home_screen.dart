import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/stock_model.dart';
import '../../../models/product.dart';
import 'widgets/header_section.dart';
import 'widgets/revenue_card.dart';
import 'widgets/stock_alert_section.dart';
import 'widgets/activity_card.dart';

/// Main home dashboard screen for Tiga Angkatan / AIsistenku mobile app.
///
/// Designed cleanly with no AI SLOP. Focuses on real backend data:
/// 1. Top Bar & Greeting Header
/// 2. Revenue Card (Bisnis Hari Ini)
/// 3. Stock Alerts (Perlu Diperhatikan)
/// 4. Top Products (Menu Terlaris)
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
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 100), // Increased padding and bottom margin
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── 1. Top Bar & Greeting Header ───────────────────────
                HeaderSection(),
                SizedBox(height: 32),

                // ── 2. Bisnis Hari Ini (Revenue & Mini Bar Chart) ──────
                RevenueCard(),
                SizedBox(height: 32),

                // ── 3. Perlu Diperhatikan (Stock Alert Section) ────────
                StockAlertSection(),
                SizedBox(height: 32),

                // ── 4. Menu Terlaris Hari Ini & Realtime Sync ──────────
                ActivityCard(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
