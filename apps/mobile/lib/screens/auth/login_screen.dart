import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/api_service.dart';
import '../../models/product.dart';
import '../../models/stock_model.dart';
import '../../models/finance_model.dart';
import '../../models/ai_chat_model.dart';
import '../../models/profile_model.dart';
import '../shell_screen.dart';

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
  final _phoneController = TextEditingController();

  bool _isRegister = false;
  int _registerStep = 1; // 1: Email/Pass, 2: Personal/Business Info
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _isServerConnected = false;

  @override
  void initState() {
    super.initState();
    _checkServer();
  }

  Future<void> _checkServer() async {
    await ApiConfig.autoDetectServer();
    final ok = await ApiService.instance.checkHealth();
    if (mounted) {
      setState(() => _isServerConnected = ok);
    }
  }

  void _showServerConfigDialog() {
    final controller = TextEditingController(
      text: ApiConfig.baseUrl.replaceAll('http://', '').replaceAll('/api', ''),
    );
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Atur IP Server Backend',
            style:
                GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: controller,
              decoration: InputDecoration(
                prefixText: 'http://',
                suffixText: '/api',
                hintText: '192.168.x.x:3000',
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                ActionChip(
                  label: const Text('Wi-Fi PC'),
                  onPressed: () => controller.text = '192.168.62.21:3000',
                ),
                ActionChip(
                  label: const Text('Localhost'),
                  onPressed: () => controller.text = 'localhost:3000',
                ),
                ActionChip(
                  label: const Text('Emulator'),
                  onPressed: () => controller.text = '10.0.2.2:3000',
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryTeal,
              foregroundColor: Colors.white,
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
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _handleNextStep() {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email dan password wajib diisi')),
      );
      return;
    }

    setState(() {
      _registerStep = 2;
    });
  }

  void _handleSubmit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final name = _nameController.text.trim();
    final business = _businessController.text.trim();
    final phone = _phoneController.text.trim();

    if (!_isRegister && (email.isEmpty || password.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email dan password wajib diisi')),
      );
      return;
    }

    if (_isRegister && (name.isEmpty || business.isEmpty || phone.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Data diri, toko, dan nomor telepon wajib diisi')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final endpoint = _isRegister ? '/auth/register' : '/auth/login';
      final body = _isRegister
          ? {
              'name': name,
              'email': email,
              'password': password,
              'businessName': business,
              'businessPhone': phone
            }
          : {'email': email, 'password': password};

      final res = await ApiService.instance.post(endpoint, body);
      final token = (res?['access_token'] ??
          res?['accessToken'] ??
          res?['data']?['accessToken'] ??
          res?['data']?['access_token']) as String?;

      if (token == null) {
        throw Exception(res?['message'] ??
            'Gagal masuk: tidak menerima token dari backend.');
      }
      ApiService.instance.setAuthToken(token);

      final isDemoAccount = email.toLowerCase() == 'owner@tigaangkatan.id';
      if (isDemoAccount) {
        ProductRepository.instance.loadDemoProducts();
        StockRepository.instance.loadDemoData();
        FinanceRepository.instance.loadDemoData();
        ProfileRepository.instance.resetToDemo();
      } else {
        ProductRepository.instance.clearForNewUser();
        StockRepository.instance.clearForNewUser();
        FinanceRepository.instance.clearForNewUser();
        AiChatRepository.instance.clearForNewUser();

        await Future.wait([
          ProductRepository.instance.fetchProductsFromBackend(),
          StockRepository.instance.fetchStocksFromBackend(),
          FinanceRepository.instance.fetchFinanceFromBackend(),
          AiChatRepository.instance.fetchMessagesFromBackend(),
          ProfileRepository.instance.fetchProfileFromBackend(),
        ]).catchError((e) {
          debugPrint('⚠️ Sync user data from backend: $e');
          return <void>[];
        });
      }

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const ShellScreen()),
      );
    } catch (e) {
      if (!mounted) return;
      final cleanMsg = e.toString().replaceAll('Exception: ', '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(cleanMsg), backgroundColor: AppColors.destructive),
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
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Elegant Header Section
          Container(
            padding:
                const EdgeInsets.only(top: 60, left: 24, right: 24, bottom: 40),
            decoration: const BoxDecoration(
              color: AppColors.primaryTeal,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(40),
                bottomRight: Radius.circular(40),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Image.asset(
                      'assets/icons/logoAisitenku.png',
                      height: 50,
                      color: Colors.white,
                    ),
                    InkWell(
                      onTap: _showServerConfigDialog,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                Text(
                  _isRegister
                      ? 'Mulai Perjalanan Bisnismu'
                      : 'Selamat Datang Kembali',
                  style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _isRegister
                      ? 'Langkah awal menuju manajemen toko yang lebih cerdas dan otomatis.'
                      : 'Masuk untuk mengelola produk, inventaris, dan keuangan Anda.',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),

          // Form Section
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Modern Segmented Control for Login/Register
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() {
                              _isRegister = false;
                              _registerStep = 1;
                            }),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: !_isRegister
                                    ? Colors.white
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: !_isRegister
                                    ? [
                                        BoxShadow(
                                            color: Colors.black
                                                .withValues(alpha: 0.05),
                                            blurRadius: 4)
                                      ]
                                    : null,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                'Masuk',
                                style: GoogleFonts.inter(
                                  fontWeight: !_isRegister
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                                  color: !_isRegister
                                      ? AppColors.darkText
                                      : Colors.grey.shade600,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _isRegister = true),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: _isRegister
                                    ? Colors.white
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: _isRegister
                                    ? [
                                        BoxShadow(
                                            color: Colors.black
                                                .withValues(alpha: 0.05),
                                            blurRadius: 4)
                                      ]
                                    : null,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                'Daftar Baru',
                                style: GoogleFonts.inter(
                                  fontWeight: _isRegister
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                                  color: _isRegister
                                      ? AppColors.darkText
                                      : Colors.grey.shade600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Form Fields
                  if (!_isRegister || (_isRegister && _registerStep == 1)) ...[
                    _buildInputField(
                      controller: _emailController,
                      label: 'Alamat Email',
                      hint: 'nama@email.com',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 20),
                    _buildInputField(
                      controller: _passwordController,
                      label: 'Kata Sandi',
                      hint: 'Minimal 8 karakter',
                      icon: Icons.lock_outline,
                      obscureText: _obscurePassword,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: Colors.grey,
                        ),
                        onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                  ],

                  if (_isRegister && _registerStep == 2) ...[
                    GestureDetector(
                      onTap: () => setState(() => _registerStep = 1),
                      child: Row(
                        children: [
                          const Icon(Icons.arrow_back_ios,
                              size: 14, color: AppColors.primaryTeal),
                          const SizedBox(width: 4),
                          Text('Kembali ke Email',
                              style: GoogleFonts.inter(
                                  color: AppColors.primaryTeal,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildInputField(
                      controller: _nameController,
                      label: 'Nama Lengkap Anda',
                      hint: 'Masukkan Nama Lengkap Anda',
                      icon: Icons.person_outline,
                    ),
                    const SizedBox(height: 20),
                    _buildInputField(
                      controller: _businessController,
                      label: 'Nama Toko / Bisnis',
                      hint: 'Contoh: Toko Maju Jaya',
                      icon: Icons.storefront_outlined,
                    ),
                    const SizedBox(height: 20),
                    _buildInputField(
                      controller: _phoneController,
                      label: 'Nomor Telepon Bisnis',
                      hint: 'Contoh: 08123456789',
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                    ),
                  ],

                  const SizedBox(height: 32),

                  // Action Buttons
                  ElevatedButton(
                    onPressed: _isLoading
                        ? null
                        : (_isRegister && _registerStep == 1)
                            ? _handleNextStep
                            : _handleSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryTeal,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2),
                          )
                        : Text(
                            (!_isRegister)
                                ? 'Masuk ke Akun'
                                : (_registerStep == 1)
                                    ? 'Lanjutkan ke Data Bisnis'
                                    : 'Selesaikan Pendaftaran',
                            style: GoogleFonts.inter(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                  ),

                  if (!_isRegister) ...[
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: _isLoading ? null : _handleDemoLogin,
                      icon: const Icon(Icons.coffee_rounded,
                          size: 20, color: AppColors.primaryTeal),
                      label: Text(
                        'Coba Mode Demo (Cafe)',
                        style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryTeal),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(
                            color: AppColors.primaryTeal, width: 1.5),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ]
                ],
              ),
            ),
          ),
        ],
      ),
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
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.darkText,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          style: GoogleFonts.inter(fontSize: 15, color: AppColors.darkText),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(color: Colors.grey.shade400),
            prefixIcon: Icon(icon, color: Colors.grey.shade500),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: Colors.grey.shade50,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide:
                  const BorderSide(color: AppColors.primaryTeal, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}
