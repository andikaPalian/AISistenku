import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/services/api_service.dart';
import '../../models/profile_model.dart';
import '../../models/product.dart';
import '../../models/stock_model.dart';
import '../../models/finance_model.dart';
import '../../models/ai_chat_model.dart';
import '../auth/login_screen.dart';
import 'widgets/profile_hero_card.dart';
import 'widgets/profile_info_card.dart';
import 'widgets/profile_sheets.dart';

/// Modern, professional Profile & Business Management screen.
///
/// Implements:
/// 1. Hero Identity Header with verified badge, avatar initials/photo, and store highlights.
/// 2. Account Profile Details (Name, Email, Phone, Change Password).
/// 3. Store & Business Profile (Store Name, Category, Address, Phone, Operational Hours, Tax PB1).
/// 4. Operational & POS Hardware Preferences (Auto-Print, Push Alert, Biometric).
/// 5. Developer & Server Connection Hub (Quick IP configuration with live ping status).
/// 6. App Metadata, Help Center & Privacy Security details.
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
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
                    color: const Color(0xFF22C55E),
                    backgroundColor: Colors.white,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── 1. Hero Identity Header ────────────────────────
                          ProfileHeroCard(
                            user: user,
                            business: business,
                            onEditProfile: () => ProfileSheets.showEditUserProfile(
                              context,
                              onSaved: () => setState(() {}),
                            ),
                            onManageStore: () => ProfileSheets.showEditBusinessProfile(
                              context,
                              onSaved: () => setState(() {}),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // ── 2. Data Akun Pemilik ───────────────────────────
                          const ProfileSectionHeader(
                            title: 'Profil Pemilik Akun',
                            icon: Icons.account_circle_outlined,
                          ),
                          const SizedBox(height: 10),
                          _buildUserCard(user),
                          const SizedBox(height: 24),

                          // ── 3. Data Bisnis & Toko ──────────────────────────
                          const ProfileSectionHeader(
                            title: 'Identitas Bisnis & Gerai',
                            icon: Icons.storefront_outlined,
                          ),
                          const SizedBox(height: 10),
                          _buildBusinessCard(business),
                          const SizedBox(height: 24),

                          // ── 4. Pengaturan Kasir & Aplikasi ─────────────────
                          const ProfileSectionHeader(
                            title: 'Pengaturan POS & Perangkat',
                            icon: Icons.tune_rounded,
                          ),
                          const SizedBox(height: 10),
                          _buildPreferencesCard(prefs),
                          const SizedBox(height: 24),

                          // ── 5. Koneksi Server & Developer ──────────────────
                          const ProfileSectionHeader(
                            title: 'Koneksi Backend Server',
                            icon: Icons.dns_outlined,
                          ),
                          const SizedBox(height: 10),
                          _buildServerConfigCard(),
                          const SizedBox(height: 24),

                          // ── 6. Informasi Aplikasi & Bantuan ────────────────
                          const ProfileSectionHeader(
                            title: 'Bantuan & Informasi',
                            icon: Icons.help_outline_rounded,
                          ),
                          const SizedBox(height: 10),
                          _buildAppInfoCard(),
                          const SizedBox(height: 32),

                          // ── 7. Logout Button ───────────────────────────────
                          _buildLogoutButton(),
                          const SizedBox(height: 48),
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

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFFF8FAFC),
      elevation: 0,
      centerTitle: false,
      leading: IconButton(
        icon: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
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
            size: 15,
            color: Color(0xFF0F172A),
          ),
        ),
        onPressed: () => Navigator.maybePop(context),
      ),
      title: Text(
        'Profil & Pengaturan',
        style: GoogleFonts.plusJakartaSans(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: const Color(0xFF0F172A),
          letterSpacing: -0.3,
        ),
      ),
      actions: [
        if (_isSyncing)
          const Padding(
            padding: EdgeInsets.only(right: 18),
            child: Center(
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFF22C55E),
                ),
              ),
            ),
          )
        else
          IconButton(
            tooltip: 'Sinkronisasi Ulang',
            icon: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Icon(Icons.sync_rounded, color: Color(0xFF0F172A), size: 18),
            ),
            onPressed: _fetchProfile,
          ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildUserCard(UserProfile user) {
    return ProfileCard(
      children: [
        ProfileInfoTile(
          icon: Icons.person_outline_rounded,
          label: 'Nama Lengkap',
          value: user.name,
          onTap: () => ProfileSheets.showEditUserProfile(context, onSaved: () => setState(() {})),
        ),
        const ProfileDivider(),
        ProfileInfoTile(
          icon: Icons.mail_outline_rounded,
          label: 'Email Akun',
          value: user.email,
          trailingChipText: 'Terverifikasi',
          trailingChipColor: const Color(0xFF16A34A),
          trailingChipBg: const Color(0xFFDCFCE7),
        ),
        const ProfileDivider(),
        ProfileInfoTile(
          icon: Icons.phone_outlined,
          label: 'Nomor WhatsApp / Kontak',
          value: user.phone,
          onTap: () => ProfileSheets.showEditUserProfile(context, onSaved: () => setState(() {})),
        ),
        const ProfileDivider(),
        ProfileInfoTile(
          icon: Icons.lock_outline_rounded,
          label: 'Kata Sandi & Keamanan',
          value: '••••••••••••',
          trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
          onTap: () => ProfileSheets.showChangePassword(context),
        ),
      ],
    );
  }

  Widget _buildBusinessCard(BusinessProfile business) {
    return ProfileCard(
      children: [
        ProfileInfoTile(
          icon: Icons.storefront_rounded,
          label: 'Nama Gerai / Bisnis',
          value: business.name,
          onTap: () => ProfileSheets.showEditBusinessProfile(context, onSaved: () => setState(() {})),
        ),
        const ProfileDivider(),
        ProfileInfoTile(
          icon: Icons.category_outlined,
          label: 'Kategori Usaha',
          value: business.category,
        ),
        const ProfileDivider(),
        ProfileInfoTile(
          icon: Icons.location_on_outlined,
          label: 'Alamat Operasional',
          value: business.address,
          onTap: () => ProfileSheets.showEditBusinessProfile(context, onSaved: () => setState(() {})),
        ),
        const ProfileDivider(),
        ProfileInfoTile(
          icon: Icons.access_time_rounded,
          label: 'Jam Buka Toko',
          value: business.operationalHours,
          trailingChipText: '🟢 Aktif Buka',
          trailingChipColor: const Color(0xFF16A34A),
          trailingChipBg: const Color(0xFFDCFCE7),
        ),
        const ProfileDivider(),
        ProfileInfoTile(
          icon: Icons.receipt_long_outlined,
          label: 'Pajak PB1 & Footer Struk',
          value: 'PB1: ${business.taxPercentage.toStringAsFixed(0)}% • "${business.receiptFooter}"',
          onTap: () => ProfileSheets.showEditBusinessProfile(context, onSaved: () => setState(() {})),
        ),
      ],
    );
  }

  Widget _buildPreferencesCard(AppPreferences prefs) {
    return ProfileCard(
      children: [
        ProfileSwitchTile(
          icon: Icons.print_outlined,
          title: 'Cetak Struk Otomatis',
          subtitle: 'Struk transaksi POS langsung tercetak ke Bluetooth printer',
          value: prefs.autoPrintReceipt,
          onChanged: (val) {
            _repo.updatePreferences(autoPrintReceipt: val);
          },
        ),
        const ProfileDivider(),
        ProfileSwitchTile(
          icon: Icons.notifications_active_outlined,
          title: 'Notifikasi Transaksi Realtime',
          subtitle: 'Kirim notifikasi setiap kali ada pesanan baru terselesaikan',
          value: prefs.pushNotifications,
          onChanged: (val) {
            _repo.updatePreferences(pushNotifications: val);
          },
        ),
        const ProfileDivider(),
        ProfileSwitchTile(
          icon: Icons.warning_amber_rounded,
          title: 'Peringatan Stok Menipis',
          subtitle: 'AI mengingatkan saat bahan baku mendekati batas minimum',
          value: prefs.stockAlerts,
          onChanged: (val) {
            _repo.updatePreferences(stockAlerts: val);
          },
        ),
        const ProfileDivider(),
        ProfileSwitchTile(
          icon: Icons.fingerprint_rounded,
          title: 'Kunci Aplikasi Biometrik',
          subtitle: 'Masuk cepat menggunakan sidik jari atau Face ID',
          value: prefs.biometricLogin,
          onChanged: (val) {
            _repo.updatePreferences(biometricLogin: val);
          },
        ),
      ],
    );
  }

  Widget _buildServerConfigCard() {
    return ProfileCard(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: _isServerConnected ? const Color(0xFFF0FDF4) : const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _isServerConnected ? const Color(0xFFBBF7D0) : const Color(0xFFFECACA),
                ),
              ),
              child: Icon(
                Icons.cloud_sync_rounded,
                color: _isServerConnected ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                size: 20,
              ),
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
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        _isServerConnected ? '🟢 Terhubung' : '⚠️ Offline / Terputus',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: _isServerConnected ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    ApiConfig.baseUrl,
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 11,
                      color: const Color(0xFF64748B),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF111111),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              onPressed: () => ProfileSheets.showServerConfig(
                context,
                onConnectionTested: (ok) => setState(() => _isServerConnected = ok),
              ),
              child: Text(
                'Ubah IP',
                style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAppInfoCard() {
    return ProfileCard(
      children: [
        ProfileInfoTile(
          icon: Icons.info_outline_rounded,
          label: 'Versi Aplikasi',
          value: 'AIsistenku POS & ERP v1.2.0',
          trailingChipText: 'Build 2026.09',
          trailingChipColor: Colors.white,
          trailingChipBg: const Color(0xFF111111),
        ),
        const ProfileDivider(),
        ProfileInfoTile(
          icon: Icons.headset_mic_outlined,
          label: 'Pusat Bantuan & Layanan',
          value: 'Hubungi tim technical support 24/7',
          trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
          onTap: () => ProfileSheets.showSupportHelpSheet(context),
        ),
        const ProfileDivider(),
        ProfileInfoTile(
          icon: Icons.privacy_tip_outlined,
          label: 'Syarat & Kebijakan Privasi',
          value: 'Enkripsi data standar ISO & PCI-DSS POS',
          trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
          onTap: () => ProfileSheets.showSecurityPrivacySheet(context),
        ),
      ],
    );
  }

  Widget _buildLogoutButton() {
    return Container(
      width: double.infinity,
      height: 52,
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFECACA), width: 1.2),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => ProfileSheets.showLogoutConfirmation(
            context,
            onConfirmLogout: _handleLogout,
          ),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.logout_rounded,
                  color: Color(0xFFDC2626),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Keluar dari Akun',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFFDC2626),
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
