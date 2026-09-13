import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/action_success_modal.dart';
import '../../../models/product.dart';
import '../../../models/stock_model.dart';

/// Helper model representing a dynamic row in the Recipe (BOM) form.
class _RecipeRowItem {
  String? stockId;
  String stockName;
  String selectedUnit;
  final TextEditingController qtyController;
  int costPerUnit;
  String baseUnit;
  IconData icon;

  _RecipeRowItem({
    this.stockId,
    this.stockName = '',
    required this.selectedUnit,
    String initialQty = '1',
    this.costPerUnit = 0,
    this.baseUnit = 'pcs',
    this.icon = Icons.inventory_2_rounded,
  }) : qtyController = TextEditingController(text: initialQty);

  void dispose() {
    qtyController.dispose();
  }

  double get quantity => double.tryParse(qtyController.text.trim()) ?? 0.0;

  double get quantityInBaseUnit {
    final q = quantity;
    if (q <= 0) return 0.0;
    if (baseUnit.toLowerCase() == 'kg' && selectedUnit.toLowerCase() == 'g') {
      return q / 1000.0;
    }
    if (baseUnit.toLowerCase() == 'l' && selectedUnit.toLowerCase() == 'ml') {
      return q / 1000.0;
    }
    return q;
  }

  int get estimatedCost {
    return (quantityInBaseUnit * costPerUnit).round();
  }
}

/// Modal bottom sheet for Adding or Editing a Product in POS with native Gallery/Camera Image Upload support.
class AddEditProductModal extends StatefulWidget {
  final Product? product;

  const AddEditProductModal({super.key, this.product});

  static Future<void> show(BuildContext context, {Product? product}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddEditProductModal(product: product),
    );
  }

  @override
  State<AddEditProductModal> createState() => _AddEditProductModalState();
}

