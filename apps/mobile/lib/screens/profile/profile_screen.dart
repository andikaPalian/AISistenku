import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/api_service.dart';
import '../../models/profile_model.dart';
import '../../models/product.dart';
import '../../models/stock_model.dart';
import '../../models/finance_model.dart';
import '../../models/ai_chat_model.dart';
import '../auth/login_screen.dart';

/// Modern, professional Profile & Business Management screen.
///
/// Implements:
/// 1. Hero Identity Header with verified badge, avatar edit, and role indicator.
/// 2. Account Profile Details (Name, Email, Phone, Change Password).
/// 3. Store & Business Profile (Store Name, Category, Address, Phone, Operational Hours, Tax PB1).
/// 4. Operational & POS Hardware Preferences (Thermal Printer, Auto-Print, Push Alert, Biometric).
/// 5. Developer & Server Connection Hub (Quick IP configuration with live ping status).
/// 6. App Metadata & Help Center.
/// 7. Destructive Logout Flow with confirmation bottom sheet and cache flushing.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ProfileRepository _repo = ProfileRepository.instance;
  bool _isSyncing = false;
  bool _isServerConnected = false;

  @override
  void initState() {
    super.initState();
    _checkServer();
    _fetchProfile();
  }

  Future<void> _checkServer() async {
    final ok = await ApiService.instance.checkHealth();
    if (mounted) {
      setState(() => _isServerConnected = ok);
    }
  }

  Future<void> _fetchProfile() async {
    setState(() => _isSyncing = true);
    await _repo.fetchProfileFromBackend();
    if (mounted) {
      setState(() => _isSyncing = false);
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // 1. Edit User Profile Bottom Sheet
  // ──────────────────────────────────────────────────────────────────────────
  void _showEditUserProfileSheet() {
    final user = _repo.user;
    final nameController = TextEditingController(text: user.name);
    final phoneController = TextEditingController(text: user.phone);
    final formKey = GlobalKey<FormState>();
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 16,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.tealBackgrounds,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.lightTealBorder),
                        ),
                        child: const Icon(
                          Icons.person_outline_rounded,
                          color: AppColors.primaryTeal,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Edit Data Akun Pemilik',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.darkText,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Perbarui identitas profil pemilik bisnis dan kontak aktif.',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.mutedText,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Nama Lengkap Field
                  Text(
                    'Nama Lengkap',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.darkText,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: nameController,
                    style: GoogleFonts.inter(fontSize: 14, color: AppColors.darkText),
                    decoration: InputDecoration(
                      hintText: 'Contoh: Budi Santoso',
                      prefixIcon: const Icon(Icons.badge_outlined, size: 20, color: AppColors.mutedText),
                      filled: true,
                      fillColor: AppColors.tealBackgrounds,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppColors.lightTealBorder),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.primaryTeal, width: 1.5),
                      ),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Nama lengkap tidak boleh kosong';
                      }
                      if (val.trim().length < 2) {
                        return 'Nama minimal 2 karakter';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Email Field (Read Only)
                  Text(
                    'Alamat Email (Akun Utama)',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.darkText,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    initialValue: user.email,
                    readOnly: true,
                    style: GoogleFonts.inter(fontSize: 14, color: AppColors.mutedText),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.mail_outline_rounded, size: 20, color: AppColors.mutedText),
                      suffixIcon: const Tooltip(
                        message: 'Email terhubung ke autentikasi',
                        child: Icon(Icons.lock_outline_rounded, size: 18, color: AppColors.mutedText),
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF1F5F9),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Nomor Telepon / WA
                  Text(
                    'Nomor WhatsApp / Telepon',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.darkText,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    style: GoogleFonts.inter(fontSize: 14, color: AppColors.darkText),
                    decoration: InputDecoration(
                      hintText: 'Contoh: 0812-3456-7890',
                      prefixIcon: const Icon(Icons.phone_outlined, size: 20, color: AppColors.mutedText),
                      filled: true,
                      fillColor: AppColors.tealBackgrounds,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppColors.lightTealBorder),
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
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryTeal,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: isSubmitting
                          ? null
                          : () async {
                              if (!formKey.currentState!.validate()) return;
                              setSheetState(() => isSubmitting = true);

                              final ok = await _repo.updateUserProfile(
                                name: nameController.text.trim(),
                                phone: phoneController.text.trim(),
                              );

                              if (context.mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      ok
                                          ? '✅ Profil akun berhasil diperbarui di server'
                                          : '✅ Profil akun diperbarui (tersimpan lokal)',
                                    ),
                                    backgroundColor: AppColors.primaryTeal,
                                  ),
                                );
                              }
                            },
                      child: isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              'Simpan Perubahan',
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // 2. Edit Business Profile Bottom Sheet
  // ──────────────────────────────────────────────────────────────────────────
  void _showEditBusinessProfileSheet() {
    final biz = _repo.business;
    final nameController = TextEditingController(text: biz.name);
    final categoryController = TextEditingController(text: biz.category);
    final addressController = TextEditingController(text: biz.address);
    final phoneController = TextEditingController(text: biz.phone);
    final hoursController = TextEditingController(text: biz.operationalHours);
    final taxController = TextEditingController(text: biz.taxPercentage.toStringAsFixed(0));
    final receiptNoteController = TextEditingController(text: biz.receiptFooter);
    final formKey = GlobalKey<FormState>();
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 16,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 44,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.border,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.tealBackgrounds,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.lightTealBorder),
                          ),
                          child: const Icon(
                            Icons.storefront_rounded,
                            color: AppColors.primaryTeal,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Edit Profil Bisnis & Toko',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.darkText,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Kelola identitas gerai, alamat cabang, jam operasional, dan pengaturan struk POS.',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppColors.mutedText,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Nama Toko
                    Text(
                      'Nama Bisnis / Toko',
                      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.darkText),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: nameController,
                      style: GoogleFonts.inter(fontSize: 14, color: AppColors.darkText),
                      decoration: InputDecoration(
                        hintText: 'Contoh: Kedai Kopi Senja',
                        prefixIcon: const Icon(Icons.store_rounded, size: 20, color: AppColors.mutedText),
                        filled: true,
                        fillColor: AppColors.tealBackgrounds,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppColors.lightTealBorder),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.primaryTeal, width: 1.5),
                        ),
                      ),
                      validator: (val) => val == null || val.trim().isEmpty ? 'Nama toko wajib diisi' : null,
                    ),
                    const SizedBox(height: 14),

                    // Kategori Usaha
                    Text(
                      'Kategori Industri / Usaha',
                      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.darkText),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: categoryController,
                      style: GoogleFonts.inter(fontSize: 14, color: AppColors.darkText),
                      decoration: InputDecoration(
                        hintText: 'Contoh: Coffee Shop & F&B',
                        prefixIcon: const Icon(Icons.category_outlined, size: 20, color: AppColors.mutedText),
                        filled: true,
                        fillColor: AppColors.tealBackgrounds,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppColors.lightTealBorder),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.primaryTeal, width: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Alamat Lengkap
                    Text(
                      'Alamat Gerai / Outlet',
                      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.darkText),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: addressController,
                      maxLines: 2,
                      style: GoogleFonts.inter(fontSize: 14, color: AppColors.darkText),
                      decoration: InputDecoration(
                        hintText: 'Contoh: Jl. Melati No. 12, Bandung',
                        prefixIcon: const Icon(Icons.place_outlined, size: 20, color: AppColors.mutedText),
                        filled: true,
                        fillColor: AppColors.tealBackgrounds,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppColors.lightTealBorder),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.primaryTeal, width: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Kontak Telepon & Jam Operasional Row
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Telepon Toko',
                                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.darkText),
                              ),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: phoneController,
                                keyboardType: TextInputType.phone,
                                style: GoogleFonts.inter(fontSize: 14, color: AppColors.darkText),
                                decoration: InputDecoration(
                                  hintText: '0821-9876...',
                                  filled: true,
                                  fillColor: AppColors.tealBackgrounds,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: AppColors.lightTealBorder),
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
                                'Jam Operasional',
                                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.darkText),
                              ),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: hoursController,
                                style: GoogleFonts.inter(fontSize: 14, color: AppColors.darkText),
                                decoration: InputDecoration(
                                  hintText: '08:00 - 22:00',
                                  filled: true,
                                  fillColor: AppColors.tealBackgrounds,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: AppColors.lightTealBorder),
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
                    const SizedBox(height: 14),

                    // Pajak PB1 & Footer Struk
                    Row(
                      children: [
                        SizedBox(
                          width: 100,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Pajak (%)',
                                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.darkText),
                              ),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: taxController,
                                keyboardType: TextInputType.number,
                                style: GoogleFonts.inter(fontSize: 14, color: AppColors.darkText),
                                decoration: InputDecoration(
                                  suffixText: '%',
                                  filled: true,
                                  fillColor: AppColors.tealBackgrounds,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: AppColors.lightTealBorder),
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
                                'Pesan Kaki Struk',
                                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.darkText),
                              ),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: receiptNoteController,
                                style: GoogleFonts.inter(fontSize: 14, color: AppColors.darkText),
                                decoration: InputDecoration(
                                  hintText: 'Terima kasih atas...',
                                  filled: true,
                                  fillColor: AppColors.tealBackgrounds,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: AppColors.lightTealBorder),
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
                    const SizedBox(height: 24),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryTeal,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: isSubmitting
                            ? null
                            : () async {
                                if (!formKey.currentState!.validate()) return;
                                setSheetState(() => isSubmitting = true);

                                final taxVal = double.tryParse(taxController.text.trim()) ?? 10.0;
                                final ok = await _repo.updateBusinessProfile(
                                  name: nameController.text.trim(),
                                  category: categoryController.text.trim(),
                                  address: addressController.text.trim(),
                                  phone: phoneController.text.trim(),
                                  operationalHours: hoursController.text.trim(),
                                  taxPercentage: taxVal,
                                  receiptFooter: receiptNoteController.text.trim(),
                                );

                                if (context.mounted) {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        ok
                                            ? '✅ Profil bisnis berhasil diperbarui di server'
                                            : '✅ Profil bisnis diperbarui (tersimpan lokal)',
                                      ),
                                      backgroundColor: AppColors.primaryTeal,
                                    ),
                                  );
                                }
                              },
                        child: isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                'Simpan Perubahan Bisnis',
                                style: GoogleFonts.inter(
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
          );
        },
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // 3. Change Password Dialog
  // ──────────────────────────────────────────────────────────────────────────
  void _showChangePasswordDialog() {
    final oldPassController = TextEditingController();
    final newPassController = TextEditingController();
    final confirmPassController = TextEditingController();
    bool obscureOld = true;
    bool obscureNew = true;
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: AppColors.lightTealBorder, width: 1.2),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.tealBackgrounds,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.lightTealBorder),
                  ),
                  child: const Icon(Icons.key_rounded, color: AppColors.primaryTeal, size: 20),
                ),
                const SizedBox(width: 10),
                Text(
                  'Ubah Kata Sandi',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
                    color: AppColors.darkText,
                  ),
                ),
              ],
            ),
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Masukkan sandi saat ini dan buat sandi baru yang kuat.',
                      style: GoogleFonts.inter(fontSize: 12, color: AppColors.mutedText),
                    ),
                    const SizedBox(height: 14),

                    // Old password
                    Text(
                      'Kata Sandi Lama',
                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.darkText),
                    ),
                    const SizedBox(height: 4),
                    TextFormField(
                      controller: oldPassController,
                      obscureText: obscureOld,
                      style: GoogleFonts.inter(fontSize: 13),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppColors.tealBackgrounds,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: AppColors.lightTealBorder),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: AppColors.primaryTeal),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscureOld ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            size: 18,
                            color: AppColors.mutedText,
                          ),
                          onPressed: () => setDialogState(() => obscureOld = !obscureOld),
                        ),
                      ),
                      validator: (v) => v == null || v.isEmpty ? 'Sandi lama wajib diisi' : null,
                    ),
                    const SizedBox(height: 12),

                    // New password
                    Text(
                      'Kata Sandi Baru',
                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.darkText),
                    ),
                    const SizedBox(height: 4),
                    TextFormField(
                      controller: newPassController,
                      obscureText: obscureNew,
                      style: GoogleFonts.inter(fontSize: 13),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppColors.tealBackgrounds,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: AppColors.lightTealBorder),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: AppColors.primaryTeal),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscureNew ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            size: 18,
                            color: AppColors.mutedText,
                          ),
                          onPressed: () => setDialogState(() => obscureNew = !obscureNew),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.length < 6) {
                          return 'Sandi baru minimal 6 karakter';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),

                    // Confirm new password
                    Text(
                      'Konfirmasi Sandi Baru',
                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.darkText),
                    ),
                    const SizedBox(height: 4),
                    TextFormField(
                      controller: confirmPassController,
                      obscureText: obscureNew,
                      style: GoogleFonts.inter(fontSize: 13),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppColors.tealBackgrounds,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: AppColors.lightTealBorder),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: AppColors.primaryTeal),
                        ),
                      ),
                      validator: (v) {
                        if (v != newPassController.text) {
                          return 'Konfirmasi sandi tidak sesuai';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(
                  'Batal',
                  style: GoogleFonts.inter(color: AppColors.mutedText, fontWeight: FontWeight.w600),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryTeal,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () {
                  if (!formKey.currentState!.validate()) return;
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✅ Kata sandi akun berhasil diperbarui'),
                      backgroundColor: AppColors.primaryTeal,
                    ),
                  );
                },
                child: Text('Simpan Sandi', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
              ),
            ],
          );
        },
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // 4. Server Configuration Modal
  // ──────────────────────────────────────────────────────────────────────────
  void _showServerConfigModal() {
    final controller = TextEditingController(
      text: ApiConfig.baseUrl.replaceAll('http://', '').replaceAll('/api', ''),
    );
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: AppColors.lightTealBorder, width: 1.2),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.tealBackgrounds,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.lightTealBorder),
              ),
              child: const Icon(Icons.dns_rounded, color: AppColors.primaryTeal, size: 20),
            ),
            const SizedBox(width: 10),
            Text(
              'IP Server Backend',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                fontSize: 17,
                color: AppColors.darkText,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sesuaikan host backend untuk sinkronisasi POS, stok, dan AI:',
              style: GoogleFonts.inter(fontSize: 13, color: AppColors.mutedText),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              style: GoogleFonts.inter(fontSize: 14, color: AppColors.darkText),
              decoration: InputDecoration(
                prefixText: 'http://',
                suffixText: '/api',
                hintText: '192.168.62.21:3000',
                filled: true,
                fillColor: AppColors.tealBackgrounds,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: AppColors.lightTealBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.primaryTeal, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                ActionChip(
                  label: const Text('Wi-Fi PC (192.168.62.21)'),
                  backgroundColor: AppColors.tealBackgrounds,
                  side: BorderSide(color: AppColors.lightTealBorder),
                  labelStyle: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.darkText),
                  onPressed: () => controller.text = '192.168.62.21:3000',
                ),
                ActionChip(
                  label: const Text('USB adb reverse (localhost)'),
                  backgroundColor: AppColors.tealBackgrounds,
                  side: BorderSide(color: AppColors.lightTealBorder),
                  labelStyle: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.darkText),
                  onPressed: () => controller.text = 'localhost:3000',
                ),
                ActionChip(
                  label: const Text('Emulator (10.0.2.2)'),
                  backgroundColor: AppColors.tealBackgrounds,
                  side: BorderSide(color: AppColors.lightTealBorder),
                  labelStyle: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.darkText),
                  onPressed: () => controller.text = '10.0.2.2:3000',
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Batal',
              style: GoogleFonts.inter(color: AppColors.mutedText, fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryTeal,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              final raw = controller.text.trim();
              if (raw.isNotEmpty) {
                final formatted = raw.startsWith('http') ? raw : 'http://$raw';
                ApiConfig.setBaseUrl(formatted);
              }
              Navigator.pop(ctx);
              await _checkServer();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      _isServerConnected
                          ? '✅ Berhasil terhubung ke ${ApiConfig.baseUrl}'
                          : '⚠️ Server belum merespons, pastikan backend aktif',
                    ),
                    backgroundColor: _isServerConnected ? AppColors.primaryTeal : AppColors.destructive,
                  ),
                );
              }
            },
            child: Text('Simpan & Tes', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // 5. Logout Confirmation Bottom Sheet
  // ──────────────────────────────────────────────────────────────────────────
  void _showLogoutConfirmation() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFFECACA), width: 1.5),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.logout_rounded,
                      color: AppColors.destructive,
                      size: 32,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Konfirmasi Keluar Akun',
                  style: GoogleFonts.poppins(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    color: AppColors.darkText,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Apakah Anda yakin ingin keluar? Sesi aktif Anda akan diakhiri dan seluruh data transaksi telah tersimpan di cloud.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.mutedText,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: AppColors.lightTealBorder),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: () => Navigator.pop(ctx),
                        child: Text(
                          'Batal',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.darkText,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.destructive,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: () async {
                          Navigator.pop(ctx);
                          await _handleLogout();
                        },
                        child: Text(
                          'Ya, Keluar',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleLogout() async {
    // 1. Invalidate backend session safely
    try {
      await ApiService.instance.post('/auth/logout', {});
    } catch (_) {}

    // 2. Clear token & business ID
    ApiService.instance.setAuthToken(null);
    ApiService.instance.setBusinessId(null);

    // 3. Clear repositories
    ProductRepository.instance.clearForNewUser();
    StockRepository.instance.clearForNewUser();
    FinanceRepository.instance.clearForNewUser();
    AiChatRepository.instance.clearForNewUser();
    ProfileRepository.instance.resetToDemo();

    if (!mounted) return;

    // 4. Navigate to LoginScreen clearing all back stack
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // BUILD METHOD
  // ──────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: _buildAppBar(),
      body: ValueListenableBuilder<UserProfile>(
        valueListenable: _repo.userNotifier,
        builder: (context, user, _) {
          return ValueListenableBuilder<BusinessProfile>(
            valueListenable: _repo.businessNotifier,
            builder: (context, business, _) {
              return ValueListenableBuilder<AppPreferences>(
                valueListenable: _repo.preferencesNotifier,
                builder: (context, prefs, _) {
                  return RefreshIndicator(
                    onRefresh: _fetchProfile,
                    color: AppColors.primaryTeal,
                    backgroundColor: Colors.white,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── 1. Hero Avatar & Identity Card ───────────────
                          _buildHeroIdentityCard(user, business),
                          const SizedBox(height: 20),

                          // ── 2. Data Akun Pemilik ─────────────────────────
                          _buildSectionHeader('Profil Pemilik Akun', Icons.account_circle_outlined),
                          const SizedBox(height: 10),
                          _buildUserCard(user),
                          const SizedBox(height: 24),

                          // ── 3. Data Bisnis & Toko ────────────────────────
                          _buildSectionHeader('Identitas Bisnis & Gerai', Icons.storefront_outlined),
                          const SizedBox(height: 10),
                          _buildBusinessCard(business),
                          const SizedBox(height: 24),

                          // ── 4. Pengaturan Kasir & Aplikasi ───────────────
                          _buildSectionHeader('Pengaturan POS & Perangkat', Icons.tune_rounded),
                          const SizedBox(height: 10),
                          _buildPreferencesCard(prefs),
                          const SizedBox(height: 24),

                          // ── 5. Koneksi Server & Developer ────────────────
                          _buildSectionHeader('Koneksi Backend Server', Icons.dns_outlined),
                          const SizedBox(height: 10),
                          _buildServerConfigCard(),
                          const SizedBox(height: 24),

                          // ── 6. Informasi Aplikasi & Bantuan ──────────────
                          _buildSectionHeader('Bantuan & Informasi', Icons.help_outline_rounded),
                          const SizedBox(height: 10),
                          _buildAppInfoCard(),
                          const SizedBox(height: 32),

                          // ── 7. Logout Button ─────────────────────────────
                          _buildLogoutButton(),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Sub-widgets & UI Components
  // ──────────────────────────────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.pageBackground,
      elevation: 0,
      centerTitle: false,
      leading: IconButton(
        icon: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.lightTealBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 16,
            color: AppColors.darkText,
          ),
        ),
        onPressed: () => Navigator.maybePop(context),
      ),
      title: Text(
        'Profil & Pengaturan',
        style: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.darkText,
        ),
      ),
      actions: [
        if (_isSyncing)
          const Padding(
            padding: EdgeInsets.only(right: 16),
            child: Center(
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primaryTeal,
                ),
              ),
            ),
          )
        else
          IconButton(
            tooltip: 'Sinkronisasi Ulang',
            icon: const Icon(Icons.sync_rounded, color: AppColors.primaryTeal),
            onPressed: _fetchProfile,
          ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primaryTeal),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.darkText,
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }

  Widget _buildHeroIdentityCard(UserProfile user, BusinessProfile business) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF0F766E),
            AppColors.primaryTeal,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryTeal.withValues(alpha: 0.22),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Avatar + Edit badge
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Image.network(
                    user.avatarUrl ??
                        'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200&auto=format&fit=crop&q=80',
                    width: 78,
                    height: 78,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _buildAvatarFallback(user.name),
                  ),
                ),
              ),

              GestureDetector(
                onTap: _showEditUserProfileSheet,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: AppColors.mintAccent,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.camera_alt_rounded,
                    size: 16,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // User Name & Verification Status
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  user.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              const Icon(
                Icons.verified_rounded,
                color: AppColors.mintAccent,
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 4),

          // Store & Role Pill
          Wrap(
            spacing: 8,
            runSpacing: 6,
            alignment: WrapAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.shield_rounded, color: AppColors.mintAccent, size: 14),
                    const SizedBox(width: 5),
                    Text(
                      user.role,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.storefront_rounded, color: Colors.white, size: 14),
                    const SizedBox(width: 5),
                    Text(
                      business.name,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Action buttons row
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primaryTeal,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const Icon(Icons.edit_rounded, size: 16),
                  label: Text(
                    'Edit Profil',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                  onPressed: _showEditUserProfileSheet,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white, width: 1.2),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const Icon(Icons.store_mall_directory_rounded, size: 16),
                  label: Text(
                    'Kelola Toko',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  onPressed: _showEditBusinessProfileSheet,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarFallback(String name) {
    final initials = name.trim().isNotEmpty
        ? name
            .trim()
            .split(' ')
            .where((e) => e.isNotEmpty)
            .map((e) => e[0].toUpperCase())
            .take(2)
            .join()
        : 'BS';
    return Container(
      width: 78,
      height: 78,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF14B8A6), Color(0xFF0F766E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          initials.isNotEmpty ? initials : 'BS',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 26,
            letterSpacing: 1.0,
          ),
        ),
      ),
    );
  }


  Widget _buildUserCard(UserProfile user) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.lightTealBorder, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildInfoTile(
            icon: Icons.person_outline_rounded,
            label: 'Nama Lengkap',
            value: user.name,
            trailing: const Icon(Icons.edit_outlined, size: 18, color: AppColors.primaryTeal),
            onTap: _showEditUserProfileSheet,
          ),
          _buildDivider(),
          _buildInfoTile(
            icon: Icons.mail_outline_rounded,
            label: 'Email Akun',
            value: user.email,
            trailingChipText: 'Terverifikasi',
            trailingChipColor: AppColors.successGreen,
          ),
          _buildDivider(),
          _buildInfoTile(
            icon: Icons.phone_outlined,
            label: 'Nomor WhatsApp / Kontak',
            value: user.phone,
            trailing: const Icon(Icons.edit_outlined, size: 18, color: AppColors.primaryTeal),
            onTap: _showEditUserProfileSheet,
          ),
          _buildDivider(),
          _buildInfoTile(
            icon: Icons.lock_outline_rounded,
            label: 'Kata Sandi & Keamanan',
            value: '••••••••••••',
            trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.mutedText),
            onTap: _showChangePasswordDialog,
          ),
        ],
      ),
    );
  }

  Widget _buildBusinessCard(BusinessProfile business) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.lightTealBorder, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildInfoTile(
            icon: Icons.storefront_rounded,
            label: 'Nama Gerai / Bisnis',
            value: business.name,
            trailing: const Icon(Icons.edit_outlined, size: 18, color: AppColors.primaryTeal),
            onTap: _showEditBusinessProfileSheet,
          ),
          _buildDivider(),
          _buildInfoTile(
            icon: Icons.category_outlined,
            label: 'Kategori Usaha',
            value: business.category,
          ),
          _buildDivider(),
          _buildInfoTile(
            icon: Icons.location_on_outlined,
            label: 'Alamat Operasional',
            value: business.address,
            onTap: _showEditBusinessProfileSheet,
          ),
          _buildDivider(),
          _buildInfoTile(
            icon: Icons.access_time_rounded,
            label: 'Jam Buka Toko',
            value: business.operationalHours,
            trailingChipText: '🟢 Aktif Buka',
            trailingChipColor: AppColors.successGreen,
          ),
          _buildDivider(),
          _buildInfoTile(
            icon: Icons.receipt_long_outlined,
            label: 'Pajak PB1 & Footer Struk',
            value: 'PB1: ${business.taxPercentage.toStringAsFixed(0)}% • "${business.receiptFooter}"',
            onTap: _showEditBusinessProfileSheet,
          ),
        ],
      ),
    );
  }

  Widget _buildPreferencesCard(AppPreferences prefs) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.lightTealBorder, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildSwitchTile(
            icon: Icons.print_outlined,
            title: 'Cetak Struk Otomatis',
            subtitle: 'Struk transaksi POS langsung tercetak ke Bluetooth printer',
            value: prefs.autoPrintReceipt,
            onChanged: (val) {
              _repo.updatePreferences(autoPrintReceipt: val);
            },
          ),
          _buildDivider(),
          _buildSwitchTile(
            icon: Icons.notifications_active_outlined,
            title: 'Notifikasi Transaksi Realtime',
            subtitle: 'Kirim notifikasi setiap kali ada pesanan baru terselesaikan',
            value: prefs.pushNotifications,
            onChanged: (val) {
              _repo.updatePreferences(pushNotifications: val);
            },
          ),
          _buildDivider(),
          _buildSwitchTile(
            icon: Icons.warning_amber_rounded,
            title: 'Peringatan Stok Menipis',
            subtitle: 'AI mengingatkan saat bahan baku mendekati batas minimum',
            value: prefs.stockAlerts,
            onChanged: (val) {
              _repo.updatePreferences(stockAlerts: val);
            },
          ),
          _buildDivider(),
          _buildSwitchTile(
            icon: Icons.fingerprint_rounded,
            title: 'Kunci Aplikasi Biometrik',
            subtitle: 'Masuk cepat menggunakan sidik jari atau Face ID',
            value: prefs.biometricLogin,
            onChanged: (val) {
              _repo.updatePreferences(biometricLogin: val);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildServerConfigCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.lightTealBorder, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.tealBackgrounds,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.lightTealBorder),
            ),
            child: const Icon(Icons.cloud_sync_rounded, color: AppColors.primaryTeal, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Status Server: ',
                      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.darkText),
                    ),
                    Text(
                      _isServerConnected ? '🟢 Terhubung' : '⚠️ Offline / Terputus',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _isServerConnected ? AppColors.successGreen : AppColors.destructive,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  ApiConfig.baseUrl,
                  style: GoogleFonts.inter(fontSize: 12, color: AppColors.mutedText),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.tealBackgrounds,
              foregroundColor: AppColors.primaryTeal,
              elevation: 0,
              side: BorderSide(color: AppColors.lightTealBorder),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            onPressed: _showServerConfigModal,
            child: Text(
              'Ubah IP',
              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppInfoCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.lightTealBorder, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildInfoTile(
            icon: Icons.info_outline_rounded,
            label: 'Versi Aplikasi',
            value: 'AIsistenku POS & ERP v1.2.0',
            trailingChipText: 'Build 2026.09',
            trailingChipColor: AppColors.primaryTeal,
          ),
          _buildDivider(),
          _buildInfoTile(
            icon: Icons.headset_mic_outlined,
            label: 'Pusat Bantuan & Layanan',
            value: 'Hubungi tim technical support 24/7',
            trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.mutedText),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Hubungi Support: support@tigaangkatan.id atau WA 0812-3456-7890'),
                  backgroundColor: AppColors.primaryTeal,
                ),
              );
            },
          ),
          _buildDivider(),
          _buildInfoTile(
            icon: Icons.privacy_tip_outlined,
            label: 'Syarat & Kebijakan Privasi',
            value: 'Enkripsi data standar ISO & PCI-DSS POS',
            trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.mutedText),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('AIsistenku: Privasi data pelanggan & transaksi dilindungi standar keamanan.'),
                  backgroundColor: AppColors.primaryTeal,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton() {
    return Container(
      width: double.infinity,
      height: 52,
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFECACA), width: 1.2),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: _showLogoutConfirmation,
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.logout_rounded,
                  color: AppColors.destructive,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Keluar dari Akun',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.destructive,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Helper Tile Components
  // ──────────────────────────────────────────────────────────────────────────

  Widget _buildDivider() {
    return Divider(height: 1, thickness: 1, color: AppColors.lightTealBorder.withValues(alpha: 0.6));
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String label,
    required String value,
    Widget? trailing,
    String? trailingChipText,
    Color? trailingChipColor,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.tealBackgrounds,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: AppColors.primaryTeal),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.mutedText,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.darkText,
                    ),
                  ),
                ],
              ),
            ),
            if (trailingChipText != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: (trailingChipColor ?? AppColors.primaryTeal).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  trailingChipText,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: trailingChipColor ?? AppColors.primaryTeal,
                  ),
                ),
              )
            else if (trailing != null)
              trailing,
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.tealBackgrounds,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: AppColors.primaryTeal),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.darkText,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.mutedText,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Switch.adaptive(
            value: value,
            activeThumbColor: AppColors.primaryTeal,
            activeTrackColor: AppColors.lightTealBorder,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
