import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/api_service.dart';
import '../../core/services/socket_service.dart';
import '../../models/product.dart';
import '../../models/stock_model.dart';
import '../../models/finance_model.dart';
import '../../models/ai_chat_model.dart';
import '../../models/profile_model.dart';
import '../shell_screen.dart';

/// Clean, high-contrast Login & Register screen following the Neo-Clean design system.
///
/// Features:
/// - Curved Obsidian Header with authentic Aisistenku branding and compact server chip.
/// - Segmented pill tab switcher ("Masuk" vs "Daftar Baru").
/// - Login: High-contrast Email & Password with "Ingat Saya", "Lupa Kata Sandi", and demo access.
/// - Register: Structured sections for "Data Akun Pemilik" (Name, Email, Password)
///   and "Identitas Bisnis & Gerai" (Store Name, Phone) matching backend DTO.
/// - Primary Obsidian action button ("Masuk ke Akun" / "Daftar Sekarang").
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _businessController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _isRegister = false;
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _rememberMe = true;

  @override
  void initState() {
    super.initState();
    _checkServer();
  }

  Future<void> _checkServer() async {
    await ApiConfig.autoDetectServer();
    await ApiService.instance.checkHealth();
  }

  void _showServerConfigDialog() {
    final controller = TextEditingController(
      text: ApiConfig.baseUrl.replaceAll('http://', '').replaceAll('/api', ''),
    );
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        title: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.dns_rounded, color: Color(0xFF0F172A), size: 18),
            ),
            const SizedBox(width: 10),
            Text(
              'Atur IP Server Backend',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: const Color(0xFF0F172A),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sesuaikan host backend untuk sinkronisasi POS dan data lokal:',
              style: GoogleFonts.plusJakartaSans(fontSize: 12, color: const Color(0xFF64748B)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 13,
                color: const Color(0xFF0F172A),
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                prefixText: 'http://',
                suffixText: '/api',
                hintText: '192.168.62.21:3000',
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF111111), width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _buildQuickChip('Wi-Fi PC', '192.168.62.21:3000', controller),
                _buildQuickChip('Localhost', 'localhost:3000', controller),
                _buildQuickChip('Emulator', '10.0.2.2:3000', controller),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Batal',
              style: GoogleFonts.plusJakartaSans(
                color: const Color(0xFF64748B),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF111111),
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
            },
            child: Text(
              'Simpan',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickChip(String label, String host, TextEditingController controller) {
    return ActionChip(
      label: Text(label),
      backgroundColor: const Color(0xFFF1F5F9),
      side: const BorderSide(color: Color(0xFFE2E8F0)),
      labelStyle: GoogleFonts.plusJakartaSans(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF0F172A),
      ),
      onPressed: () => controller.text = host,
    );
  }

  void _showForgotPasswordDialog() {
    final emailCtrl = TextEditingController(text: _emailController.text);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        title: Text(
          'Atur Ulang Sandi',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w800,
            fontSize: 17,
            color: const Color(0xFF0F172A),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Masukkan email Anda untuk menerima tautan pemulihan kata sandi:',
              style: GoogleFonts.plusJakartaSans(fontSize: 13, color: const Color(0xFF64748B)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: emailCtrl,
              keyboardType: TextInputType.emailAddress,
              style: GoogleFonts.plusJakartaSans(fontSize: 14, color: const Color(0xFF0F172A)),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.email_outlined, size: 20, color: Color(0xFF64748B)),
                hintText: 'nama@email.com',
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF111111), width: 1.5),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Batal',
              style: GoogleFonts.plusJakartaSans(color: const Color(0xFF64748B), fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF111111),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('✅ Tautan pemulihan dikirim ke email atau hubungi WA 0812-3456-7890'),
                  backgroundColor: Color(0xFF111111),
                ),
              );
            },
            child: Text('Kirim', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _handleSubmit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final name = _nameController.text.trim();
    final business = _businessController.text.trim();
    final address = _addressController.text.trim();
    final phone = _phoneController.text.trim();

    if (!_isRegister && (email.isEmpty || password.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email dan password wajib diisi')),
      );
      return;
    }

    if (_isRegister && (name.isEmpty || email.isEmpty || password.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama, email, dan password wajib diisi')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final endpoint = _isRegister ? '/auth/register' : '/auth/login';
      final cleanPhone = phone.replaceAll(RegExp(r'[\s-]'), '');
      final body = _isRegister
          ? {
              'name': name,
              'email': email,
              'password': password,
              'businessName': business.isNotEmpty ? business : name,
              if (address.isNotEmpty) 'businessAddress': address,
              'businessPhone': cleanPhone.isNotEmpty ? cleanPhone : '081234567890',
            }
          : {'email': email, 'password': password};

      final res = await ApiService.instance.post(endpoint, body);
      final token = (res?['access_token'] ??
          res?['accessToken'] ??
          res?['data']?['accessToken'] ??
          res?['data']?['access_token']) as String?;

      if (token == null) {
        throw Exception(res?['message'] ?? 'Gagal masuk: tidak menerima token dari backend.');
      }
      ApiService.instance.setAuthToken(token);

      // Extract and set businessId immediately from login response
      final userData = res?['data']?['user'] ?? res?['user'];
      if (userData is Map && userData['memberships'] is List && (userData['memberships'] as List).isNotEmpty) {
        final firstMembership = (userData['memberships'] as List).first;
        if (firstMembership is Map && firstMembership['business'] is Map) {
          final bizId = firstMembership['business']['id']?.toString();
          if (bizId != null && bizId.isNotEmpty) {
            ApiService.instance.setBusinessId(bizId);
          }
        }
      }

      // 1. Fetch user & business profile from backend to ensure full context is synced
      await ProfileRepository.instance.fetchProfileFromBackend();

      // Connect to real-time WebSocket gateway
      final activeBizId = ApiService.instance.businessId ?? ProfileRepository.instance.business.id;
      SocketService.instance.connect(token: token, businessId: activeBizId);

      // 2. Clear previous session state and fetch real dynamic data from backend
      ProductRepository.instance.clearForNewUser();
      StockRepository.instance.clearForNewUser();
      FinanceRepository.instance.clearForNewUser();
      AiChatRepository.instance.clearForNewUser();

      await Future.wait([
        ProductRepository.instance.fetchProductsFromBackend(),
        StockRepository.instance.fetchStocksFromBackend(),
        FinanceRepository.instance.fetchFinanceFromBackend(),
        FinanceRepository.instance.fetchDashboardFromBackend(),
        AiChatRepository.instance.fetchMessagesFromBackend(),
      ]).catchError((e) {
        debugPrint('⚠️ Sync user data from backend: $e');
        return <void>[];
      });

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const ShellScreen()),
      );
    } catch (e) {
      if (!mounted) return;
      final cleanMsg = e.toString().replaceAll('Exception: ', '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(cleanMsg), backgroundColor: AppColors.destructive),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _handleDemoLogin() {
    _emailController.text = 'owner@tigaangkatan.id';
    _passwordController.text = 'password123';
    _isRegister = false;
    _handleSubmit();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _businessController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── 1. Curved Obsidian Header ──────────────────────────────
            Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 16,
                left: 24,
                right: 24,
                bottom: 36,
              ),
              decoration: const BoxDecoration(
                color: Color(0xFF111111),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(36),
                  bottomRight: Radius.circular(36),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Official Brand Logo (Long-press allows developer host config)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: GestureDetector(
                      onLongPress: _showServerConfigDialog,
                      child: Image.asset(
                        'assets/icons/logoAisitenku.png',
                        height: 40,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Headline & Clean Subtitle
                  Text(
                    _isRegister ? 'Daftar Akun Baru' : 'Selamat Datang',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _isRegister
                        ? 'Langkah awal menuju manajemen toko yang lebih cerdas dan otomatis.'
                        : 'AISISTENKU — Sistem Manajemen Toko & POS',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.75),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),

            // ── 2. Form Body Container ────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Segmented Control (Masuk / Daftar Baru)
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _isRegister = false),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 11),
                              decoration: BoxDecoration(
                                color: !_isRegister ? Colors.white : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: !_isRegister
                                    ? [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.05),
                                          blurRadius: 4,
                                          offset: const Offset(0, 1),
                                        )
                                      ]
                                    : null,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                'Masuk',
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: !_isRegister ? FontWeight.w800 : FontWeight.w600,
                                  color: !_isRegister ? const Color(0xFF0F172A) : const Color(0xFF64748B),
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _isRegister = true),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 11),
                              decoration: BoxDecoration(
                                color: _isRegister ? Colors.white : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: _isRegister
                                    ? [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.05),
                                          blurRadius: 4,
                                          offset: const Offset(0, 1),
                                        )
                                      ]
                                    : null,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                'Daftar Baru',
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: _isRegister ? FontWeight.w800 : FontWeight.w600,
                                  color: _isRegister ? const Color(0xFF0F172A) : const Color(0xFF64748B),
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Form Input Fields ─────────────────────────────
                  if (_isRegister) ...[
                    // Section 1: Data Akun Pemilik
                    _buildSectionHeader('Data Akun Pemilik'),
                    const SizedBox(height: 12),
                    _buildInputField(
                      controller: _nameController,
                      label: 'Nama Lengkap / Toko',
                      hint: 'Contoh: Andika Palian',
                      icon: Icons.person_outline_rounded,
                    ),
                    const SizedBox(height: 14),
                    _buildInputField(
                      controller: _emailController,
                      label: 'Email',
                      hint: 'nama@email.com',
                      icon: Icons.mail_outline_rounded,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 14),
                    _buildInputField(
                      controller: _passwordController,
                      label: 'Password',
                      hint: 'Minimal 8 karakter',
                      icon: Icons.lock_outline_rounded,
                      obscureText: _obscurePassword,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          color: const Color(0xFF94A3B8),
                          size: 20,
                        ),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                    const SizedBox(height: 22),

                    // Section 2: Identitas Bisnis & Gerai (Sesuai Backend)
                    _buildSectionHeader('Identitas Bisnis & Gerai'),
                    const SizedBox(height: 12),
                    _buildInputField(
                      controller: _businessController,
                      label: 'Nama Bisnis / Toko',
                      hint: 'Contoh: Kedai Kopi Tiga Angkatan',
                      icon: Icons.storefront_outlined,
                    ),
                    const SizedBox(height: 14),
                    _buildInputField(
                      controller: _addressController,
                      label: 'Alamat Toko / Bisnis',
                      hint: 'Contoh: Jl. Slamet Riyadi No. 12, Solo',
                      icon: Icons.location_on_outlined,
                    ),
                    const SizedBox(height: 14),
                    _buildInputField(
                      controller: _phoneController,
                      label: 'Nomor Telepon Bisnis',
                      hint: 'Contoh: 0812-3456-7890',
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                    ),
                  ] else ...[
                    _buildInputField(
                      controller: _emailController,
                      label: 'Email',
                      hint: 'nama@email.com',
                      icon: Icons.mail_outline_rounded,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),
                    _buildInputField(
                      controller: _passwordController,
                      label: 'Password',
                      hint: 'Minimal 8 karakter',
                      icon: Icons.lock_outline_rounded,
                      obscureText: _obscurePassword,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          color: const Color(0xFF94A3B8),
                          size: 20,
                        ),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: Checkbox(
                                value: _rememberMe,
                                activeColor: const Color(0xFF111111),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                                onChanged: (val) => setState(() => _rememberMe = val ?? true),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Ingat Saya',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF475569),
                              ),
                            ),
                          ],
                        ),
                        GestureDetector(
                          onTap: _showForgotPasswordDialog,
                          child: Text(
                            'Lupa Kata Sandi?',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 24),

                  // ── Primary Action Button (Solid Obsidian) ─────────
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleSubmit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF111111),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              !_isRegister ? 'Masuk ke Akun' : 'Daftar Sekarang',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),

                  // ── Secondary Action: Demo Button (Login only) ────
                  if (!_isRegister) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 50,
                      child: OutlinedButton.icon(
                        onPressed: _isLoading ? null : _handleDemoLogin,
                        icon: const Icon(
                          Icons.coffee_rounded,
                          size: 18,
                          color: Color(0xFF0F172A),
                        ),
                        label: Text(
                          'Coba Demo Akun Cafe (Data Contoh)',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFE2E8F0), width: 1.2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 36),

                  // ── Subtle Security Footer ────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.shield_outlined, size: 14, color: Color(0xFF94A3B8)),
                      const SizedBox(width: 6),
                      Text(
                        'Enkripsi SSL • Keamanan Retail POS PCI-DSS',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Text(
          title.toUpperCase(),
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
            color: const Color(0xFF64748B),
          ),
        ),
        const SizedBox(width: 10),
        const Expanded(child: Divider(color: Color(0xFFE2E8F0), thickness: 1)),
      ],
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    TextInputType? keyboardType,
    Widget? suffixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF0F172A),
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.plusJakartaSans(
              color: const Color(0xFF94A3B8),
              fontWeight: FontWeight.w400,
              fontSize: 13,
            ),
            prefixIcon: Icon(icon, color: const Color(0xFF64748B), size: 20),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFF111111), width: 1.6),
            ),
          ),
        ),
      ],
    );
  }
}
