import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/finance_model.dart';

/// Card showing today's gross revenue, mini 7-day bar chart,
/// and key sub-metrics (Orders, Today's Expenses, Net Margin).
///
class RevenueCard extends StatelessWidget {
  const RevenueCard({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: FinanceRepository.instance,
      builder: (context, _) {
        final repo = FinanceRepository.instance;
        final grossRevenueNum = repo.getTotalIncome(FinancePeriod.today);
        final expenseNum = repo.getTotalExpense(FinancePeriod.today);
        
        final grossRevenue = FinanceRepository.formatRupiah(grossRevenueNum);
        final todayExpenses = FinanceRepository.formatRupiah(expenseNum);
        
        final netProfit = grossRevenueNum - expenseNum;
        final netMargin = grossRevenueNum > 0 ? (netProfit / grossRevenueNum * 100).toStringAsFixed(1) : '0';
        
        final todayOrders = repo.getFilteredTransactions(period: FinancePeriod.today, typeFilter: TransactionType.income)
            .where((tx) => tx.source == TransactionSource.posAutomatic)
            .length;

        return Container(
          decoration: BoxDecoration(
            color: AppColors.primaryTeal, // Consistent with app system brand color
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryTeal.withValues(alpha: 0.35),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pendapatan Kotor Hari Ini',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: const Color(0xFF99F6E4), // Mint light
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                grossRevenue,
                style: GoogleFonts.poppins(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildMetricItem('Pesanan', '$todayOrders', Icons.receipt_long_rounded),
                  _buildMetricItem('Beban', todayExpenses, Icons.money_off_rounded),
                  _buildMetricItem('Margin', '$netMargin%', Icons.pie_chart_rounded),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMetricItem(String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: const Color(0xFF5EEAD4)),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: const Color(0xFFCCFBF1),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}
