import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/stock_model.dart';

/// Modal bottom sheet for Stock Opname / Manual Stock Adjustment.
class AdjustStockModal extends StatefulWidget {
  final StockItem item;

  const AdjustStockModal({
    super.key,
    required this.item,
  });

  static Future<bool?> show(BuildContext context, {required StockItem item}) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AdjustStockModal(item: item),
    );
  }

  @override
  State<AdjustStockModal> createState() => _AdjustStockModalState();
}

class _AdjustStockModalState extends State<AdjustStockModal> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _actualQtyController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  String _selectedReason = 'Selisih Opname / Audit Fisik';
  double _actualQty = 0;

  final List<String> _reasons = [
    'Selisih Opname / Audit Fisik',
    'Bahan Basi / Kadaluwarsa',
    'Tumpah / Rusak / Terbuang (Waste)',
    'Koreksi Salah Input',
    'Bonus / Sampel Supplier',
  ];

  @override
  void initState() {
    super.initState();
    _actualQty = widget.item.currentStock;
    _actualQtyController.text = _actualQty == _actualQty.roundToDouble()
        ? _actualQty.toInt().toString()
        : _actualQty.toStringAsFixed(1);

    _actualQtyController.addListener(() {
      final parsed = double.tryParse(_actualQtyController.text) ?? 0;
      if (parsed != _actualQty) {
        setState(() {
          _actualQty = parsed;
        });
      }
    });
  }

  @override
  void dispose() {
    _actualQtyController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    if (!_formKey.currentState!.validate()) return;

    final diff = _actualQty - widget.item.currentStock;
    if (diff == 0) {
      Navigator.pop(context);
      return;
    }

    StockRepository.instance.adjustStock(
      stockId: widget.item.id,
      actualQuantity: _actualQty,
      reason: _selectedReason,
      note: _notesController.text.trim().isNotEmpty
          ? _notesController.text.trim()
          : null,
      operatorName: 'Owner / Supervisor',
    );

    Navigator.pop(context, true);

    final diffStr = diff > 0
        ? '+${diff.toStringAsFixed(1)} ${widget.item.unit}'
        : '${diff.toStringAsFixed(1)} ${widget.item.unit}';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Color(0xFF22C55E)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Stok ${widget.item.name} berhasil disesuaikan ($diffStr)',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF111111),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final keyboardPadding = MediaQuery.of(context).viewInsets.bottom;
    final item = widget.item;
    final diff = _actualQty - item.currentStock;
    final isNegative = diff < 0;
    final isZero = diff == 0;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + keyboardPadding),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF111111),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.tune_rounded,
                        color: Color(0xFF22C55E),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Penyesuaian Stok (Opname)',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF111111),
                              letterSpacing: -0.3,
                            ),
                          ),
                          Text(
                            item.name,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Before vs After comparison
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tercatat di Sistem',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item.formattedCurrentStock,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF111111),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 40,
                        color: const Color(0xFFE2E8F0),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Selisih (Discrepancy)',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                isZero
                                    ? '0 ${item.unit}'
                                    : '${diff > 0 ? '+' : ''}${diff.toStringAsFixed(diff == diff.roundToDouble() ? 0 : 1)} ${item.unit}',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: isZero
                                      ? const Color(0xFF64748B)
                                      : isNegative
                                          ? const Color(0xFFEF4444)
                                          : const Color(0xFF16A34A),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // Actual Count Input
                Text(
                  'Hasil Hitung Fisik Sebenarnya (${item.unit})',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF111111),
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _actualQtyController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                  ],
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF111111),
                  ),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    suffixText: item.unit,
                    suffixStyle: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF64748B),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1.2),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1.2),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFF111111), width: 1.5),
                    ),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Masukkan jumlah fisik';
                    if (double.tryParse(val) == null) return 'Format angka tidak valid';
                    return null;
                  },
                ),
                const SizedBox(height: 18),

                // Reason for Adjustment
                Text(
                  'Alasan Penyesuaian',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF111111),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: _selectedReason,
                      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF111111)),
                      items: _reasons.map((r) {
                        return DropdownMenuItem<String>(
                          value: r,
                          child: Text(
                            r,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF111111),
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedReason = val);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Notes
                Text(
                  'Catatan Tambahan (Opsional)',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF111111),
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _notesController,
                  maxLines: 2,
                  style: GoogleFonts.plusJakartaSans(fontSize: 14, color: const Color(0xFF111111)),
                  decoration: InputDecoration(
                    hintText: 'Contoh: Kemasan bocor saat penyimpanan',
                    hintStyle: GoogleFonts.plusJakartaSans(fontSize: 13, color: const Color(0xFF94A3B8)),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1.2),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1.2),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFF111111), width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Submit Button (Solid Black)
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _handleSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF111111),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 4,
                      shadowColor: Colors.black.withValues(alpha: 0.25),
                    ),
                    child: Text(
                      'Simpan Hasil Penyesuaian',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
