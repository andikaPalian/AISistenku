import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import '../../../core/services/thermal_printer_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/action_success_modal.dart';
import '../../../models/product.dart';
import '../../../models/profile_model.dart';

/// Interactive modal sheet to select, connect, and configure Bluetooth ESC/POS Thermal Printers.
class PrinterSelectionModal extends StatefulWidget {
  final OrderRecord? order;
  final VoidCallback? onPrinted;

  const PrinterSelectionModal({
    super.key,
    this.order,
    this.onPrinted,
  });

  static Future<void> show(
    BuildContext context, {
    OrderRecord? order,
    VoidCallback? onPrinted,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PrinterSelectionModal(
        order: order,
        onPrinted: onPrinted,
      ),
    );
  }

  @override
  State<PrinterSelectionModal> createState() => _PrinterSelectionModalState();
}

class _PrinterSelectionModalState extends State<PrinterSelectionModal> {
  final ThermalPrinterService _printerService = ThermalPrinterService.instance;
  bool _isLoading = false;
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    _initPrinterStatus();
  }

  Future<void> _initPrinterStatus() async {
    setState(() => _isLoading = true);
    await _printerService.checkConnection();
    await _printerService.getPairedDevices();
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleConnect(BluetoothDevice device) async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Menghubungkan ke ${device.name ?? "Printer"}...';
    });

    final success = await _printerService.connect(device);

    if (mounted) {
      setState(() {
        _isLoading = false;
        _statusMessage = null;
      });

      if (success) {
        ActionSuccessModal.show(
          context,
          title: 'Printer Terhubung',
          subtitle: 'Koneksi Bluetooth ke printer thermal telah aktif dan siap mencetak struk.',
          itemName: device.name ?? 'Bluetooth Printer',
          itemCategory: 'Perangkat Keras',
          quantityChange: 'Online',
          financialImpact: 'Kertas: ${_printerService.paperSize.label}',
          statusBadge: 'Terhubung',
          itemIcon: Icons.print_rounded,
        );
      } else {
        ActionSuccessModal.showNotice(
          context,
          title: 'Gagal Menghubungkan Printer',
          subtitle: 'Pastikan printer Bluetooth dalam kondisi menyala, Bluetooth HP aktif, dan perangkat sudah dipasangkan (paired).',
          itemName: device.name ?? 'Bluetooth Printer',
          itemCategory: 'Perangkat Keras',
          isError: true,
        );
      }
    }
  }

  Future<void> _handleDisconnect() async {
    setState(() => _isLoading = true);
    await _printerService.disconnect();
    if (mounted) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Printer Bluetooth diputuskan'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _handlePrintReceipt() async {
    if (widget.order == null) return;

    setState(() {
      _isLoading = true;
      _statusMessage = 'Mengirim perintah cetak ESC/POS...';
    });

    final business = ProfileRepository.instance.business;
    final success = await _printerService.printReceipt(
      order: widget.order!,
      business: business,
    );

    if (mounted) {
      setState(() {
        _isLoading = false;
        _statusMessage = null;
      });

      if (success) {
        widget.onPrinted?.call();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Struk transaksi #${widget.order!.orderCode} berhasil dicetak!',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.secondary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal mencetak struk. Pastikan kertas terpasang dan printer dalam jangkauan.'),
            backgroundColor: AppColors.destructive,
          ),
        );
      }
    }
  }

  Future<void> _handleTestPrint() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Mencetak struk uji (Test Print)...';
    });

    final success = await _printerService.printTestReceipt();

    if (mounted) {
      setState(() {
        _isLoading = false;
        _statusMessage = null;
      });

      if (success) {
        ActionSuccessModal.show(
          context,
          title: 'Struk Uji Berhasil Dicetak',
          subtitle: 'Printer thermal bekerja dengan baik dan lebar kertas ${_printerService.paperSize.label} telah selaras.',
          itemName: 'Test Print ESC/POS',
          itemCategory: 'Diagnostik Hardware',
          quantityChange: 'Status OK',
          financialImpact: 'Kertas: ${_printerService.paperSize.label}',
          statusBadge: 'Siap Cetak',
          itemIcon: Icons.receipt_rounded,
        );
      } else {
        ActionSuccessModal.showNotice(
          context,
          title: 'Gagal Mencetak Struk Uji',
          subtitle: 'Periksa sisa kertas struk, daya baterai printer, atau pastikan koneksi Bluetooth masih tersambung.',
          itemName: 'Printer Bluetooth',
          itemCategory: 'Diagnostik Hardware',
          isError: true,
        );
      }
    }
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
        maxHeight: MediaQuery.of(context).size.height * 0.88,
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

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF111111),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.print_rounded, color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Printer Thermal Bluetooth',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.darkText,
                            ),
                          ),
                          Text(
                            'Koneksi Fisik Mesin Kasir (ESC/POS)',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppColors.mutedText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 22),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          const SizedBox(height: 16),

          // Content
          Flexible(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Connection Status Card
                  _buildConnectionStatusBanner(),
                  const SizedBox(height: 16),

                  // 2. Paper Size Selector (58mm vs 80mm)
                  Text(
                    'Ukuran Kertas Thermal Struk',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.darkText,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildPaperSizeOption(
                          size: ThermalPaperSize.mm58,
                          isSelected: _printerService.paperSize == ThermalPaperSize.mm58,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildPaperSizeOption(
                          size: ThermalPaperSize.mm80,
                          isSelected: _printerService.paperSize == ThermalPaperSize.mm80,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // 3. Paired Devices List Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Perangkat Bluetooth Berpasangan',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.darkText,
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: _isLoading ? null : _initPrinterStatus,
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.refresh_rounded, size: 14, color: AppColors.primaryTeal),
                              const SizedBox(width: 4),
                              Text(
                                'Pindai Ulang',
                                style: GoogleFonts.inter(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primaryTeal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  if (_isLoading && _printerService.devices.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (_printerService.devices.isEmpty)
                    _buildEmptyDeviceCard()
                  else
                    ..._printerService.devices.map((dev) => _buildDeviceTile(dev)),

                  const SizedBox(height: 16),

                  // Test Print Button
                  OutlinedButton.icon(
                    onPressed: _isLoading ? null : _handleTestPrint,
                    icon: const Icon(Icons.receipt_long_outlined, size: 16),
                    label: Text(
                      'Uji Cetak Struk (Test Print)',
                      style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w700),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF111111),
                      side: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      minimumSize: const Size(double.infinity, 46),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Main Print Button (if order is passed)
          if (widget.order != null)
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _handlePrintReceipt,
                icon: const Icon(Icons.print_rounded, size: 20),
                label: _isLoading
                    ? Text(_statusMessage ?? 'Memproses...', style: GoogleFonts.inter(fontWeight: FontWeight.w700))
                    : Text(
                        'Cetak Struk #${widget.order!.orderCode}',
                        style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700),
                      ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF111111),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  elevation: 4,
                  shadowColor: const Color(0xFF111111).withValues(alpha: 0.3),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildConnectionStatusBanner() {
    final isConn = _printerService.isConnected;
    final selected = _printerService.selectedDevice;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isConn
            ? AppColors.secondary.withValues(alpha: 0.1)
            : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isConn ? AppColors.secondary.withValues(alpha: 0.3) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: isConn ? AppColors.secondary : const Color(0xFF94A3B8),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isConn
                      ? 'Terhubung: ${selected?.name ?? "Printer Thermal"}'
                      : 'Belum Terhubung ke Printer Fisik',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isConn ? const Color(0xFF15803D) : AppColors.darkText,
                  ),
                ),
                Text(
                  isConn
                      ? 'Protokol ESC/POS aktif • Lebar: ${_printerService.paperSize.label}'
                      : 'Pilih printer dari daftar di bawah untuk menghubungkan',
                  style: GoogleFonts.inter(fontSize: 11, color: AppColors.mutedText),
                ),
              ],
            ),
          ),
          if (isConn)
            TextButton(
              onPressed: _handleDisconnect,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.destructive,
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              child: Text(
                'Putuskan',
                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPaperSizeOption({
    required ThermalPaperSize size,
    required bool isSelected,
  }) {
    return InkWell(
      onTap: () {
        setState(() {
          _printerService.setPaperSize(size);
        });
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF111111) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFF111111) : const Color(0xFFE2E8F0),
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.receipt_outlined,
                  size: 16,
                  color: isSelected ? Colors.white : AppColors.darkText,
                ),
                const SizedBox(width: 6),
                Text(
                  size.label,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? Colors.white : AppColors.darkText,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              size == ThermalPaperSize.mm58 ? '32 Karakter/Baris' : '48 Karakter/Baris',
              style: GoogleFonts.inter(
                fontSize: 10.5,
                color: isSelected ? Colors.white.withValues(alpha: 0.8) : AppColors.mutedText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceTile(BluetoothDevice device) {
    final isSelected = _printerService.selectedDevice?.address == device.address && _printerService.isConnected;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? AppColors.secondary : const Color(0xFFE2E8F0),
          width: isSelected ? 1.5 : 1.0,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.secondary.withValues(alpha: 0.12)
                  : const Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.bluetooth_rounded,
              size: 18,
              color: isSelected ? AppColors.secondary : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  device.name ?? 'Perangkat Bluetooth',
                  style: GoogleFonts.inter(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.darkText,
                  ),
                ),
                Text(
                  device.address ?? 'Bluetooth Serial',
                  style: GoogleFonts.inter(fontSize: 11, color: AppColors.mutedText),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: isSelected ? null : () => _handleConnect(device),
            style: ElevatedButton.styleFrom(
              backgroundColor: isSelected ? const Color(0xFFE2E8F0) : const Color(0xFF111111),
              foregroundColor: isSelected ? const Color(0xFF64748B) : Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: Text(
              isSelected ? 'Tersambung' : 'Sambungkan',
              style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyDeviceCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          const Icon(Icons.bluetooth_disabled_rounded, size: 36, color: Color(0xFF94A3B8)),
          const SizedBox(height: 8),
          Text(
            'Tidak Ada Printer Terpasang',
            style: GoogleFonts.poppins(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.darkText),
          ),
          const SizedBox(height: 4),
          Text(
            'Pastikan printer thermal telah di-pairing melalui pengaturan Bluetooth HP Android Anda, lalu ketuk "Pindai Ulang".',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 11.5, color: AppColors.mutedText, height: 1.4),
          ),
        ],
      ),
    );
  }
}
