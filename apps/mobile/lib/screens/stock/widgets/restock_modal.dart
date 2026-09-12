import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/stock_model.dart';
import '../../../models/finance_model.dart';

/// Modal bottom sheet for recording incoming stock (Restock / Pembelian).
class RestockModal extends StatefulWidget {
  final StockItem? initialItem;

  const RestockModal({
    super.key,
    this.initialItem,
  });

  static Future<bool?> show(BuildContext context, {StockItem? initialItem}) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => RestockModal(initialItem: initialItem),
    );
  }

  @override
  State<RestockModal> createState() => _RestockModalState();
}

class _RestockModalState extends State<RestockModal> {
  final _formKey = GlobalKey<FormState>();
  late StockItem? _selectedItem;
  final TextEditingController _qtyController = TextEditingController();
  final TextEditingController _costController = TextEditingController();
  final TextEditingController _supplierController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  double _enteredQty = 0;
  bool _recordToFinance = true;

  @override
  void initState() {
    super.initState();
    _selectedItem = widget.initialItem ??
        (StockRepository.instance.items.isNotEmpty
            ? StockRepository.instance.items.first
            : null);

    if (_selectedItem != null) {
      _costController.text = _selectedItem!.costPerUnit.toString();
      _supplierController.text = _selectedItem!.supplier;
    }

    _qtyController.addListener(() {
      final parsed = double.tryParse(_qtyController.text) ?? 0;
      if (parsed != _enteredQty) {
        setState(() {
          _enteredQty = parsed;
        });
      }
    });
  }

  @override
  void dispose() {
    _qtyController.dispose();
    _costController.dispose();
    _supplierController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _addQuickAmount(double amount) {
    HapticFeedback.lightImpact();
    final current = double.tryParse(_qtyController.text) ?? 0;
    final next = current + amount;
    _qtyController.text = next == next.roundToDouble()
        ? next.toInt().toString()
        : next.toStringAsFixed(1);
  }

  void _handleSubmit() {
    if (!_formKey.currentState!.validate() || _selectedItem == null) return;
    if (_enteredQty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Jumlah restock harus lebih dari 0'),
          backgroundColor: AppColors.destructive,
        ),
      );
      return;
    }

    final unitCost = int.tryParse(_costController.text) ?? _selectedItem!.costPerUnit;
    final supplierName = _supplierController.text.trim();
    final noteText = _notesController.text.trim();
    final totalExpense = (_enteredQty * unitCost).round();

    StockRepository.instance.restockItem(
      stockId: _selectedItem!.id,
      quantity: _enteredQty,
      costPerUnit: unitCost,
      supplier: supplierName,
      note: noteText.isNotEmpty ? noteText : null,
      operatorName: 'Owner',
    );

    // Auto-record expense to Finance if enabled (aligns with web flow)
    if (_recordToFinance && totalExpense > 0) {
      FinanceRepository.instance.addTransaction(
        title: 'Restock ${_selectedItem!.name}',
        type: TransactionType.expense,
        category: FinanceCategory.ingredients,
        amount: totalExpense.toDouble(),
        source: TransactionSource.manual,
        notes: noteText.isNotEmpty
            ? 'Restock ${_enteredQty.toStringAsFixed(_enteredQty == _enteredQty.roundToDouble() ? 0 : 1)} ${_selectedItem!.unit} • $noteText'
            : 'Restock ${_enteredQty.toStringAsFixed(_enteredQty == _enteredQty.roundToDouble() ? 0 : 1)} ${_selectedItem!.unit} dari ${supplierName.isNotEmpty ? supplierName : _selectedItem!.supplier}',
        timestamp: DateTime.now(),
      );
    }

    Navigator.pop(context, true);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Color(0xFF22C55E)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Stok ${_selectedItem!.name} berhasil ditambah +$_enteredQty ${_selectedItem!.unit}!',
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
    final items = StockRepository.instance.items;
    final item = _selectedItem;

    final newTotalStock = (item?.currentStock ?? 0) + _enteredQty;
    final willBeSafe = item != null && newTotalStock > item.minStock;

