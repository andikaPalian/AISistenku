import 'package:flutter/material.dart';
import '../core/services/api_service.dart';
import 'stock_model.dart';

/// Type of financial transaction.
enum TransactionType {
  income,
  expense,
}

/// Category classification matching the database schema & UMKM needs.
enum FinanceCategory {
  sales('Penjualan', Icons.point_of_sale_rounded, Color(0xFF10B981)),
  refund('Refund / Retur', Icons.assignment_return_rounded, Color(0xFFE11D48)),
  ingredients('Bahan Baku', Icons.shopping_bag_outlined, Color(0xFFEF4444)),
  utility('Listrik & Utilitas', Icons.bolt_rounded, Color(0xFFF59E0B)),
  operational('Operasional', Icons.settings_suggest_rounded, Color(0xFF6366F1)),
  salary('Gaji Karyawan', Icons.badge_outlined, Color(0xFFEC4899)),
  marketing('Promosi & Iklan', Icons.campaign_rounded, Color(0xFF8B5CF6)),
  other('Lain-lain', Icons.category_rounded, Color(0xFF64748B));

  final String label;
  final IconData icon;
  final Color color;

  const FinanceCategory(this.label, this.icon, this.color);
}

/// Source of transaction origin.
enum TransactionSource {
  posAutomatic('POS Otomatis', Icons.receipt_long_rounded),
  manual('Input Manual', Icons.edit_note_rounded),
  aiAgent('AI Asisten', Icons.smart_toy_rounded);

  final String label;
  final IconData icon;

  const TransactionSource(this.label, this.icon);
}

/// Filter period for finance overview.
enum FinancePeriod {
  today('Hari Ini'),
  thisWeek('Minggu Ini'),
  thisMonth('Bulan Ini');

  final String label;

  const FinancePeriod(this.label);
}

/// Single financial transaction entity.
class FinanceTransaction {
  final String id;
  final String? orderId;
  final String? orderStatus;
  final String? orderCode;
  final String title;
  final TransactionType type;
  final FinanceCategory category;
  final double amount;
  final TransactionSource source;
  final String? notes;
  final DateTime timestamp;

  const FinanceTransaction({
    required this.id,
    this.orderId,
    this.orderStatus,
    this.orderCode,
    required this.title,
    required this.type,
    required this.category,
    required this.amount,
    required this.source,
    this.notes,
    required this.timestamp,
  });

  /// Check if the transaction belongs to an order that is already refunded or cancelled.
  bool get isRefundedOrder =>
      orderStatus == 'REFUNDED' ||
      orderStatus == 'CANCELLED' ||
      category == FinanceCategory.refund;

  /// Formats amount in Rupiah (e.g. "+Rp45.000" or "-Rp250.000").
  String get formattedAmountWithSign {
    final formatted = FinanceRepository.formatRupiah(amount);
    return type == TransactionType.income ? '+$formatted' : '-$formatted';
  }

  /// Formats pure positive amount in Rupiah.
  String get formattedAmount {
    return FinanceRepository.formatRupiah(amount);
  }

  /// Formats relative or human-readable date.
  String get formattedDateString {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final txDate = DateTime(timestamp.year, timestamp.month, timestamp.day);

    final hour = timestamp.hour.toString().padLeft(2, '0');
    final minute = timestamp.minute.toString().padLeft(2, '0');
    final timeString = '$hour:$minute';

    if (txDate == today) {
      return 'Today, $timeString';
    } else if (txDate == today.subtract(const Duration(days: 1))) {
      return 'Yesterday, $timeString';
    } else {
      return '${timestamp.day}/${timestamp.month}, $timeString';
    }
  }

  /// Subtitle formatted as shown in reference design: "Income • Today, 14:30"
  String get listSubtitle {
    final catName = category == FinanceCategory.sales ? 'Income' : category.label;
    return '$catName • $formattedDateString';
  }

