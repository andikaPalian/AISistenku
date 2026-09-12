import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/stock_model.dart';
import '../../../models/product.dart';
import '../../../models/finance_model.dart';
import 'widgets/header_section.dart';
import 'widgets/revenue_card.dart';
import 'widgets/quick_actions_grid.dart';
import 'widgets/stock_alert_section.dart';
import 'widgets/recent_orders_section.dart';
import 'widgets/activity_card.dart';

/// Main home dashboard screen for Tiga Angkatan / AIsistenku mobile app.
///
/// Complete, clean, and authentic daily command center for store owners:
/// 1. Top Bar & Location Header with Notification Sheet
/// 2. Revenue Card (Bisnis Hari Ini) with live income, orders, and expense
/// 3. Quick Actions Operational Row (Kasir, Stok, Catat Kas, Menu Lain)
/// 4. Stock Alert Section (Perlu Diperhatikan / Stok Kritis)
/// 5. Live Recent Orders Section (Transaksi Terkini)
/// 6. Best Sellers Section (Menu Terlaris Top 3)
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
        FinanceRepository.instance.fetchFinanceFromBackend(),
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
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 160),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Header Profil & Notifikasi
                HeaderSection(),
                SizedBox(height: 20),

                // 2. Ringkasan Bisnis & Pendapatan Hari Ini
                RevenueCard(),
                SizedBox(height: 28),

                // 3. Pintasan Aksi Cepat Operasional
                QuickActionsGrid(),
                SizedBox(height: 28),

                // 4. Peringatan Stok Kritis (Perlu Perhatian)
                StockAlertSection(),
                SizedBox(height: 28),

                // 5. Transaksi Terkini (Live Feed)
                RecentOrdersSection(),
                SizedBox(height: 28),

                // 6. Produk Terlaris Hari Ini
                ActivityCard(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
