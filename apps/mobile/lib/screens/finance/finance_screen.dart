import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../models/finance_model.dart';
import 'widgets/finance_header.dart';
import 'widgets/current_balance_card.dart';
import 'widgets/income_expense_cards.dart';
import 'widgets/sales_analytics_chart.dart';
import 'widgets/peak_hours_chart.dart';
import 'widgets/top_products_card.dart';
import 'widgets/ai_finance_insight_card.dart';
import 'widgets/recent_transactions_section.dart';
import 'add_transaction_screen.dart';
import 'all_transactions_screen.dart';

/// Main Finance & Business Analytics screen (Tab 5).
///
/// Combines the sleek aesthetics of the reference UI with deep analytics
/// (sales trend charts, peak hours, bestselling products, cashflow, and AI insights)
/// to empower UMKM business owners with data-driven decision making.
class FinanceScreen extends StatefulWidget {
  const FinanceScreen({super.key});

  @override
  State<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends State<FinanceScreen> {
  FinancePeriod _selectedPeriod = FinancePeriod.today;

  void _onPeriodChanged(FinancePeriod period) {
    setState(() {
      _selectedPeriod = period;
    });
  }

  void _openAddTransaction([TransactionType type = TransactionType.expense]) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddTransactionScreen(initialType: type),
      ),
    );
  }

  void _openAllTransactions() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AllTransactionsScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: FinanceRepository.instance,
      builder: (context, _) {
        final repo = FinanceRepository.instance;
        final balance = repo.currentBalance;
        final income = repo.getTotalIncome(_selectedPeriod);
        final expense = repo.getTotalExpense(_selectedPeriod);
        final netProfit = repo.getNetProfit(_selectedPeriod);
        final grossMargin = repo.getGrossMargin(_selectedPeriod);
        final chartPoints = repo.getChartPoints(_selectedPeriod);
        final peakHours = repo.getPeakHours();
        final topProducts = repo.getTopProducts();
        final recentTx = repo.getFilteredTransactions(
          period: _selectedPeriod,
        );

        return Scaffold(
          backgroundColor: AppColors.pageBackground,
          body: SafeArea(
            bottom: false,
            child: Column(
              children: [
                // ── Scrollable Body ─────────────────────────────────
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 1. Header & Period Selector (Hari Ini | Minggu Ini | Bulan Ini)
                        FinanceHeader(
                          selectedPeriod: _selectedPeriod,
                          onPeriodChanged: _onPeriodChanged,
                        ),
                        const SizedBox(height: 20),

                        // 2. Current Balance Hero Card
                        CurrentBalanceCard(
                          balance: balance,
                          netProfit: netProfit,
                        ),
                        const SizedBox(height: 14),

                        // 3. Side-by-Side Income & Expense Stat Cards
                        IncomeExpenseCards(
                          income: income,
                          expense: expense,
                          onIncomeTap: () =>
                              _openAddTransaction(TransactionType.income),
                          onExpenseTap: () =>
                              _openAddTransaction(TransactionType.expense),
                        ),
                        const SizedBox(height: 24),

                        // 4. Interactive Sales & Cashflow Chart
                        SalesAnalyticsChart(
                          dataPoints: chartPoints,
                          period: _selectedPeriod,
                        ),
                        const SizedBox(height: 20),

                        // 5. Peak Hours Operational Chart
                        PeakHoursChart(peakHours: peakHours),
                        const SizedBox(height: 20),

                        // 6. Top Products & Revenue Contribution
                        TopProductsCard(products: topProducts),
                        const SizedBox(height: 20),

                        // 7. AI Business & Financial Recommendation Card
                        AiFinanceInsightCard(
                          grossMargin: grossMargin,
                          onConsultTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Membuka konsultasi di Tab AIsisten...',
                                ),
                                backgroundColor: AppColors.primaryTeal,
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 24),

                        // 8. Recent Transactions Section with All/Income/Expense filter
                        RecentTransactionsSection(
                          transactions: recentTx,
                          onViewAllTap: _openAllTransactions,
                        ),

                        // Spacer for bottom sticky button clearance
                        const SizedBox(height: 70),
                      ],
                    ),
                  ),
                ),

                // ── Bottom Full-Width "Tambah Transaksi +" Button ────
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      top: BorderSide(
                        color: AppColors.lightTealBorder,
                        width: 1,
                      ),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryTeal.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -3),
                      ),
                    ],
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () => _openAddTransaction(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryTeal,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        'Tambah Transaksi +',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