    final unitCost = int.tryParse(_costController.text) ?? (item?.costPerUnit ?? 0);
    final totalExpense = (_enteredQty * unitCost).round();

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
                        Icons.add_shopping_cart_rounded,
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
                            'Catat Stok Masuk',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF111111),
                              letterSpacing: -0.3,
                            ),
                          ),
                          Text(
                            'Restock & catat pengeluaran bahan',
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

                // Item Selector (if not pre-locked or allowing change)
                Text(
                  'Bahan Baku',
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
                    child: DropdownButton<StockItem>(
                      isExpanded: true,
                      value: item,
                      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF111111)),
                      items: items.map((stock) {
                        return DropdownMenuItem<StockItem>(
                          value: stock,
                          child: Row(
                            children: [
                              Icon(stock.icon, size: 18, color: const Color(0xFF111111)),
                              const SizedBox(width: 10),
                              Text(
                                stock.name,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF111111),
                                ),
                              ),
                              const Spacer(),
                              Text(
                                'Saat ini: ${stock.formattedCurrentStock}',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: widget.initialItem != null
                          ? null // locked if opened from detail
                          : (newItem) {
                              if (newItem != null) {
                                setState(() {
                                  _selectedItem = newItem;
                                  _costController.text = newItem.costPerUnit.toString();
                                  _supplierController.text = newItem.supplier;
                                });
                              }
                            },
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // Quantity Input & Quick increments
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Jumlah Masuk (${item?.unit ?? ''})',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF111111),
                      ),
                    ),
                    if (item != null)
                      Text(
                        'Min: ${item.formattedMinStock}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _qtyController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                  ],
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF111111),
                  ),
                  decoration: InputDecoration(
                    hintText: '0',
                    filled: true,
                    fillColor: Colors.white,
                    suffixText: item?.unit ?? '',
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
                    if (val == null || val.trim().isEmpty) {
                      return 'Masukkan jumlah';
                    }
                    final num = double.tryParse(val);
                    if (num == null || num <= 0) {
                      return 'Jumlah harus > 0';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),

                // Quick buttons
                Wrap(
                  spacing: 8,
                  children: [1.0, 5.0, 10.0, 20.0].map((amt) {
                    final label = amt == amt.roundToDouble() ? amt.toInt() : amt;
                    return InkWell(
                      onTap: () => _addQuickAmount(amt),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
                        ),
                        child: Text(
                          '+$label ${item?.unit ?? ''}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF111111),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // Dynamic Live Status Preview Card
                if (item != null && _enteredQty > 0)
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: willBeSafe ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: willBeSafe
                            ? const Color(0xFF22C55E).withValues(alpha: 0.3)
                            : const Color(0xFFF59E0B).withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          willBeSafe
                              ? Icons.check_circle_outline_rounded
                              : Icons.info_outline_rounded,
                          color: willBeSafe
                              ? const Color(0xFF16A34A)
                              : const Color(0xFFD97706),
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Proyeksi Stok Setelah Restock',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: willBeSafe
                                      ? const Color(0xFF16A34A)
                                      : const Color(0xFFD97706),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${item.formattedCurrentStock} + ${_enteredQty.toStringAsFixed(_enteredQty == _enteredQty.roundToDouble() ? 0 : 1)} ${item.unit} = ${newTotalStock.toStringAsFixed(newTotalStock == newTotalStock.roundToDouble() ? 0 : 1)} ${item.unit}',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: willBeSafe
                                      ? const Color(0xFF16A34A)
                                      : const Color(0xFFD97706),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: willBeSafe
                                ? const Color(0xFF22C55E)
                                : const Color(0xFFF59E0B),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            willBeSafe ? 'Aman' : 'Mendekati Min',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 18),

                // Pricing & Finance Integration
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Harga Beli per ${item?.unit ?? 'Unit'}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF111111),
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _costController,
                            keyboardType: TextInputType.number,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF111111),
                            ),
                            decoration: InputDecoration(
                              prefixText: 'Rp ',
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
                            onChanged: (_) => setState(() {}),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total Pembelian',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF111111),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            height: 48,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
                            ),
                            alignment: Alignment.centerLeft,
                            child: Text(
                              StockItem.formatRupiah(totalExpense),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF16A34A),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Supplier & Note
                Text(
                  'Supplier / Pemasok',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF111111),
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _supplierController,
                  style: GoogleFonts.plusJakartaSans(fontSize: 14, color: const Color(0xFF111111)),
                  decoration: InputDecoration(
                    hintText: 'Nama toko atau supplier',
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
                const SizedBox(height: 14),

                // Auto-sync finance checkbox toggle
                InkWell(
                  onTap: () => setState(() => _recordToFinance = !_recordToFinance),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: Checkbox(
                            value: _recordToFinance,
                            activeColor: const Color(0xFF111111),
                            onChanged: (val) => setState(() => _recordToFinance = val ?? true),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Catat otomatis sebagai Pengeluaran Bahan di Keuangan',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF111111),
                            ),
                          ),
                        ),
                      ],
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
                      'Simpan Stok Masuk',
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
