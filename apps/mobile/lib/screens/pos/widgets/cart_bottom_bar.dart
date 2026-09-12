import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Bottom bar showing cart summary and "Lihat Pesanan" action button.
/// Only visible when there are items in the cart.
class CartBottomBar extends StatelessWidget {
  final int itemCount;
  final String totalFormatted;
  final VoidCallback onViewOrder;

  const CartBottomBar({
    super.key,
    required this.itemCount,
    required this.totalFormatted,
    required this.onViewOrder,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 24), // Elevated floating margin
      child: GestureDetector(
        onTap: onViewOrder,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF111111), // Solid Black Pill
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF111111).withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Left: Total Price
              Text(
                totalFormatted,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              // Right: Action
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.shopping_bag_rounded,
                      color: Color(0xFF111111),
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Lihat Pesanan ($itemCount)',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
