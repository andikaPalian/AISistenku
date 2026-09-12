import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FinanceRepository.instance.fetchFinanceFromBackend();
      FinanceRepository.instance.fetchDashboardFromBackend();
    });
  }

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
          backgroundColor: const Color(0xFFF8FAFC),
          body: SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 140),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FinanceHeader(
                    selectedPeriod: _selectedPeriod,
                    onPeriodChanged: _onPeriodChanged,
                    onAddTransactionTap: () => _openAddTransaction(),
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
                  const SizedBox(height: 20),

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
                          backgroundColor: Color(0xFF111111),
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
                  const SizedBox(height: 20),

                  // 9. Full-Width "Tambah Transaksi +" Button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () => _openAddTransaction(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF111111),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.add_circle_outline_rounded,
                            size: 19,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Tambah Transaksi +',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
