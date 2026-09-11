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
            const Icon(Icons.check_circle_rounded, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Stok ${_selectedItem!.name} berhasil ditambah +$_enteredQty ${_selectedItem!.unit}!',
                style: GoogleFonts.inter(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.primaryTeal,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                      color: Color(0xFFE2E8F0),
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
                        color: AppColors.primaryTeal.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.add_shopping_cart_rounded,
                        color: AppColors.primaryTeal,
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
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.darkText,
                            ),
                          ),
                          Text(
                            'Restock & catat pengeluaran bahan',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: AppColors.mutedText,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded, color: AppColors.mutedText),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Item Selector (if not pre-locked or allowing change)
                Text(
                  'Bahan Baku',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.darkText,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  decoration: BoxDecoration(
                    color: Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),

                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<StockItem>(
                      isExpanded: true,
                      value: item,
                      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.primaryTeal),
                      items: items.map((stock) {
                        return DropdownMenuItem<StockItem>(
                          value: stock,
                          child: Row(
                            children: [
                              Icon(stock.icon, size: 18, color: AppColors.primaryTeal),
                              const SizedBox(width: 10),
                              Text(
                                stock.name,
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.darkText,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                'Saat ini: ${stock.formattedCurrentStock}',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: AppColors.mutedText,
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
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.darkText,
                      ),
                    ),
                    if (item != null)
                      Text(
                        'Min: ${item.formattedMinStock}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.mutedText,
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
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryTeal,
                  ),
                  decoration: InputDecoration(
                    hintText: '0',
                    filled: true,
                    fillColor: Color(0xFFF1F5F9),
                    suffixText: item?.unit ?? '',
                    suffixStyle: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.mutedText,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.primaryTeal, width: 1.5),
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
                          color: Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(20),

                        ),
                        child: Text(
                          '+$label ${item?.unit ?? ''}',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryTeal,
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
                      color: willBeSafe ? AppColors.successBg : AppColors.warningBg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: willBeSafe
                            ? AppColors.successGreen.withValues(alpha: 0.3)
                            : AppColors.warningOrange.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          willBeSafe
                              ? Icons.check_circle_outline_rounded
                              : Icons.info_outline_rounded,
                          color: willBeSafe
                              ? AppColors.successText
                              : AppColors.warningText,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Proyeksi Stok Setelah Restock',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: willBeSafe
                                      ? AppColors.successText
                                      : AppColors.warningText,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${item.formattedCurrentStock} + ${_enteredQty.toStringAsFixed(_enteredQty == _enteredQty.roundToDouble() ? 0 : 1)} ${item.unit} = ${newTotalStock.toStringAsFixed(newTotalStock == newTotalStock.roundToDouble() ? 0 : 1)} ${item.unit}',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: willBeSafe
                                      ? AppColors.successText
                                      : AppColors.warningText,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: willBeSafe
                                ? AppColors.successGreen
                                : AppColors.warningOrange,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            willBeSafe ? 'Aman' : 'Mendekati Min',
                            style: GoogleFonts.inter(
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
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.darkText,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _costController,
                            keyboardType: TextInputType.number,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.darkText,
                            ),
                            decoration: InputDecoration(
                              prefixText: 'Rp ',
                              filled: true,
                              fillColor: Color(0xFFF1F5F9),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: AppColors.primaryTeal, width: 1.5),
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
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.darkText,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            height: 48,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(12),

                            ),
                            alignment: Alignment.centerLeft,
                            child: Text(
                              StockItem.formatRupiah(totalExpense),
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primaryTeal,
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
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.darkText,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _supplierController,
                  style: GoogleFonts.inter(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Nama toko atau supplier',
                    filled: true,
                    fillColor: const Color(0xFFF1F5F9), // Slate
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.primaryTeal, width: 1.5),
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
                            activeColor: AppColors.primaryTeal,
                            onChanged: (val) => setState(() => _recordToFinance = val ?? true),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Catat otomatis sebagai Pengeluaran Bahan di Keuangan',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppColors.darkText,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _handleSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryTeal,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 6,
                      shadowColor: AppColors.primaryTeal.withValues(alpha: 0.4),
                    ),
                    child: Text(
                      'Simpan Stok Masuk',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
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
