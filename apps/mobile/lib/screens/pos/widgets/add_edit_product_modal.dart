import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/api_service.dart';
import '../../../models/product.dart';

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
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Pilih Sumber Gambar',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 16),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.tealBackgrounds,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.photo_library_rounded, color: AppColors.primaryTeal),
                ),
                title: Text('Pilih dari Galeri Foto', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                subtitle: Text('Ambil foto dari memori HP', style: GoogleFonts.inter(fontSize: 12, color: AppColors.mutedText)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.tealBackgrounds,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.camera_alt_rounded, color: AppColors.primaryTeal),
                ),
                title: Text('Ambil Foto Kamera', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                subtitle: Text('Foto langsung menggunakan kamera', style: GoogleFonts.inter(fontSize: 12, color: AppColors.mutedText)),
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
    final imageUrl = _currentImageUrl?.trim();

    setState(() => _isLoading = true);

    try {
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
        );

        ProductRepository.instance.updateProduct(updated);

        // Sync with backend API in background
        ApiService.instance.put('/products/${updated.id}', {
          'name': name,
          'price': price,
          'code': code,
          'category': _selectedCategory.label,
          'stock': stock,
          'min_stock': minStock,
          'unit': _selectedUnit,
          'default_variant': variant,
          'image_url': imageUrl,
        }).catchError((_) => null);
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
        );

        ProductRepository.instance.addProduct(newProduct);

        // Sync with backend API in background
        ApiService.instance.post('/products', {
          'name': name,
          'price': price,
          'code': code,
          'category': _selectedCategory.label,
          'stock': stock,
          'min_stock': minStock,
          'unit': _selectedUnit,
          'default_variant': variant,
          'image_url': imageUrl,
        }).catchError((_) => null);
      }

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEditing ? 'Produk berhasil diperbarui' : 'Produk baru berhasil ditambahkan'),
          backgroundColor: AppColors.primaryTeal,
        ),
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
              ProductRepository.instance.deleteProduct(widget.product!.id);
              ApiService.instance.delete('/products/${widget.product!.id}').catchError((_) => null);
              Navigator.pop(ctx);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Produk berhasil dihapus')),
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

    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_a_photo_rounded, color: AppColors.primaryTeal, size: 28),
          SizedBox(height: 4),
          Text(
            'Upload Foto',
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.primaryTeal),
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        top: 16,
        left: 20,
        right: 20,
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
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.lightTealBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _isEditing ? 'Edit Menu Produk' : 'Tambah Menu Baru',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.darkText,
                ),
              ),
              if (_isEditing)
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, color: AppColors.destructive),
                  onPressed: _handleDelete,
                )
              else
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
            ],
          ),
          const Divider(height: 1, color: AppColors.lightTealBorder),
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
                    Text(
                      'Foto / Gambar Menu *',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.darkText,
                      ),
                    ),
                    const SizedBox(height: 8),

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Live Thumbnail Box (Tappable to pick image)
                        GestureDetector(
                          onTap: _showImageSourcePicker,
                          child: Container(
                            width: 88,
                            height: 88,
                            decoration: BoxDecoration(
                              color: AppColors.tealBackgrounds,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.lightTealBorder, width: 1.5),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: _buildImagePreviewWidget(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),

                        // Upload Action Buttons
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              ElevatedButton.icon(
                                onPressed: _showImageSourcePicker,
                                icon: const Icon(Icons.cloud_upload_rounded, size: 18),
                                label: Text(
                                  _pickedImageBytes != null || (_currentImageUrl != null && _currentImageUrl!.isNotEmpty)
                                      ? 'Ganti Foto'
                                      : 'Pilih Foto (Galeri/Kamera)',
                                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryTeal,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _imageUrlController,
                                style: GoogleFonts.inter(fontSize: 12),
                                decoration: InputDecoration(
                                  hintText: 'Atau tempel link URL...',
                                  hintStyle: GoogleFonts.inter(fontSize: 11, color: AppColors.mutedText),
                                  filled: true,
                                  fillColor: AppColors.tealBackgrounds,
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(color: AppColors.lightTealBorder),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(color: AppColors.lightTealBorder),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(color: AppColors.primaryTeal, width: 1.5),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Preset Image Badges
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
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected ? Colors.white : AppColors.darkText,
                                ),
                              ),
                              avatar: const Icon(Icons.image_outlined, size: 14),
                              backgroundColor: isSelected ? AppColors.primaryTeal : AppColors.tealBackgrounds,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side: BorderSide(
                                  color: isSelected ? AppColors.primaryTeal : AppColors.lightTealBorder,
                                ),
                              ),
                              onPressed: () => _onSelectPresetImage(p['url']!),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 16),

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
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isSel ? Colors.white : AppColors.darkText,
                            ),
                          ),
                          selected: isSel,
                          selectedColor: AppColors.primaryTeal,
                          backgroundColor: AppColors.tealBackgrounds,
                          side: BorderSide(
                            color: isSel ? AppColors.primaryTeal : AppColors.lightTealBorder,
                          ),
                          onSelected: (_) => setState(() => _selectedCategory = cat),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),

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
                                style: GoogleFonts.inter(fontSize: 14),
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
                  ],
                ),
              ),
            ),
          ),

          // Submit Button
          ElevatedButton(
            onPressed: _isLoading ? null : _handleSave,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryTeal,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: _isLoading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text(
                    _isEditing ? 'Simpan Perubahan' : 'Tambah ke Menu POS',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 15),
                  ),
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
        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.darkText),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, {String? prefix}) {
    return InputDecoration(
      hintText: hint,
      prefixText: prefix,
      hintStyle: GoogleFonts.inter(fontSize: 13, color: AppColors.mutedText.withValues(alpha: 0.6)),
      filled: true,
      fillColor: AppColors.tealBackgrounds,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.lightTealBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.lightTealBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.primaryTeal, width: 1.5),
      ),
    );
  }
}
