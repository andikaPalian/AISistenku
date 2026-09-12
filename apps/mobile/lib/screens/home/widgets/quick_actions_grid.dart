import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class QuickActionsGrid extends StatelessWidget {
  const QuickActionsGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> actions = [
      {'title': 'Kasir POS', 'icon': Icons.point_of_sale_rounded, 'color': Colors.blue},
      {'title': 'Stok Barang', 'icon': Icons.inventory_2_rounded, 'color': Colors.orange},
      {'title': 'Laporan', 'icon': Icons.insert_chart_rounded, 'color': Colors.purple},
      {'title': 'Diskon', 'icon': Icons.percent_rounded, 'color': Colors.red},
      {'title': 'Pelanggan', 'icon': Icons.group_rounded, 'color': Colors.teal},
      {'title': 'Meja', 'icon': Icons.table_restaurant_rounded, 'color': Colors.brown},
      {'title': 'Pegawai', 'icon': Icons.badge_rounded, 'color': Colors.indigo},
      {'title': 'Pengaturan', 'icon': Icons.settings_rounded, 'color': Colors.grey},
    ];

    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.8,
      ),
      itemCount: actions.length,
      itemBuilder: (context, index) {
        final action = actions[index];
        return Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6), // Soft grey background like in reference
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                action['icon'],
                color: action['color'],
                size: 28,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              action['title'],
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF111111),
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        );
      },
    );
  }
}
