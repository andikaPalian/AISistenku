import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme/app_colors.dart';
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
