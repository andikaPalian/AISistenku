import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/stock_model.dart';

/// Modal bottom sheet for creating/registering a new raw material.
class AddStockModal extends StatefulWidget {
  final StockItem? itemToEdit;

  const AddStockModal({
    super.key,
    this.itemToEdit,
  });

  static Future<bool?> show(BuildContext context, {StockItem? itemToEdit}) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddStockModal(itemToEdit: itemToEdit),
    );
  }

  @override
  State<AddStockModal> createState() => _AddStockModalState();
}

class _AddStockModalState extends State<AddStockModal> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _stockController;
  late final TextEditingController _minStockController;
  late final TextEditingController _costController;
  late final TextEditingController _supplierController;
  late final TextEditingController _notesController;

  StockCategory _selectedCategory = StockCategory.kopi;
  String _selectedUnit = 'kg';

  final List<String> _availableUnits = ['kg', 'L', 'liter', 'btl', 'botol', 'g', 'gram', 'pcs', 'cup', 'porsi', 'pack', 'ml', 'dus', 'kaleng'];

  bool get isEditing => widget.itemToEdit != null;

  @override
  void initState() {
    super.initState();
    final item = widget.itemToEdit;
    _nameController = TextEditingController(text: item?.name ?? '');
    _stockController = TextEditingController(
      text: item != null
          ? (item.currentStock == item.currentStock.roundToDouble()
              ? item.currentStock.toInt().toString()
              : item.currentStock.toString())
          : '',
    );
    _minStockController = TextEditingController(
      text: item != null
          ? (item.minStock == item.minStock.roundToDouble()
              ? item.minStock.toInt().toString()
              : item.minStock.toString())
          : '5',
    );
    _costController = TextEditingController(
      text: item != null ? item.costPerUnit.toString() : '20000',
    );
    _supplierController = TextEditingController(text: item?.supplier ?? '');
    _notesController = TextEditingController(text: item?.note ?? '');

    if (item != null) {
      _selectedCategory = item.category;
      _selectedUnit = item.unit;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _stockController.dispose();
    _minStockController.dispose();
    _costController.dispose();
    _supplierController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final stock = double.tryParse(_stockController.text) ?? 0;
    final minStock = double.tryParse(_minStockController.text) ?? 1;
    final cost = int.tryParse(_costController.text) ?? 0;
    final supplier = _supplierController.text.trim();
    final note = _notesController.text.trim();

    IconData icon = Icons.inventory_2_rounded;
    switch (_selectedCategory) {
      case StockCategory.kopi:
        icon = Icons.coffee_rounded;
        break;
      case StockCategory.dairy:
        icon = Icons.water_drop_rounded;
        break;
      case StockCategory.pemanis:
        icon = Icons.grain_rounded;
        break;
      case StockCategory.sirup:
        icon = Icons.liquor_rounded;
        break;
      case StockCategory.kemasan:
        icon = Icons.local_drink_rounded;
        break;
      case StockCategory.topping:
        icon = Icons.spa_rounded;
        break;
      default:
        icon = Icons.inventory_2_rounded;
    }

    if (isEditing) {
      final updated = widget.itemToEdit!.copyWith(
        name: name,
        category: _selectedCategory,
        currentStock: stock,
        minStock: minStock,
        unit: _selectedUnit,
        costPerUnit: cost,
        supplier: supplier.isNotEmpty ? supplier : 'Supplier Utama',
        note: note.isNotEmpty ? note : null,
        icon: icon,
        lastUpdated: DateTime.now(),
      );
      StockRepository.instance.updateStockItem(updated);
    } else {
      final newItem = StockItem(
        id: 'stock_${DateTime.now().millisecondsSinceEpoch}',
        name: name,
        category: _selectedCategory,
        currentStock: stock,
        minStock: minStock,
        unit: _selectedUnit,
        costPerUnit: cost,
        supplier: supplier.isNotEmpty ? supplier : 'Supplier Utama',
        note: note.isNotEmpty ? note : null,
        icon: icon,
        lastUpdated: DateTime.now(),
      );
      StockRepository.instance.addStockItem(newItem);
    }

    Navigator.pop(context, true);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isEditing
              ? 'Data bahan baku $name berhasil diperbarui'
              : 'Bahan baku baru $name berhasil ditambahkan!',
          style: GoogleFonts.inter(fontWeight: FontWeight.w500),
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
                      child: Icon(
                        isEditing ? Icons.edit_note_rounded : Icons.add_box_rounded,
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
                            isEditing ? 'Ubah Bahan Baku' : 'Tambah Bahan Baku Baru',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.darkText,
                            ),
                          ),
                          Text(
                            'Kelola detail & batas peringatan stok',
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

                // Nama Bahan
                Text(
                  'Nama Bahan Baku',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.darkText,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameController,
                  style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w500),
                  decoration: InputDecoration(
                    hintText: 'Contoh: Sirup Hazelnut, Matcha Uji, Cup 16oz',
                    filled: true,
                    fillColor: Color(0xFFF1F5F9),
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
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Nama bahan wajib diisi' : null,
                ),
                const SizedBox(height: 16),

                // Kategori & Satuan (2 Columns)
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Kategori',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.darkText,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                            decoration: BoxDecoration(
                              color: Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(12),

                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<StockCategory>(
                                isExpanded: true,
                                value: _selectedCategory,
                                icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.primaryTeal),
                                items: StockCategory.values
                                    .where((c) => c != StockCategory.all)
                                    .map((cat) => DropdownMenuItem(
                                          value: cat,
                                          child: Text(
                                            cat.label,
                                            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
                                          ),
                                        ))
                                    .toList(),
                                onChanged: (cat) {
                                  if (cat != null) setState(() => _selectedCategory = cat);
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Satuan',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.darkText,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                            decoration: BoxDecoration(
                              color: Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(12),

                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                isExpanded: true,
                                value: _selectedUnit,
                                icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.primaryTeal),
                                items: _availableUnits
                                    .map((u) => DropdownMenuItem(
                                          value: u,
                                          child: Text(
                                            u,
                                            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
                                          ),
                                        ))
                                    .toList(),
                                onChanged: (u) {
                                  if (u != null) setState(() => _selectedUnit = u);
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Stok Awal & Stok Minimum (2 Columns)
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isEditing ? 'Stok Saat Ini' : 'Stok Awal ($_selectedUnit)',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.darkText,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _stockController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
                            decoration: InputDecoration(
                              hintText: '0',
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
                            validator: (v) =>
                                (v == null || double.tryParse(v) == null) ? 'Angka valid' : null,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Batas Minimum ($_selectedUnit)',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.darkText,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _minStockController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
                            decoration: InputDecoration(
                              hintText: '5',
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
                            validator: (v) =>
                                (v == null || double.tryParse(v) == null) ? 'Batas min' : null,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Harga Beli & Supplier
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Harga Beli / $_selectedUnit',
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
                            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500),
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
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Supplier',
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
                              hintText: 'Nama supplier',
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
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Catatan
                Text(
                  'Catatan Khusus (Opsional)',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.darkText,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _notesController,
                  maxLines: 2,
                  style: GoogleFonts.inter(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Contoh: Simpan di suhu chiller 4°C',
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
                      isEditing ? 'Simpan Perubahan' : 'Simpan Bahan Baku',
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
