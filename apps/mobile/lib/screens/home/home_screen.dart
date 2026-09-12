import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/stock_model.dart';
import '../../../models/product.dart';
import 'widgets/header_section.dart';
import 'widgets/revenue_card.dart';
import 'widgets/quick_actions_grid.dart';
import 'widgets/activity_card.dart';

/// Main home dashboard screen for Tiga Angkatan / AIsistenku mobile app.
///
/// Designed cleanly with no AI SLOP. Focuses on real backend data:
/// 1. Top Bar & Greeting Header
/// 2. Revenue Card (Bisnis Hari Ini)
/// 3. Quick Actions Grid
/// 4. Top Products (Menu Terlaris)
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Future<void> _handleRefresh() async {
    try {
      await Future.wait([
        ProductRepository.instance.fetchProductsFromBackend(),
        StockRepository.instance.fetchStocksFromBackend(),
      ]);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _handleRefresh,
          color: AppColors.primary,
          backgroundColor: Colors.white,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 140),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                HeaderSection(),
                SizedBox(height: 24),
                RevenueCard(),
                SizedBox(height: 32),
                QuickActionsGrid(),
                SizedBox(height: 32),
                ActivityCard(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