  FinanceTransaction copyWith({
    String? id,
    String? orderId,
    String? orderStatus,
    String? orderCode,
    String? title,
    TransactionType? type,
    FinanceCategory? category,
    double? amount,
    TransactionSource? source,
    String? notes,
    DateTime? timestamp,
  }) {
    return FinanceTransaction(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      orderStatus: orderStatus ?? this.orderStatus,
      orderCode: orderCode ?? this.orderCode,
      title: title ?? this.title,
      type: type ?? this.type,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      source: source ?? this.source,
      notes: notes ?? this.notes,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}

/// Data point for sales & cashflow charts.
class ChartDataPoint {
  final String label; // e.g. "Sen", "08:00", "Mg 1"
  final double income;
  final double expense;

  const ChartDataPoint({
    required this.label,
    required this.income,
    required this.expense,
  });

  double get netProfit => income - expense;
}

/// Peak hours data point for barista shift & sales optimization.
class PeakHourData {
  final String timeRange; // e.g. "12:00-14:00"
  final int orderCount;
  final double revenue;
  final bool isPeak;

  const PeakHourData({
    required this.timeRange,
    required this.orderCount,
    required this.revenue,
    this.isPeak = false,
  });
}

/// Product contribution for bestsellers analysis.
class TopProductContribution {
  final String name;
  final int soldQuantity;
  final double totalRevenue;
  final double contributionPercent;
  final Color badgeColor;

  const TopProductContribution({
    required this.name,
    required this.soldQuantity,
    required this.totalRevenue,
    required this.contributionPercent,
    required this.badgeColor,
  });

  /// Formatted revenue in Rupiah (e.g. "Rp450.000").
  String get formattedRevenue => FinanceRepository.formatRupiah(totalRevenue);

  /// Clean formatted percentage string (e.g. "42.9%").
  String get formattedPercent {
    if (contributionPercent <= 0) return '0%';
    final fixed = contributionPercent.toStringAsFixed(1);
    return fixed.endsWith('.0') ? '${fixed.substring(0, fixed.length - 2)}%' : '$fixed%';
  }
}

/// Repository singleton managing financial records and dynamic metric calculations.
class FinanceRepository extends ChangeNotifier {
  static final FinanceRepository instance = FinanceRepository._internal();

  FinanceRepository._internal() {
    _seedData();
  }

  final List<FinanceTransaction> _transactions = [];
  List<ChartDataPoint> _cachedChartData = [];
  List<TopProductContribution> _cachedTopProducts = [];
  Map<String, dynamic>? _cachedDashboard;

  List<FinanceTransaction> get transactions => List.unmodifiable(_transactions);

  void clearForNewUser() {
    _transactions.clear();
    notifyListeners();
  }

  void loadDemoData() {
    _transactions.clear();
    _seedData();
    notifyListeners();
  }

  void _seedData() {
    final now = DateTime.now();
    _transactions.addAll([
      FinanceTransaction(
        id: 'tx-001',
        title: 'Iced Latte Sales',
        type: TransactionType.income,
        category: FinanceCategory.sales,
        amount: 45000,
        source: TransactionSource.posAutomatic,
        notes: 'Order #3A-88895 (2 cups Iced Latte)',
        timestamp: DateTime(now.year, now.month, now.day, 14, 30),
      ),
      FinanceTransaction(
        id: 'tx-002',
        title: 'Coffee Beans Purchase',
        type: TransactionType.expense,
        category: FinanceCategory.ingredients,
        amount: 250000,
        source: TransactionSource.manual,
        notes: 'Restock 2kg Espresso Blend dari Roastery Lokal',
        timestamp: DateTime(now.year, now.month, now.day, 10, 15),
      ),
      FinanceTransaction(
        id: 'tx-003',
        title: 'Sugar Purchase',
        type: TransactionType.expense,
        category: FinanceCategory.ingredients,
        amount: 170000,
        source: TransactionSource.manual,
        notes: 'Gula Aren Cair 5 Jerigen',
        timestamp: DateTime(now.year, now.month, now.day - 1, 16, 45),
      ),
      FinanceTransaction(
        id: 'tx-004',
        title: 'POS Sales',
        type: TransactionType.income,
        category: FinanceCategory.sales,
        amount: 850000,
        source: TransactionSource.posAutomatic,
        notes: 'Batch Penjualan Siang & Sore (18 Transaksi)',
        timestamp: DateTime(now.year, now.month, now.day - 1, 19, 0),
      ),
      FinanceTransaction(
        id: 'tx-005',
        title: 'Susu UHT Fresh Milk 10L',
        type: TransactionType.expense,
        category: FinanceCategory.ingredients,
        amount: 195000,
        source: TransactionSource.aiAgent,
        notes: 'Restock otomatis via konfirmasi AIsisten',
        timestamp: DateTime(now.year, now.month, now.day - 2, 11, 20),
      ),
      FinanceTransaction(
        id: 'tx-006',
        title: 'Penjualan Siang (POS)',
        type: TransactionType.income,
        category: FinanceCategory.sales,
        amount: 1250000,
        source: TransactionSource.posAutomatic,
        notes: 'Rekap Shift 1 (24 Transaksi)',
        timestamp: DateTime(now.year, now.month, now.day - 3, 15, 30),
      ),
      FinanceTransaction(
        id: 'tx-007',
        title: 'Listrik & Token PLN',
        type: TransactionType.expense,
        category: FinanceCategory.utility,
        amount: 300000,
        source: TransactionSource.manual,
        notes: 'Token Listrik Outlet Utama 5500VA',
        timestamp: DateTime(now.year, now.month, now.day - 4, 9, 10),
      ),
      FinanceTransaction(
        id: 'tx-008',
        title: 'Cup Sealer & Paper Cup 500pcs',
        type: TransactionType.expense,
        category: FinanceCategory.operational,
        amount: 180000,
        source: TransactionSource.manual,
        notes: 'Packaging take away',
        timestamp: DateTime(now.year, now.month, now.day - 5, 13, 0),
      ),
      FinanceTransaction(
        id: 'tx-009',
        title: 'Penjualan Akhir Pekan (POS)',
        type: TransactionType.income,
        category: FinanceCategory.sales,
        amount: 2450000,
        source: TransactionSource.posAutomatic,
        notes: 'Rekap Omzet Sabtu & Minggu',
        timestamp: DateTime(now.year, now.month, now.day - 6, 21, 30),
      ),
    ]);
  }

  Future<void> fetchFinanceFromBackend() async {
    try {
      final res = await ApiService.instance.get('/finance/transactions');
      List? list;
      if (res != null) {
        if (res['data'] is List) {
          list = res['data'];
        } else if (res['transactions'] is List) {
          list = res['transactions'];
        }
      }
      if (list != null) {
        final List<FinanceTransaction> loaded = [];
        for (final t in list) {
          final isIncome = (t['type'] ?? '').toString().toLowerCase() == 'income';
          FinanceCategory cat = FinanceCategory.sales;
          final catStr = (t['category'] ?? '').toString().toLowerCase();
          if (catStr.contains('refund') || catStr.contains('retur') || catStr.contains('balik')) {
            cat = FinanceCategory.refund;
          } else if (catStr.contains('bahan') || catStr.contains('ingredient')) {
            cat = FinanceCategory.ingredients;
          } else if (catStr.contains('operasional') || catStr.contains('operational')) {
            cat = FinanceCategory.operational;
          } else if (catStr.contains('gaji') || catStr.contains('salary')) {
            cat = FinanceCategory.salary;
          } else if (catStr.contains('listrik') || catStr.contains('utility')) {
            cat = FinanceCategory.utility;
          }

          TransactionSource src = TransactionSource.manual;
          final srcStr = (t['source'] ?? '').toString().toLowerCase();
          if (srcStr.contains('pos') || srcStr.contains('otomatis')) {
            src = TransactionSource.posAutomatic;
          } else if (srcStr.contains('ai')) {
            src = TransactionSource.aiAgent;
          }

          final amountVal = double.tryParse((t['amount'] ?? '0').toString()) ??
              (t['amount'] as num?)?.toDouble() ??
              0.0;

          final orderData = t['order'] is Map ? t['order'] as Map : null;
          final orderStatus = orderData != null ? orderData['status']?.toString() : t['orderStatus']?.toString();
          final orderCode = orderData != null ? orderData['orderCode']?.toString() : t['orderCode']?.toString();

          loaded.add(FinanceTransaction(
            id: (t['id'] ?? t['transaction_id'] ?? 'tx-${DateTime.now().millisecondsSinceEpoch}').toString(),
            orderId: (t['orderId'] ?? t['order_id'])?.toString(),
            orderStatus: orderStatus,
            orderCode: orderCode,
            title: (t['title'] ?? 'Transaksi').toString(),
            type: isIncome ? TransactionType.income : TransactionType.expense,
            category: cat,
            amount: amountVal,
            source: src,
            notes: t['notes']?.toString(),
            timestamp: t['timestamp'] != null
                ? DateTime.tryParse(t['timestamp'].toString()) ?? DateTime.now()
                : DateTime.now(),
          ));
        }
        if (loaded.isNotEmpty) {
          _transactions.clear();
          _transactions.addAll(loaded);
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('⚠️ fetchFinanceFromBackend error: $e');
    }
  }

  Future<void> fetchDashboardFromBackend() async {
    try {
      final summaryRes = await ApiService.instance.get('/dashboard/overview');
      if (summaryRes != null && summaryRes is Map) {
        _cachedDashboard = summaryRes['data'] is Map ? summaryRes['data'] : summaryRes;
      }

      final trendRes = await ApiService.instance.get('/dashboard/sales-trend?range=30d');
      List? trendList;
      if (trendRes != null) {
        if (trendRes is List) {
          trendList = trendRes;
        } else if (trendRes is Map && trendRes['data'] is List) {
          trendList = trendRes['data'];
        }
      }
      if (trendList != null) {
        _cachedChartData = trendList.map((t) {
          final totalSales = double.tryParse((t['totalSales'] ?? '0').toString()) ??
              (t['totalSales'] as num?)?.toDouble() ??
              0.0;
          final dateStr = (t['date'] ?? '').toString();
          return ChartDataPoint(
            label: dateStr.length == 10 ? dateStr.substring(5, 10) : dateStr,
            income: totalSales,
            expense: 0.0,
          );
        }).toList();
      }

      final topRes = await ApiService.instance.get('/dashboard/top-products?range=30d&limit=3');
      List? topList;
      if (topRes != null) {
        if (topRes is List) {
          topList = topRes;
        } else if (topRes is Map && topRes['data'] is List) {
          topList = topRes['data'];
        }
      }
      if (topList != null) {
        final colors = [const Color(0xFF0D9488), const Color(0xFF14B8A6), const Color(0xFF3B82F6)];
        final totalRev = topList.fold<double>(0.0, (sum, e) {
          final rev = double.tryParse((e['totalRevenue'] ?? '0').toString()) ?? (e['totalRevenue'] as num?)?.toDouble() ?? 0.0;
          return sum + rev;
        });
        final totalQty = topList.fold<int>(0, (sum, e) {
          final qty = int.tryParse((e['totalQuantitySold'] ?? '0').toString()) ?? (e['totalQuantitySold'] as num?)?.toInt() ?? 0;
          return sum + qty;
        });

        _cachedTopProducts = topList.asMap().entries.map((entry) {
          final rev = double.tryParse((entry.value['totalRevenue'] ?? '0').toString()) ??
              (entry.value['totalRevenue'] as num?)?.toDouble() ??
              0.0;
          final qty = int.tryParse((entry.value['totalQuantitySold'] ?? '0').toString()) ??
              (entry.value['totalQuantitySold'] as num?)?.toInt() ??
              0;

          final rawPercent = totalRev > 0
              ? (rev / totalRev * 100)
              : (totalQty > 0 ? (qty / totalQty * 100) : 0.0);
          final cleanPercent = double.tryParse(rawPercent.toStringAsFixed(1)) ?? 0.0;

          final rawName = (entry.value['productName'] ?? '').toString().trim();
          final cleanName = rawName.isNotEmpty && rawName.toLowerCase() != 'menu'
              ? rawName
              : 'Produk Favorit #${entry.key + 1}';

          return TopProductContribution(
            name: cleanName,
            soldQuantity: qty,
            totalRevenue: rev,
            contributionPercent: cleanPercent,
            badgeColor: colors[entry.key % colors.length],
          );
        }).toList();
      }

      notifyListeners();
    } catch (e) {
      debugPrint('⚠️ fetchDashboardFromBackend error: $e');
    }
  }

  /// Add new transaction and notify UI listeners.
  void addTransaction({
    required String title,
    required TransactionType type,
    required FinanceCategory category,
    required double amount,
    required TransactionSource source,
    String? notes,
    required DateTime timestamp,
  }) {
    final newTx = FinanceTransaction(
      id: 'tx-${DateTime.now().millisecondsSinceEpoch}',
      title: title.trim(),
      type: type,
      category: category,
      amount: amount,
      source: source,
      notes: notes?.trim().isEmpty == true ? null : notes?.trim(),
      timestamp: timestamp,
    );

    _transactions.insert(0, newTx);
    notifyListeners();

    // Sync to backend
    ApiService.instance.post('/finance/transactions', {
      'title': title.trim(),
      'type': type == TransactionType.income ? 'income' : 'expense',
      'category': category.label,
      'amount': amount,
      'source': source.label,
      'notes': notes?.trim().isEmpty == true ? null : notes?.trim(),
      'timestamp': timestamp.toIso8601String(),
    }).catchError((_) => null);
  }

  /// Remove transaction.
  void deleteTransaction(String id) {
    _transactions.removeWhere((tx) => tx.id == id);
    notifyListeners();
  }

  /// Filter transactions based on period, type filter, and optional query.
  List<FinanceTransaction> getFilteredTransactions({
    required FinancePeriod period,
    TransactionType? typeFilter,
    String query = '',
  }) {
    final now = DateTime.now();
    DateTime cutoff;

    switch (period) {
      case FinancePeriod.today:
        cutoff = DateTime(now.year, now.month, now.day);
        break;
      case FinancePeriod.thisWeek:
        cutoff = DateTime(now.year, now.month, now.day)
            .subtract(Duration(days: now.weekday - 1));
        break;
      case FinancePeriod.thisMonth:
        cutoff = DateTime(now.year, now.month, 1);
        break;
    }

    return _transactions.where((tx) {
      final matchesPeriod = tx.timestamp.isAfter(cutoff) ||
          tx.timestamp.isAtSameMomentAs(cutoff) ||
          (period == FinancePeriod.today &&
              tx.timestamp.year == now.year &&
              tx.timestamp.month == now.month &&
              tx.timestamp.day == now.day);

      final matchesType = typeFilter == null || tx.type == typeFilter;

      final matchesQuery = query.isEmpty ||
          tx.title.toLowerCase().contains(query.toLowerCase()) ||
          tx.category.label.toLowerCase().contains(query.toLowerCase()) ||
          (tx.notes != null &&
              tx.notes!.toLowerCase().contains(query.toLowerCase()));

      return matchesPeriod && matchesType && matchesQuery;
    }).toList();
  }

  /// Calculate total current balance (Overall cumulative).
  double get currentBalance {
    double total = 5250000; // Base opening balance
    for (final tx in _transactions) {
      if (tx.type == TransactionType.income) {
        total += tx.amount;
      } else {
        total -= tx.amount;
      }
    }
    return total;
  }

  /// Total count of orders completed today.
  int get todayOrdersCount {
    if (_cachedDashboard != null) {
      final val = _cachedDashboard!['todayOrdersCount'] ??
          _cachedDashboard!['today_orders'] ??
          _cachedDashboard!['todayOrders'];
      if (val != null) {
        return int.tryParse(val.toString()) ?? (val as num?)?.toInt() ?? 0;
      }
    }
    return _transactions.where((tx) {
      final now = DateTime.now();
      return tx.type == TransactionType.income &&
          tx.timestamp.year == now.year &&
          tx.timestamp.month == now.month &&
          tx.timestamp.day == now.day;
    }).length;
  }

  /// Calculate total income for a given period.
  double getTotalIncome(FinancePeriod period) {
    if (_cachedDashboard != null) {
      if (period == FinancePeriod.today) {
        final val = _cachedDashboard!['todayRevenue'] ?? _cachedDashboard!['today_sales'];
        if (val != null) return double.tryParse(val.toString()) ?? (val as num?)?.toDouble() ?? 0.0;
      } else if (period == FinancePeriod.thisMonth) {
        final val = _cachedDashboard!['monthRevenue'] ?? _cachedDashboard!['total_sales'];
        if (val != null) return double.tryParse(val.toString()) ?? (val as num?)?.toDouble() ?? 0.0;
      }
    }
    final filtered = getFilteredTransactions(
      period: period,
      typeFilter: TransactionType.income,
    );
    return filtered.fold(0.0, (sum, tx) => sum + tx.amount);
  }

  /// Calculate total expense for a given period.
  double getTotalExpense(FinancePeriod period) {
    if (_cachedDashboard != null) {
      if (period == FinancePeriod.today) {
        final val = _cachedDashboard!['todayExpense'];
        if (val != null) return double.tryParse(val.toString()) ?? (val as num?)?.toDouble() ?? 0.0;
      } else if (period == FinancePeriod.thisMonth) {
        final val = _cachedDashboard!['monthExpense'];
        if (val != null) return double.tryParse(val.toString()) ?? (val as num?)?.toDouble() ?? 0.0;
      }
    }
    final filtered = getFilteredTransactions(
      period: period,
      typeFilter: TransactionType.expense,
    );
    return filtered.fold(0.0, (sum, tx) => sum + tx.amount);
  }

  /// Calculate total refund amount for a given period.
  double getTotalRefund(FinancePeriod period) {
    final filtered = getFilteredTransactions(period: period);
    return filtered
        .where((tx) => tx.category == FinanceCategory.refund)
        .fold(0.0, (sum, tx) => sum + tx.amount);
  }

  /// Total count of refunded orders/transactions for a given period.
  int getRefundCount(FinancePeriod period) {
    final filtered = getFilteredTransactions(period: period);
    return filtered.where((tx) => tx.category == FinanceCategory.refund).length;
  }

  /// Calculate total Gross Income (Penjualan Kotor sebelum deduksi refund).
  double getTotalGrossIncome(FinancePeriod period) {
    if (_cachedDashboard != null && period == FinancePeriod.today) {
      final val = _cachedDashboard!['todayGrossRevenue'] ?? _cachedDashboard!['today_gross_sales'];
      if (val != null) {
        final parsed = double.tryParse(val.toString()) ?? (val as num?)?.toDouble() ?? 0.0;
        if (parsed > 0) return parsed;
      }
    }

    final filteredIncomes = getFilteredTransactions(
      period: period,
      typeFilter: TransactionType.income,
    );
    final recordedIncome = filteredIncomes.fold(0.0, (sum, tx) => sum + tx.amount);
    final refundAmount = getTotalRefund(period);
    final activeSales = getTotalIncome(period);

    final total = recordedIncome > (activeSales + refundAmount)
        ? recordedIncome
        : (activeSales + refundAmount);
    return total;
  }

  /// Calculate Net Revenue (Penjualan Bersih = Gross Income - Refund).
  double getNetRevenue(FinancePeriod period) {
    if (_cachedDashboard != null && period == FinancePeriod.today) {
      final val = _cachedDashboard!['todayRevenue'] ?? _cachedDashboard!['today_sales'];
      if (val != null) {
        return double.tryParse(val.toString()) ?? (val as num?)?.toDouble() ?? 0.0;
      }
    }

    final gross = getTotalGrossIncome(period);
    final refund = getTotalRefund(period);
    final net = gross - refund;
    return net < 0 ? 0.0 : net;
  }

  /// Calculate operational expenses (excluding refunds, e.g. bahan baku, operasional, gaji, listrik).
  double getOperationalExpense(FinancePeriod period) {
    final filtered = getFilteredTransactions(
      period: period,
      typeFilter: TransactionType.expense,
    );
    return filtered
        .where((tx) => tx.category != FinanceCategory.refund)
        .fold(0.0, (sum, tx) => sum + tx.amount);
  }

  /// Calculate Net Profit for period.
  double getNetProfit(FinancePeriod period) {
    return getTotalIncome(period) - getTotalExpense(period);
  }

  /// Calculate Gross Margin percentage.
  double getGrossMargin(FinancePeriod period) {
    final income = getTotalIncome(period);
    if (income == 0) return 0;
    final profit = getNetProfit(period);
    return (profit / income) * 100;
  }

  /// Generate chart data points for the given period.
  List<ChartDataPoint> getChartPoints(FinancePeriod period) {
    if (_cachedChartData.isNotEmpty && period == FinancePeriod.thisMonth) {
      return _cachedChartData;
    }
    switch (period) {
      case FinancePeriod.today:
        return const [
          ChartDataPoint(label: '08:00', income: 150000, expense: 50000),
          ChartDataPoint(label: '10:00', income: 280000, expense: 250000),
          ChartDataPoint(label: '12:00', income: 420000, expense: 0),
          ChartDataPoint(label: '14:00', income: 210000, expense: 0),
          ChartDataPoint(label: '16:00', income: 190000, expense: 150000),
          ChartDataPoint(label: '18:00', income: 380000, expense: 0),
          ChartDataPoint(label: '20:00', income: 290000, expense: 0),
        ];
      case FinancePeriod.thisWeek:
        return const [
          ChartDataPoint(label: 'Sen', income: 650000, expense: 200000),
          ChartDataPoint(label: 'Sel', income: 720000, expense: 150000),
          ChartDataPoint(label: 'Rab', income: 590000, expense: 420000),
          ChartDataPoint(label: 'Kam', income: 840000, expense: 180000),
          ChartDataPoint(label: 'Jum', income: 1100000, expense: 350000),
          ChartDataPoint(label: 'Sab', income: 1550000, expense: 480000),
          ChartDataPoint(label: 'Min', income: 1420000, expense: 220000),
        ];
      case FinancePeriod.thisMonth:
        return const [
          ChartDataPoint(label: 'Mgg 1', income: 4200000, expense: 1600000),
          ChartDataPoint(label: 'Mgg 2', income: 4850000, expense: 1450000),
          ChartDataPoint(label: 'Mgg 3', income: 5100000, expense: 1900000),
          ChartDataPoint(label: 'Mgg 4', income: 4300000, expense: 1250000),
        ];
    }
  }

  /// Peak hours data points for business operations.
  List<PeakHourData> getPeakHours() {
    return const [
      PeakHourData(timeRange: '08-11', orderCount: 14, revenue: 320000),
      PeakHourData(
          timeRange: '12-14', orderCount: 38, revenue: 950000, isPeak: true),
      PeakHourData(timeRange: '15-17', orderCount: 22, revenue: 540000),
      PeakHourData(
          timeRange: '18-21', orderCount: 45, revenue: 1180000, isPeak: true),
      PeakHourData(timeRange: '21-23', orderCount: 12, revenue: 260000),
    ];
  }

  /// Top 3 bestselling menu items with revenue contribution.
  List<TopProductContribution> getTopProducts() {
    if (_cachedTopProducts.isNotEmpty) {
      return _cachedTopProducts;
    }
    return const [
      TopProductContribution(
        name: 'Kopi Susu Gula Aren',
        soldQuantity: 68,
        totalRevenue: 1224000,
        contributionPercent: 42.5,
        badgeColor: Color(0xFF0D9488),
      ),
      TopProductContribution(
        name: 'Croissant Butter',
        soldQuantity: 42,
        totalRevenue: 756000,
        contributionPercent: 26.3,
        badgeColor: Color(0xFF14B8A6),
      ),
      TopProductContribution(
        name: 'Matcha Oat Latte',
        soldQuantity: 28,
        totalRevenue: 588000,
        contributionPercent: 20.4,
        badgeColor: Color(0xFF3B82F6),
      ),
    ];
  }

  /// Refund and cancel an order on backend with atomic stock rollback & reverse journal.
  Future<bool> refundOrder({
    required String orderId,
    String? reason,
    String targetStatus = 'REFUNDED',
    bool restoreStock = true,
  }) async {
    try {
      final res = await ApiService.instance.post('/orders/$orderId/refund', {
        if (reason != null && reason.isNotEmpty) 'reason': reason,
        'targetStatus': targetStatus,
        'restoreStock': restoreStock,
      });

      if (res != null) {
        // Refresh local finance state and stock quantities
        await Future.wait([
          fetchFinanceFromBackend(),
          StockRepository.instance.fetchStocksFromBackend(),
        ]);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('⚠️ FinanceRepository.refundOrder error: $e');
      rethrow;
    }
  }

  /// Checks if a specific order has already been refunded in the transactions history.
  bool isOrderAlreadyRefunded({
    String? orderId,
    String? orderCode,
    String? title,
    String? notes,
  }) {
    final ordRegex = RegExp(r'ORD-\d{8}-\d{3}|ORD-\d+');
    final codeFromTitle = title != null ? ordRegex.firstMatch(title)?.group(0) : null;
    final codeFromNotes = notes != null ? ordRegex.firstMatch(notes)?.group(0) : null;
    final targetCode = orderCode ?? codeFromTitle ?? codeFromNotes;

    return _transactions.any((tx) {
      if (tx.category != FinanceCategory.refund) return false;
      if (orderId != null && tx.orderId != null && tx.orderId == orderId) {
        return true;
      }
      if (targetCode != null) {
        if (tx.title.contains(targetCode) || (tx.notes != null && tx.notes!.contains(targetCode))) {
          return true;
        }
      }
      return false;
    });
  }

  /// Helper to format currency in Rupiah (without decimals, e.g. Rp5.250.000).
  static String formatRupiah(num amount) {
    final isNegative = amount < 0;
    final absAmount = amount.abs().round();
    final str = absAmount.toString();
    final buffer = StringBuffer();
    int count = 0;

    for (int i = str.length - 1; i >= 0; i--) {
      buffer.write(str[i]);
      count++;
      if (count % 3 == 0 && i != 0) {
        buffer.write('.');
      }
    }

    final reversed = buffer.toString().split('').reversed.join('');
    return '${isNegative ? '-' : ''}Rp$reversed';
  }
}
