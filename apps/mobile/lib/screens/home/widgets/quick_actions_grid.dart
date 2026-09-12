import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/finance_model.dart';
import '../../shell_screen.dart';
import '../../finance/add_transaction_screen.dart';
import 'quick_restock_sheet.dart';
import 'more_menu_sheet.dart';

/// Modern Neo-Clean Quick Actions Operational Row.
///
/// 4 purposeful, 100% active operational shortcuts:
/// 1. `+ Transaksi`: Instant jump to Kasir POS.
/// 2. `+ Stok`: Quick restock sheet for low ingredients.
/// 3. `Catat Kas`: Instant expense recorder (bahan, operasional, logistik).
/// 4. `Menu Lain`: Direct sheet opening secondary management modules (Meja, Pelanggan, Diskon, Shift).
class QuickActionsGrid extends StatelessWidget {
  const QuickActionsGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'AKSI OPERASIONAL',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF64748B),
                letterSpacing: 0.6,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'Pintasan Cepat',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF475569),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // 4 Action Cards Row
        Row(
          children: [
            // 1. + Transaksi (Kasir POS)
            Expanded(
              child: _buildActionCard(
                label: '+ Transaksi',
                icon: Icons.point_of_sale_rounded,
                badgeBg: const Color(0xFFDCFCE7),
                iconColor: const Color(0xFF16A34A),
                onTap: () => ShellScreen.switchTab(context, 1),
              ),
            ),
            const SizedBox(width: 10),

            // 2. + Stok Masuk
            Expanded(
              child: _buildActionCard(
                label: '+ Stok',
                icon: Icons.inventory_2_outlined,
                badgeBg: const Color(0xFFDBEAFE),
                iconColor: const Color(0xFF2563EB),
                onTap: () => QuickRestockSheet.show(context),
              ),
            ),
            const SizedBox(width: 10),

            // 3. Catat Kas (Pengeluaran)
            Expanded(
              child: _buildActionCard(
                label: 'Catat Kas',
                icon: Icons.receipt_long_outlined,
                badgeBg: const Color(0xFFFEF3C7),
                iconColor: const Color(0xFFD97706),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const AddTransactionScreen(
                        initialType: TransactionType.expense,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 10),

            // 4. Menu Lain (Manajemen Toko)
            Expanded(
              child: _buildActionCard(
                label: 'Menu Lain',
                icon: Icons.grid_view_rounded,
                badgeBg: const Color(0xFFF1F5F9),
                iconColor: const Color(0xFF475569),
                onTap: () => MoreMenuSheet.show(context),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required String label,
    required IconData icon,
    required Color badgeBg,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: const Color(0xFFE2E8F0),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: iconColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
