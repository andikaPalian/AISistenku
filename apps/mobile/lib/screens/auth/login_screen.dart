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
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isRegister = false;
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: AppColors.lightTealBorder, width: 1.2),
        ),
        title: Text(
          'Atur IP Server Backend',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            fontSize: 17,
            color: AppColors.darkText,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Masukkan IP PC atau pilih preset di bawah:',
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
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: AppColors.lightTealBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:
                      BorderSide(color: AppColors.primaryTeal, width: 1.5),
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
                  labelStyle: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.darkText,
                  ),
                  onPressed: () => controller.text = '192.168.62.21:3000',
                ),
                ActionChip(
                  label: const Text('USB adb (localhost:3000)'),
                  backgroundColor: AppColors.tealBackgrounds,
                  side: BorderSide(color: AppColors.lightTealBorder),
                  labelStyle: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.darkText,
                  ),
                  onPressed: () => controller.text = 'localhost:3000',
                ),
                ActionChip(
                  label: const Text('Emulator (10.0.2.2:3000)'),
                  backgroundColor: AppColors.tealBackgrounds,
                  side: BorderSide(color: AppColors.lightTealBorder),
                  labelStyle: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.darkText,
                  ),
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
              style: GoogleFonts.inter(
                color: AppColors.mutedText,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryTeal,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
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
                          ? '✅ Terhubung ke ${ApiConfig.baseUrl}'
                          : '⚠️ Belum terhubung, pastikan backend berjalan di IP tersebut',
                    ),
                    backgroundColor: _isServerConnected
                        ? AppColors.primaryTeal
                        : AppColors.destructive,
                  ),
                );
              }
            },
            child: Text(
              'Simpan & Tes',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleSubmit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final name = _nameController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email dan password wajib diisi')),
      );
      return;
    }

    if (_isRegister && name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama lengkap / toko wajib diisi')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final endpoint = _isRegister ? '/auth/register' : '/auth/login';
      final body = _isRegister
          ? {'name': name, 'email': email, 'password': password}
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

      // If logging in as demo account, load demo data; otherwise fetch user's isolated data from backend
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

        // Fetch live data from backend for this user
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
          content: Text(cleanMsg),
          backgroundColor: AppColors.destructive,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding:
                const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Top Status Bar: Server Connection Status ─────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    InkWell(
                      onTap: _showServerConfigDialog,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: _isServerConnected
                              ? AppColors.tealBackgrounds
                              : const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _isServerConnected
                                ? AppColors.lightTealBorder
                                : const Color(0xFFFDE68A),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(
                                color: _isServerConnected
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFFD97706),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _isServerConnected
                                  ? 'Server Online'
                                  : 'Atur Server IP',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: _isServerConnected
                                    ? AppColors.primaryTeal
                                    : const Color(0xFFD97706),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.settings_outlined,
                              size: 13,
                              color: _isServerConnected
                                  ? AppColors.primaryTeal
                                  : const Color(0xFFD97706),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // ── Logo & Authentic Branding Header ────────────────
                Center(
                  child: Container(
                    width: 84,
                    height: 84,
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.lightTealBorder,
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryTeal.withValues(alpha: 0.12),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Image.asset(
                      'assets/icons/logoAisitenku.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  _isRegister ? 'Daftar Akun Baru' : 'Selamat Datang',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AppColors.darkText,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _isRegister
                      ? 'Kelola bisnis Anda dengan mudah dan mandiri'
                      : 'AISISTENKU — Sistem Manajemen Toko & POS',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.mutedText,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 24),

                // ── Main Card Form Container ─────────────────────────
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.lightTealBorder,
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryTeal.withValues(alpha: 0.04),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Tab Switcher (Masuk / Daftar)
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.tealBackgrounds,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.lightTealBorder,
                            width: 1.1,
                          ),
                        ),
                        padding: const EdgeInsets.all(4),
                        child: Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _isRegister = false),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 9),
                                  decoration: BoxDecoration(
                                    color: !_isRegister
                                        ? AppColors.primaryTeal
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(9),
                                  ),
                                  child: Text(
                                    'Masuk',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.inter(
                                      fontSize: 13.5,
                                      fontWeight: !_isRegister
                                          ? FontWeight.w600
                                          : FontWeight.w500,
                                      color: !_isRegister
                                          ? Colors.white
                                          : AppColors.mutedText,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _isRegister = true),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 9),
                                  decoration: BoxDecoration(
                                    color: _isRegister
                                        ? AppColors.primaryTeal
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(9),
                                  ),
                                  child: Text(
                                    'Daftar Baru',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.inter(
                                      fontSize: 13.5,
                                      fontWeight: _isRegister
                                          ? FontWeight.w600
                                          : FontWeight.w500,
                                      color: _isRegister
                                          ? Colors.white
                                          : AppColors.mutedText,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Form Name (Only on Register)
                      if (_isRegister) ...[
                        _buildTextField(
                          controller: _nameController,
                          label: 'Nama Lengkap / Toko',
                          icon: Icons.person_outline_rounded,
                        ),
                        const SizedBox(height: 14),
                      ],

                      // Form Email
                      _buildTextField(
                        controller: _emailController,
                        label: 'Email',
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 14),

                      // Form Password
                      _buildTextField(
                        controller: _passwordController,
                        label: 'Password',
                        icon: Icons.lock_outline_rounded,
                        obscureText: _obscurePassword,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: AppColors.mutedText,
                            size: 20,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 22),

                      // Submit Button
                      ElevatedButton(
                        onPressed: _isLoading ? null : _handleSubmit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryTeal,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
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
                                _isRegister ? 'Daftar Sekarang' : 'Masuk ke Akun',
                                style: GoogleFonts.inter(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                      ),

                      const SizedBox(height: 14),

                      // Demo Mode Button
                      OutlinedButton.icon(
                        onPressed: _isLoading ? null : _handleDemoLogin,
                        icon: const Icon(
                          Icons.coffee_rounded,
                          size: 18,
                          color: AppColors.primaryTeal,
                        ),
                        label: Text(
                          'Coba Demo Akun Cafe (Data Contoh)',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryTeal,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: AppColors.tealBackgrounds,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: BorderSide(
                            color: AppColors.lightTealBorder,
                            width: 1.2,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
                Center(
                  child: Text(
                    'AISISTENKU • Versi 1.0.0',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppColors.mutedText,
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
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
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.darkText,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          style: GoogleFonts.inter(
            fontSize: 14,
            color: AppColors.darkText,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.tealBackgrounds,
            prefixIcon: Icon(icon, color: AppColors.primaryTeal, size: 20),
            suffixIcon: suffixIcon,
            contentPadding:
                const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.lightTealBorder, width: 1.1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: AppColors.primaryTeal, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.destructive),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: AppColors.destructive, width: 1.5),
            ),
            hintText: 'Masukkan $label',
            hintStyle: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.mutedText.withValues(alpha: 0.6),
            ),
          ),
        ),
      ],
    );
  }
}
