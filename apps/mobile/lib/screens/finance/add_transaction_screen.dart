import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../models/finance_model.dart';

/// Screen to record a new Income or Expense transaction.
///
/// Faithfully reproduces the design in uploaded screenshots 1 & 2 with
/// enhanced UX (currency formatter, category picker, date picker).
class AddTransactionScreen extends StatefulWidget {
  final TransactionType initialType;

  const AddTransactionScreen({
    super.key,
    this.initialType = TransactionType.expense,
  });

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  late TransactionType _selectedType;
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  FinanceCategory _selectedCategory = FinanceCategory.ingredients;

  double _parsedAmount = 0;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialType;
    _selectedCategory = _selectedType == TransactionType.income
        ? FinanceCategory.sales
        : FinanceCategory.ingredients;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _onAmountChanged(String val) {
    final clean = val.replaceAll(RegExp(r'[^0-9]'), '');
    if (clean.isEmpty) {
      setState(() {
        _parsedAmount = 0;
        _amountController.text = '';
      });
      return;
    }
    final parsed = double.tryParse(clean) ?? 0;
    setState(() {
      _parsedAmount = parsed;
    });
  }

  void _addQuickAmount(double delta) {
    setState(() {
      _parsedAmount += delta;
      _amountController.text = _parsedAmount.toInt().toString();
    });
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primaryTeal,
              onPrimary: Colors.white,
              onSurface: AppColors.darkText,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _selectedDate.hour,
          _selectedDate.minute,
        );
      });
    }
  }

  void _submitTransaction() {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan masukkan nama transaksi'),
          backgroundColor: AppColors.destructive,
        ),
      );
      return;
    }

    if (_parsedAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nominal transaksi harus lebih dari Rp0'),
          backgroundColor: AppColors.destructive,
        ),
      );
      return;
    }

    FinanceRepository.instance.addTransaction(
      title: title,
      type: _selectedType,
      category: _selectedCategory,
      amount: _parsedAmount,
      source: TransactionSource.manual,
      notes: _notesController.text.trim(),
      timestamp: _selectedDate,
    );

    Navigator.pop(context, true);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${_selectedType == TransactionType.income ? 'Pemasukan' : 'Pengeluaran'} berhasil dicatat!',
        ),
        backgroundColor: AppColors.successGreen,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isExpense = _selectedType == TransactionType.expense;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: AppColors.darkText,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Tambah Transaksi',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.darkText,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Segmented Switcher [ Pemasukan | Pengeluaran ] ──
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDFA),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFCCFBF1),
                          width: 1.2,
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedType = TransactionType.income;
                                  _selectedCategory = FinanceCategory.sales;
                                });
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: !isExpense
                                      ? const Color(0xFF0F766E)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(9),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  'Pemasukan',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: !isExpense
                                        ? FontWeight.w600
                                        : FontWeight.w500,
                                    color: !isExpense
                                        ? Colors.white
                                        : const Color(0xFF0F766E),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedType = TransactionType.expense;
                                  _selectedCategory =
                                      FinanceCategory.ingredients;
                                });
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: isExpense
                                      ? const Color(0xFF0F766E)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(9),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  'Pengeluaran',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: isExpense
                                        ? FontWeight.w600
                                        : FontWeight.w500,
                                    color: isExpense
                                        ? Colors.white
                                        : const Color(0xFF0F766E),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    // ── Big Nominal Amount Box ────────────────────────
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xFF0F766E),
                          width: 1.2,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          TextField(
                            controller: _amountController,
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            style: GoogleFonts.poppins(
                              fontSize: 26,
                              fontWeight: FontWeight.w700,
                              color: AppColors.darkText,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Rp0',
                              hintStyle: GoogleFonts.poppins(
                                fontSize: 26,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF94A3B8),
                              ),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                              prefixText:
                                  _parsedAmount > 0 ? 'Rp' : null,
                              prefixStyle: GoogleFonts.poppins(
                                fontSize: 26,
                                fontWeight: FontWeight.w700,
                                color: AppColors.darkText,
                              ),
                            ),
                            onChanged: _onAmountChanged,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Quick nominal chip suggestions
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        children: [
                          _buildQuickChip('+20rb', 20000),
                          _buildQuickChip('+50rb', 50000),
                          _buildQuickChip('+100rb', 100000),
                          _buildQuickChip('+250rb', 250000),
                          _buildQuickChip('+500rb', 50000),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ── Field: Nama Transaksi ─────────────────────────
                    Text(
                      'Nama Transaksi',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.darkText,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: TextField(
                        controller: _titleController,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: AppColors.darkText,
                        ),
                        decoration: InputDecoration(
                          hintText: isExpense
                              ? 'e.g., Electricity Bill / Beli Susu Segar'
                              : 'e.g., Penjualan Event / Catering',
                          hintStyle: GoogleFonts.inter(
                            fontSize: 14,
                            color: const Color(0xFF94A3B8),
                          ),
                          border: InputBorder.none,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ── Field: Kategori Transaksi ─────────────────────
                    Text(
                      'Kategori Transaksi',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.darkText,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: FinanceCategory.values.map((cat) {
                        final isCatSelected = _selectedCategory == cat;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedCategory = cat;
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: isCatSelected
                                  ? const Color(0xFF0F766E)
                                  : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  cat.icon,
                                  size: 14,
                                  color: isCatSelected
                                      ? Colors.white
                                      : const Color(0xFF64748B),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  cat.label,
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: isCatSelected
                                        ? FontWeight.w600
                                        : FontWeight.w500,
                                    color: isCatSelected
                                        ? Colors.white
                                        : const Color(0xFF334155),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 20),

                    // ── Field: Tanggal ────────────────────────────────
                    Text(
                      'Tanggal',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.darkText,
                      ),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _selectDate,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${_selectedDate.month.toString().padLeft(2, '0')}/${_selectedDate.day.toString().padLeft(2, '0')}/${_selectedDate.year}',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: AppColors.darkText,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const Icon(
                              Icons.calendar_today_outlined,
                              size: 18,
                              color: Color(0xFF475569),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ── Field: Catatan (Optional) ─────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Catatan',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.darkText,
                          ),
                        ),
                        Text(
                          'Optional',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: const Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: TextField(
                        controller: _notesController,
                        maxLines: 3,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: AppColors.darkText,
                        ),
                        decoration: InputDecoration(
                          hintText: isExpense
                              ? 'e.g., Monthly electricity payment'
                              : 'e.g., Pembayaran cash langsung',
                          hintStyle: GoogleFonts.inter(
                            fontSize: 14,
                            color: const Color(0xFF94A3B8),
                          ),
                          border: InputBorder.none,
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),

            // ── Bottom Full-Width CTA Button ────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _submitTransaction,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F766E),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  child: Text(
                    isExpense
                        ? 'Tambah Pengeluaran +'
                        : 'Tambah Pemasukan +',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickChip(String label, double amount) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: GestureDetector(
        onTap: () => _addQuickAmount(amount),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF0F766E),
            ),
          ),
        ),
      ),
    );
  }
}