class _AddEditProductModalState extends State<AddEditProductModal> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _codeController;
  late TextEditingController _stockController;
  late TextEditingController _minStockController;
  late TextEditingController _variantController;
  late TextEditingController _imageUrlController;

  late ProductCategory _selectedCategory;
  late String _selectedUnit;
  String? _currentImageUrl;
  Uint8List? _pickedImageBytes;
  bool _isLoading = false;

  final List<_RecipeRowItem> _recipeRows = [];

  bool get _isEditing => widget.product != null;

  // Preset quick images for coffee & food
  final List<Map<String, String>> _presetImages = [
    {
      'label': 'Iced Latte',
      'url': 'https://images.unsplash.com/photo-1517701550927-30cf4ba1dba5?w=500&auto=format&fit=crop&q=80',
    },
    {
      'label': 'Americano',
      'url': 'https://images.unsplash.com/photo-1514432324607-a09d9b4aefdd?w=500&auto=format&fit=crop&q=80',
    },
    {
      'label': 'Cappuccino',
      'url': 'https://images.unsplash.com/photo-1572442388796-11668a67e53d?w=500&auto=format&fit=crop&q=80',
    },
    {
      'label': 'Chocolate',
      'url': 'https://images.unsplash.com/photo-1544787219-7f47ccb76574?w=500&auto=format&fit=crop&q=80',
    },
    {
      'label': 'Matcha',
      'url': 'https://images.unsplash.com/photo-1536256263959-770b48d82b0a?w=500&auto=format&fit=crop&q=80',
    },
    {
      'label': 'Croissant',
      'url': 'https://images.unsplash.com/photo-1555507036-ab1f4038808a?w=500&auto=format&fit=crop&q=80',
    },
    {
      'label': 'Avocado Toast',
      'url': 'https://images.unsplash.com/photo-1525351484163-7529414344d8?w=500&auto=format&fit=crop&q=80',
    },
    {
      'label': 'Muffin Cake',
      'url': 'https://images.unsplash.com/photo-1607958996333-41aef7caefaa?w=500&auto=format&fit=crop&q=80',
    },
  ];

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _nameController = TextEditingController(text: p?.name ?? '');
    _priceController = TextEditingController(text: p != null ? p.price.toString() : '');
    _codeController = TextEditingController(
      text: p?.code ?? 'MNU-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
    );
    _stockController = TextEditingController(text: p != null ? p.stock.toString() : '20');
    _minStockController = TextEditingController(text: p != null ? p.minStock.toString() : '5');
    _variantController = TextEditingController(text: p?.defaultVariant ?? 'Regular');
    _imageUrlController = TextEditingController(text: p?.imageUrl ?? '');

    _selectedCategory = p?.category ?? ProductCategory.kopi;
    _selectedUnit = p?.unit ?? 'cup';
    _currentImageUrl = p?.imageUrl;

    if (_currentImageUrl != null && _currentImageUrl!.startsWith('data:image')) {
      try {
        final commaIdx = _currentImageUrl!.indexOf(',');
        if (commaIdx != -1) {
          _pickedImageBytes = base64Decode(_currentImageUrl!.substring(commaIdx + 1));
        }
      } catch (_) {}
    }

    _imageUrlController.addListener(() {
      final text = _imageUrlController.text.trim();
      if (text != _currentImageUrl && !text.startsWith('data:image')) {
        setState(() {
          _currentImageUrl = text.isNotEmpty ? text : null;
          _pickedImageBytes = null;
        });
      }
    });

    _nameController.addListener(() {
      if (mounted) setState(() {});
    });

    _priceController.addListener(() {
      if (mounted) setState(() {});
    });

    // Populate recipes if editing existing product
    if (p != null && p.recipes.isNotEmpty) {
      for (final r in p.recipes) {
        final stock = StockRepository.instance.getItemById(r.stockId);
        final baseUnit = stock?.unit ?? (r.unit == 'g' ? 'kg' : (r.unit == 'ml' ? 'L' : r.unit));
        final cost = stock?.costPerUnit ?? r.costPerUnit;

        String dispUnit = r.unit;
        double dispQty = r.displayQuantity > 0 ? r.displayQuantity : r.quantityRequired;
        if (dispUnit.isEmpty) {
          if (baseUnit.toLowerCase() == 'kg') {
            dispUnit = 'g';
            dispQty = r.quantityRequired * 1000;
          } else if (baseUnit.toLowerCase() == 'l') {
            dispUnit = 'ml';
            dispQty = r.quantityRequired * 1000;
          } else {
            dispUnit = baseUnit;
          }
        }

        final qtyStr = dispQty == dispQty.roundToDouble()
            ? dispQty.toInt().toString()
            : dispQty.toString();

        final row = _RecipeRowItem(
          stockId: r.stockId,
          stockName: r.stockName,
          selectedUnit: dispUnit,
          initialQty: qtyStr,
          costPerUnit: cost,
          baseUnit: baseUnit,
          icon: stock?.icon ?? Icons.inventory_2_rounded,
        );
        row.qtyController.addListener(() {
          if (mounted) setState(() {});
        });
        _recipeRows.add(row);
      }
    } else if (p != null) {
      _loadBackendRecipeIfAvailable(p.id);
    }
  }

  Future<void> _loadBackendRecipeIfAvailable(String productId) async {
    try {
      final res = await ApiService.instance.get('/products/$productId/recipe');
      List? list;
      if (res != null) {
        if (res['data'] is List) {
          list = res['data'];
        } else if (res['recipes'] is List) {
          list = res['recipes'];
        }
      }
      if (list != null && list.isNotEmpty && mounted) {
        setState(() {
          for (final r in _recipeRows) {
            r.dispose();
          }
          _recipeRows.clear();
          for (final item in list!) {
            final recipeItem = ProductRecipeItem.fromJson(item as Map<String, dynamic>);
            final stock = StockRepository.instance.getItemById(recipeItem.stockId);
            final baseUnit = stock?.unit ?? recipeItem.unit;
            final cost = stock?.costPerUnit ?? recipeItem.costPerUnit;

            String dispUnit = recipeItem.unit;
            double dispQty = recipeItem.displayQuantity > 0 ? recipeItem.displayQuantity : recipeItem.quantityRequired;
            if (dispUnit.isEmpty) {
              if (baseUnit.toLowerCase() == 'kg') {
                dispUnit = 'g';
                dispQty = recipeItem.quantityRequired * 1000;
              } else if (baseUnit.toLowerCase() == 'l') {
                dispUnit = 'ml';
                dispQty = recipeItem.quantityRequired * 1000;
              } else {
                dispUnit = baseUnit;
              }
            }

            final qtyStr = dispQty == dispQty.roundToDouble()
                ? dispQty.toInt().toString()
                : dispQty.toString();

            final row = _RecipeRowItem(
              stockId: recipeItem.stockId,
              stockName: recipeItem.stockName,
              selectedUnit: dispUnit,
              initialQty: qtyStr,
              costPerUnit: cost,
              baseUnit: baseUnit,
              icon: stock?.icon ?? Icons.inventory_2_rounded,
            );
            row.qtyController.addListener(() {
              if (mounted) setState(() {});
            });
            _recipeRows.add(row);
          }
        });
      }
    } catch (_) {}
  }

  void _addRecipeRow({
    String? stockId,
    String? stockName,
    String? unit,
    String qty = '1',
    int cost = 0,
    String baseUnit = 'pcs',
    IconData icon = Icons.inventory_2_rounded,
  }) {
    if (stockId != null) {
      final stock = StockRepository.instance.getItemById(stockId);
      if (stock != null) {
        stockName = stock.name;
        baseUnit = stock.unit;
        cost = stock.costPerUnit;
        icon = stock.icon;
        if (unit == null || unit.isEmpty) {
          if (stock.unit.toLowerCase() == 'kg') {
            unit = 'g';
            if (qty == '1') qty = '18';
          } else if (stock.unit.toLowerCase() == 'l') {
            unit = 'ml';
            if (qty == '1') qty = '120';
          } else {
            unit = stock.unit;
          }
        }
      }
    } else {
      final available = StockRepository.instance.items;
      final unselected = available.where((s) => !_recipeRows.any((r) => r.stockId == s.id)).toList();
      
      // Auto-match ingredient that matches product name (e.g. "pepaya" -> "pepaya")
      StockItem? matchingStock;
      final currentProductName = _nameController.text.trim().toLowerCase();
      if (currentProductName.isNotEmpty) {
        for (final s in unselected) {
          final sName = s.name.trim().toLowerCase();
          if (sName == currentProductName || sName.contains(currentProductName) || currentProductName.contains(sName)) {
            matchingStock = s;
            break;
          }
        }
      }

      final firstStock = matchingStock ?? (unselected.isNotEmpty ? unselected.first : (available.isNotEmpty ? available.first : null));
      if (firstStock != null) {
        stockId = firstStock.id;
        stockName = firstStock.name;
        baseUnit = firstStock.unit;
        cost = firstStock.costPerUnit;
        icon = firstStock.icon;
        if (firstStock.unit.toLowerCase() == 'kg') {
          unit = 'g';
          qty = '18';
        } else if (firstStock.unit.toLowerCase() == 'l') {
          unit = 'ml';
          qty = '120';
        } else {
          unit = firstStock.unit;
          qty = '1';
        }
      }
    }

    final row = _RecipeRowItem(
      stockId: stockId,
      stockName: stockName ?? '',
      selectedUnit: unit ?? 'g',
      initialQty: qty,
      costPerUnit: cost,
      baseUnit: baseUnit,
      icon: icon,
    );

    row.qtyController.addListener(() {
      if (mounted) setState(() {});
    });

    setState(() {
      _recipeRows.add(row);
    });
  }

  void _removeRecipeRow(int index) {
    if (index >= 0 && index < _recipeRows.length) {
      setState(() {
        _recipeRows[index].dispose();
        _recipeRows.removeAt(index);
      });
    }
  }

  void _applyPresetRecipe(String type) {
    setState(() {
      for (final r in _recipeRows) {
        r.dispose();
      }
      _recipeRows.clear();
    });

    if (type == 'kopi_susu') {
      _addRecipeRow(stockId: 'coffee_beans', qty: '18', unit: 'g');
      _addRecipeRow(stockId: 'fresh_milk', qty: '120', unit: 'ml');
      _addRecipeRow(stockId: 'sugar', qty: '15', unit: 'g');
      _addRecipeRow(stockId: 'cup_16oz', qty: '1', unit: 'pcs');
    } else if (type == 'americano') {
      _addRecipeRow(stockId: 'coffee_beans', qty: '18', unit: 'g');
      _addRecipeRow(stockId: 'cup_16oz', qty: '1', unit: 'pcs');
    } else if (type == 'latte_non_kopi') {
      _addRecipeRow(stockId: 'fresh_milk', qty: '150', unit: 'ml');
      _addRecipeRow(stockId: 'sugar', qty: '10', unit: 'g');
      _addRecipeRow(stockId: 'cup_16oz', qty: '1', unit: 'pcs');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _codeController.dispose();
    _stockController.dispose();
    _minStockController.dispose();
    _variantController.dispose();
    _imageUrlController.dispose();
    for (final r in _recipeRows) {
      r.dispose();
    }
    super.dispose();
  }

  /// Pick an image from gallery or camera
  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? file = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
      );

      if (file == null) return;

      final bytes = await file.readAsBytes();
      final base64String = 'data:image/jpeg;base64,${base64Encode(bytes)}';

      setState(() {
        _pickedImageBytes = bytes;
        _currentImageUrl = base64String;
        _imageUrlController.text = base64String;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memilih gambar: $e')),
      );
    }
  }

  void _showImageSourcePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Pilih Sumber Foto',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 17, color: AppColors.darkText),
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.photo_library_rounded, color: Color(0xFF111111)),
                ),
                title: Text('Pilih dari Galeri Foto', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppColors.darkText)),
                subtitle: Text('Ambil foto dari penyimpanan perangkat', style: GoogleFonts.inter(fontSize: 12, color: AppColors.mutedText)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.gallery);
                },
              ),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.camera_alt_rounded, color: Color(0xFF111111)),
                ),
                title: Text('Ambil Foto Kamera', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppColors.darkText)),
                subtitle: Text('Foto menu langsung menggunakan kamera HP', style: GoogleFonts.inter(fontSize: 12, color: AppColors.mutedText)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.camera);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onSelectPresetImage(String url) {
    setState(() {
      _pickedImageBytes = null;
      _imageUrlController.text = url;
      _currentImageUrl = url;
    });
  }

  void _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final price = int.tryParse(_priceController.text.trim()) ?? 0;
    final code = _codeController.text.trim();
    final stock = int.tryParse(_stockController.text.trim()) ?? 0;
    final minStock = int.tryParse(_minStockController.text.trim()) ?? 5;
    final variant = _variantController.text.trim().isNotEmpty ? _variantController.text.trim() : 'Regular';
    String? imageUrl = _currentImageUrl?.trim();

    setState(() => _isLoading = true);

    try {
      // Jika ada gambar dari kamera/galeri, upload langsung ke Cloudinary
      if (_pickedImageBytes != null && (imageUrl == null || imageUrl.startsWith('data:image'))) {
        try {
          final res = await ApiService.instance.uploadMultipart(
            '/upload/product',
            bytes: _pickedImageBytes!,
            filename: 'product_${DateTime.now().millisecondsSinceEpoch}.jpg',
            fields: {'productName': name},
          );
          if (res != null && res['data'] != null && res['data']['url'] != null) {
            imageUrl = res['data']['url'] as String;
          }
        } catch (e) {
          debugPrint('⚠️ Cloudinary upload warning: $e, menggunakan data lokal/offline');
        }
      }

      final recipeItems = _recipeRows
          .where((r) => r.stockId != null && r.stockId!.isNotEmpty && r.quantity > 0)
          .map((r) => ProductRecipeItem(
                stockId: r.stockId!,
                stockName: r.stockName,
                quantityRequired: r.quantityInBaseUnit,
                unit: r.selectedUnit,
                displayQuantity: r.quantity,
                costPerUnit: r.costPerUnit,
              ))
          .toList();

      if (_isEditing) {
        final updated = widget.product!.copyWith(
          name: name,
          price: price,
          code: code,
          category: _selectedCategory,
          stock: stock,
          minStock: minStock,
          unit: _selectedUnit,
          defaultVariant: variant,
          imageUrl: imageUrl,
          recipes: recipeItems,
        );

        ProductRepository.instance.updateProduct(updated);
      } else {
        final newProduct = Product(
          id: 'prod-${DateTime.now().millisecondsSinceEpoch}',
          name: name,
          price: price,
          code: code,
          category: _selectedCategory,
          stock: stock,
          minStock: minStock,
          unit: _selectedUnit,
          defaultVariant: variant,
          imageUrl: imageUrl,
          placeholderIcon: Icons.coffee_rounded,
          recipes: recipeItems,
        );

        ProductRepository.instance.addProduct(newProduct);
      }

      if (!mounted) return;
      final savedName = name;
      final savedPrice = price;
      final savedCategory = _selectedCategory;
      final savedStock = stock;
      final savedUnit = _selectedUnit;
      final wasEditing = _isEditing;

      Navigator.pop(context);
      ActionSuccessModal.show(
        context,
        title: wasEditing ? 'Menu Berhasil Diperbarui' : 'Menu Baru Ditambahkan',
        subtitle: 'Katalog kasir POS dan ketersediaan porsi telah disinkronkan secara real-time.',
        itemName: savedName,
        itemCategory: 'Menu Kasir (${savedCategory.label})',
        quantityChange: Product.formatRupiah(savedPrice),
        financialImpact: 'Stok: $savedStock $savedUnit',
        statusBadge: 'Tersimpan',
        itemIcon: Icons.restaurant_menu_rounded,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _handleDelete() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Hapus Produk?',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        content: Text(
          'Apakah Anda yakin ingin menghapus "${widget.product?.name}" dari katalog POS?',
          style: GoogleFonts.inter(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.destructive,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              final prodName = widget.product?.name ?? 'Menu';
              ProductRepository.instance.deleteProduct(widget.product!.id);
              Navigator.pop(ctx);
              Navigator.pop(context);
              ActionSuccessModal.show(
                context,
                title: 'Menu Berhasil Dihapus',
                subtitle: 'Menu "$prodName" telah dihapus dari katalog POS dan inventaris.',
                itemName: prodName,
                itemCategory: 'Menu Kasir',
                quantityChange: 'Dihapus',
                financialImpact: 'Katalog Kasir Diperbarui',
                statusBadge: 'Dihapus',
                itemIcon: Icons.delete_outline_rounded,
                heroIcon: Icons.delete_forever_rounded,
                heroColor: const Color(0xFFEF4444),
                heroHaloColor: const Color(0xFFFEE2E2),
              );
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePreviewWidget() {
    if (_pickedImageBytes != null) {
      return Image.memory(
        _pickedImageBytes!,
        fit: BoxFit.cover,
      );
    }

    if (_currentImageUrl != null && _currentImageUrl!.isNotEmpty) {
      if (_currentImageUrl!.startsWith('data:image')) {
        try {
          final commaIdx = _currentImageUrl!.indexOf(',');
          final bytes = base64Decode(_currentImageUrl!.substring(commaIdx + 1));
          return Image.memory(bytes, fit: BoxFit.cover);
        } catch (_) {}
      }
      return Image.network(
        _currentImageUrl!,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const Center(
          child: Icon(Icons.broken_image_rounded, color: AppColors.mutedText),
        ),
      );
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.12), // Light green tint
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.add_a_photo_rounded, color: AppColors.secondary, size: 26),
          ),
          const SizedBox(height: 6),
          Text(
            'Sentuh untuk Upload Foto',
            style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.darkText),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: EdgeInsets.only(
        top: 16,
        left: 24,
        right: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
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

          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _isEditing ? 'Edit Menu Produk' : 'Tambah Menu Baru',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.darkText,
                ),
              ),
              if (_isEditing)
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, color: AppColors.destructive),
                  onPressed: _handleDelete,
                )
              else
                Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFFF1F5F9),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          const SizedBox(height: 16),

          // Form fields scrollable
          Flexible(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── 1. Image Preview & Upload Actions ──
                    _buildFieldLabel('Foto Menu *'),
                    const SizedBox(height: 4),

                    // Tappable Banner Card for Photo
                    GestureDetector(
                      onTap: _showImageSourcePicker,
                      child: Container(
                        width: double.infinity,
                        height: 140,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: _buildImagePreviewWidget(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Quick Action Buttons (Gallery & Camera Pills)
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _pickImage(ImageSource.gallery),
                            icon: const Icon(Icons.photo_library_outlined, size: 16),
                            label: Text('Galeri', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF111111),
                              side: const BorderSide(color: Color(0xFFE2E8F0)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _pickImage(ImageSource.camera),
                            icon: const Icon(Icons.camera_alt_outlined, size: 16),
                            label: Text('Kamera', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF111111),
                              side: const BorderSide(color: Color(0xFFE2E8F0)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Preset Image Badges
                    _buildFieldLabel('Atau Pilih Foto Cepat:'),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        children: _presetImages.map((p) {
                          final isSelected = _currentImageUrl == p['url'];
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ActionChip(
                              label: Text(
                                p['label']!,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected ? Colors.white : AppColors.darkText,
                                ),
                              ),
                              avatar: Icon(
                                Icons.coffee_rounded,
                                size: 15,
                                color: isSelected ? Colors.white : const Color(0xFF64748B),
                              ),
                              backgroundColor: isSelected ? const Color(0xFF111111) : const Color(0xFFF1F5F9),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20), // Pill preset
                                side: BorderSide.none,
                              ),
                              onPressed: () => _onSelectPresetImage(p['url']!),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // ── 2. Nama Produk ──
                    _buildFieldLabel('Nama Produk *'),
                    TextFormField(
                      controller: _nameController,
                      validator: (v) => v == null || v.trim().isEmpty ? 'Nama produk wajib diisi' : null,
                      style: GoogleFonts.inter(fontSize: 14),
                      decoration: _inputDecoration('Contoh: Iced Caramel Latte'),
                    ),
                    const SizedBox(height: 14),

                    // ── 3. Kategori ──
                    _buildFieldLabel('Kategori Produk'),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ProductCategory.kopi,
                        ProductCategory.nonKopi,
                        ProductCategory.snack,
                        ProductCategory.makanan,
                      ].map((cat) {
                        final isSel = _selectedCategory == cat;
                        return ChoiceChip(
                          label: Text(
                            cat.label,
                            style: GoogleFonts.inter(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: isSel ? Colors.white : AppColors.darkText,
                            ),
                          ),
                          selected: isSel,
                          selectedColor: const Color(0xFF111111), // Solid Black Pill
                          backgroundColor: const Color(0xFFF1F5F9),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: isSel ? BorderSide.none : const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          showCheckmark: false,
                          onSelected: (_) => setState(() => _selectedCategory = cat),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    // ── 4. Harga & Kode SKU ──
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildFieldLabel('Harga Jual (Rp) *'),
                              TextFormField(
                                controller: _priceController,
                                keyboardType: TextInputType.number,
                                validator: (v) => v == null || int.tryParse(v) == null ? 'Harga wajib angka' : null,
                                style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
                                decoration: _inputDecoration('15000', prefix: 'Rp '),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildFieldLabel('Kode / SKU'),
                              TextFormField(
                                controller: _codeController,
                                style: GoogleFonts.inter(fontSize: 14),
                                decoration: _inputDecoration('KOP-001'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // ── 5. Stok & Satuan ──
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildFieldLabel('Stok Awal'),
                              TextFormField(
                                controller: _stockController,
                                keyboardType: TextInputType.number,
                                style: GoogleFonts.inter(fontSize: 14),
                                decoration: _inputDecoration('20'),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildFieldLabel('Min. Alert Stok'),
                              TextFormField(
                                controller: _minStockController,
                                keyboardType: TextInputType.number,
                                style: GoogleFonts.inter(fontSize: 14),
                                decoration: _inputDecoration('5'),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildFieldLabel('Satuan'),
                              DropdownButtonFormField<String>(
                                initialValue: _selectedUnit,
                                items: ['cup', 'pcs', 'porsi', 'btl', 'box']
                                    .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                                    .toList(),
                                onChanged: (v) => setState(() => _selectedUnit = v ?? 'cup'),
                                decoration: _inputDecoration(''),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // ── 6. Varian Bawaan ──
                    _buildFieldLabel('Varian Bawaan / Catatan'),
                    TextFormField(
                      controller: _variantController,
                      style: GoogleFonts.inter(fontSize: 14),
                      decoration: _inputDecoration('Contoh: Less Sugar, Ice'),
                    ),
                    const SizedBox(height: 20),

                    // ── 7. Komposisi Bahan Baku (Resep) ──
                    _buildRecipeSection(),
                    const SizedBox(height: 36),
                  ],
                ),
              ),
            ),
          ),

          // Submit Button (Solid Black Pill)
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleSave,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF111111), // Solid Black Pill
                foregroundColor: Colors.white,
                elevation: 4,
                shadowColor: const Color(0xFF111111).withValues(alpha: 0.3),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              child: _isLoading
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                  : Text(
                      _isEditing ? 'Simpan Perubahan' : 'Tambah ke Menu POS',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 16),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecipeSection() {
    final availableStocks = StockRepository.instance.items;
    final totalHpp = _recipeRows.fold(0, (sum, r) => sum + r.estimatedCost);
    final sellingPrice = int.tryParse(_priceController.text.trim()) ?? 0;
    final profit = sellingPrice - totalHpp;
    final marginPct = sellingPrice > 0 ? ((profit / sellingPrice) * 100).round() : 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header Row (Responsive with Expanded to eliminate overflow)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF111111),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.blender_outlined, size: 18, color: Colors.white),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Komposisi Bahan Baku (Resep)',
                            style: GoogleFonts.poppins(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.darkText,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Resep & Bill of Materials (BOM)',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: AppColors.mutedText,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (_recipeRows.isNotEmpty) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFBBF7D0)),
                  ),
                  child: Text(
                    '${_recipeRows.length} Bahan',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF16A34A),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, size: 15, color: Color(0xFF64748B)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Tautkan bahan stok agar HPP terhitung dan stok terpotong otomatis saat checkout.',
                    style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF475569), height: 1.3),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Quick Preset Buttons
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.bolt_rounded, size: 14, color: Color(0xFF0F172A)),
                      const SizedBox(width: 3),
                      Text(
                        'Template:',
                        style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _buildPresetChip(
                  label: '☕ Kopi Susu (18g Kopi + 120ml Susu)',
                  onTap: () => _applyPresetRecipe('kopi_susu'),
                ),
                const SizedBox(width: 6),
                _buildPresetChip(
                  label: '☕ Americano (18g Kopi + Cup)',
                  onTap: () => _applyPresetRecipe('americano'),
                ),
                const SizedBox(width: 6),
                _buildPresetChip(
                  label: '🥛 Minuman Susu (150ml Susu)',
                  onTap: () => _applyPresetRecipe('latte_non_kopi'),
                ),
                if (_recipeRows.isNotEmpty) ...[
                  const SizedBox(width: 6),
                  ActionChip(
                    label: Text(
                      'Kosongkan',
                      style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.destructive),
                    ),
                    backgroundColor: const Color(0xFFFEE2E2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide.none),
                    onPressed: () {
                      setState(() {
                        for (final r in _recipeRows) {
                          r.dispose();
                        }
                        _recipeRows.clear();
                      });
                    },
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Recipe Dynamic Rows or Empty State
          if (_recipeRows.isEmpty)
            _buildEmptyRecipeCard()
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _recipeRows.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                return _buildRecipeRowCard(index, _recipeRows[index], availableStocks);
              },
            ),

          const SizedBox(height: 12),

          // Add Ingredient Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _addRecipeRow(),
              icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
              label: Text(
                'Tambah Bahan Baku Resep',
                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF111111),
                side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                backgroundColor: Colors.white,
              ),
            ),
          ),

          // Dynamic Recipe Summary & Financial Impact
          if (_recipeRows.isNotEmpty) ...[
            const SizedBox(height: 14),
            _buildRecipeSummaryCard(totalHpp, sellingPrice, profit, marginPct),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyRecipeCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.blender_outlined, size: 24, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 10),
          Text(
            'Belum Ada Resep Bahan Baku',
            style: GoogleFonts.poppins(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: AppColors.darkText,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Tautkan bahan dari stok inventaris (biji kopi, susu, cup, dsb.) agar otomatis berkurang saat kasir memproses pesanan.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 12, color: AppColors.mutedText, height: 1.4),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () => _addRecipeRow(),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: Text('Tambah Bahan Pertama', style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w700)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF111111),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecipeRowCard(int index, _RecipeRowItem row, List<StockItem> availableStocks) {
    final stockExists = availableStocks.any((s) => s.id == row.stockId);
    final currentStock = stockExists ? availableStocks.firstWhere((s) => s.id == row.stockId) : null;
    final baseUnit = currentStock?.unit ?? row.baseUnit;

    List<String> allowedUnits = [baseUnit];
    if (baseUnit.toLowerCase() == 'kg') {
      allowedUnits = ['g', 'kg'];
    } else if (baseUnit.toLowerCase() == 'l') {
      allowedUnits = ['ml', 'L'];
    } else if (baseUnit.toLowerCase() == 'btl') {
      allowedUnits = ['btl', 'ml'];
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Index badge, stock balance, delete button
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF111111),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Bahan #${index + 1}',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (currentStock != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.inventory_2_outlined, size: 12, color: Color(0xFF64748B)),
                      const SizedBox(width: 4),
                      Text(
                        'Stok: ${currentStock.formattedCurrentStock}',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              const Spacer(),
              InkWell(
                onTap: () => _removeRecipeRow(index),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.delete_outline_rounded,
                    size: 16,
                    color: AppColors.destructive,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Dropdown to pick Stock item from inventory
          Text(
            'Pilih Bahan dari Inventaris Stok *',
            style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w600, color: const Color(0xFF475569)),
          ),
          const SizedBox(height: 4),
          DropdownButtonFormField<String>(
            initialValue: stockExists ? row.stockId : null,
            isExpanded: true,
            hint: Text(
              '-- Pilih Bahan Inventaris --',
              style: GoogleFonts.inter(fontSize: 13, color: AppColors.mutedText),
            ),
            items: availableStocks.map((stock) {
              return DropdownMenuItem<String>(
                value: stock.id,
                child: Row(
                  children: [
                    Icon(stock.icon, size: 16, color: const Color(0xFF111111)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        stock.name,
                        style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '(${stock.formattedCurrentStock})',
                      style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B)),
                    ),
                  ],
                ),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null) {
                final chosen = availableStocks.firstWhere((s) => s.id == val);
                setState(() {
                  row.stockId = chosen.id;
                  row.stockName = chosen.name;
                  row.costPerUnit = chosen.costPerUnit;
                  row.baseUnit = chosen.unit;
                  row.icon = chosen.icon;

                  if (chosen.unit.toLowerCase() == 'kg') {
                    row.selectedUnit = 'g';
                    if (row.qtyController.text == '1' || row.qtyController.text.isEmpty) {
                      row.qtyController.text = '18';
                    }
                  } else if (chosen.unit.toLowerCase() == 'l') {
                    row.selectedUnit = 'ml';
                    if (row.qtyController.text == '1' || row.qtyController.text.isEmpty) {
                      row.qtyController.text = '120';
                    }
                  } else if (chosen.unit.toLowerCase() == 'btl') {
                    row.selectedUnit = 'btl';
                    if (row.qtyController.text == '1' || row.qtyController.text.isEmpty) {
                      row.qtyController.text = '0.05';
                    }
                  } else {
                    row.selectedUnit = chosen.unit;
                  }
                });
              }
            },
            decoration: _inputDecoration('Pilih Bahan'),
          ),
          const SizedBox(height: 10),

          // Quantity and Unit Inputs
          Row(
            children: [
              Expanded(
                flex: 5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Takaran per 1 $_selectedUnit *',
                      style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 4),
                    TextFormField(
                      controller: row.qtyController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.w700),
                      decoration: _inputDecoration('Contoh: 18'),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Satuan',
                      style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 4),
                    DropdownButtonFormField<String>(
                      initialValue: allowedUnits.contains(row.selectedUnit) ? row.selectedUnit : allowedUnits.first,
                      items: allowedUnits.map((u) {
                        return DropdownMenuItem<String>(
                          value: u,
                          child: Text(
                            u,
                            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                        );
                      }).toList(),
                      onChanged: (v) {
                        if (v != null) {
                          setState(() {
                            row.selectedUnit = v;
                          });
                        }
                      },
                      decoration: _inputDecoration(''),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Cost estimation footer pill (Responsive layout, eliminates duplicate "Rp Rp" and overflow)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.calculate_outlined, size: 14, color: Color(0xFF64748B)),
                      const SizedBox(width: 5),
                      Text(
                        'Modal: ',
                        style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B)),
                      ),
                      Flexible(
                        child: Text(
                          Product.formatRupiah(row.estimatedCost),
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.darkText,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                if (row.costPerUnit > 0) ...[
                  const SizedBox(width: 8),
                  Text(
                    '(@ ${Product.formatRupiah(row.costPerUnit)}/${row.baseUnit})',
                    style: GoogleFonts.inter(
                      fontSize: 10.5,
                      color: const Color(0xFF64748B),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPresetChip({required String label, required VoidCallback onTap}) {
    return ActionChip(
      label: Text(
        label,
        style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.darkText),
      ),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      onPressed: onTap,
    );
  }

  Widget _buildRecipeSummaryCard(int totalHpp, int sellingPrice, int profit, int marginPct) {
    final activeRows = _recipeRows.where((r) => r.stockId != null && r.quantity > 0).toList();
    final formulaParts = activeRows.map((r) {
      final qStr = r.quantity == r.quantity.roundToDouble()
          ? r.quantity.toInt().toString()
          : r.quantity.toString();
      return '$qStr ${r.selectedUnit} ${r.stockName}';
    }).join(' + ');

    final productName = _nameController.text.trim().isNotEmpty ? _nameController.text.trim() : 'Menu';
    final fullFormula = activeRows.isNotEmpty
        ? '1 $_selectedUnit $productName = $formulaParts'
        : 'Belum ada bahan aktif yang ditentukan.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A), // Modern rich obsidian card
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.receipt_long_rounded, color: Colors.white, size: 16),
              ),
              const SizedBox(width: 8),
              Text(
                'Ringkasan Resep (BOM)',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Formula Text Box
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              fullFormula,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF38BDF8), // Bright cyan highlight
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Financial stats
          Row(
            children: [
              // HPP Box
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Modal (HPP)',
                        style: GoogleFonts.inter(fontSize: 10.5, color: const Color(0xFF94A3B8)),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        Product.formatRupiah(totalHpp),
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'per 1 $_selectedUnit',
                        style: GoogleFonts.inter(fontSize: 9.5, color: const Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Gross Profit / Margin Box
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: (sellingPrice > 0 && profit >= 0)
                        ? AppColors.secondary.withValues(alpha: 0.15)
                        : (sellingPrice > 0 && profit < 0)
                            ? AppColors.destructive.withValues(alpha: 0.15)
                            : Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Estimasi Laba Kotor',
                        style: GoogleFonts.inter(
                          fontSize: 10.5,
                          color: (sellingPrice > 0 && profit >= 0)
                              ? const Color(0xFF4ADE80)
                              : (sellingPrice > 0 && profit < 0)
                                  ? const Color(0xFFF87171)
                                  : const Color(0xFF94A3B8),
                        ),
                      ),
                      const SizedBox(height: 2),
                      if (sellingPrice > 0)
                        Text(
                          Product.formatRupiah(profit),
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: profit >= 0 ? const Color(0xFF4ADE80) : const Color(0xFFF87171),
                          ),
                        )
                      else
                        Text(
                          '-',
                          style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white),
                        ),
                      Text(
                        sellingPrice > 0 ? 'Margin $marginPct%' : 'Isi harga jual',
                        style: GoogleFonts.inter(
                          fontSize: 9.5,
                          color: (sellingPrice > 0 && profit >= 0)
                              ? const Color(0xFF86EFAC)
                              : const Color(0xFF64748B),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        label,
        style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.darkText),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, {String? prefix}) {
    return InputDecoration(
      hintText: hint,
      prefixText: prefix,
      prefixStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF111111)),
      hintStyle: GoogleFonts.inter(fontSize: 13, color: AppColors.mutedText.withValues(alpha: 0.6)),
      filled: true,
      fillColor: const Color(0xFFF8FAFC), // Modern clean slate
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF111111), width: 1.5),
      ),
    );
  }
}
