import 'package:flutter/material.dart';
import '../core/services/api_service.dart';

/// Status of stock item based on current stock vs minimum stock.
enum StockStatus {
  baik('Aman', 'Stok mencukupi kebutuhan operasional', Icons.check_circle_rounded),
  rendah('Rendah', 'Stok mendekati batas minimum', Icons.warning_amber_rounded),
  kritis('Kritis', 'Stok di bawah batas aman, perlu segera restock', Icons.error_outline_rounded);

  final String label;
  final String description;
  final IconData icon;
  const StockStatus(this.label, this.description, this.icon);
}

/// Category of raw material.
enum StockCategory {
  all('Semua'),
  kopi('Kopi'),
  dairy('Dairy & Susu'),
  pemanis('Pemanis & Gula'),
  sirup('Sirup'),
  kemasan('Kemasan'),
  topping('Topping'),
  makanan('Makanan'),
  bahanBaku('Lainnya'),
  merchandise('Merchandise');

  final String label;
  const StockCategory(this.label);
}

/// Sorting options for stock listing.
enum StockSortBy {
  nameAsc('Nama (A - Z)', Icons.sort_by_alpha_rounded),
  stockAsc('Stok Terendah (Prioritas Restock)', Icons.arrow_upward_rounded),
  stockDesc('Stok Tertinggi', Icons.arrow_downward_rounded),
  valueDesc('Nilai Aset Terbesar', Icons.monetization_on_outlined);

  final String label;
  final IconData icon;
  const StockSortBy(this.label, this.icon);
}

/// Type of stock movement log.
enum StockLogType {
  inStock('Masuk', Icons.add_circle_outline_rounded),
  out('Keluar', Icons.remove_circle_outline_rounded),
  adjustment('Penyesuaian', Icons.tune_rounded);

  final String label;
  final IconData icon;
  const StockLogType(this.label, this.icon);
}

/// Represents a raw material / ingredient stock item.
class StockItem {
  final String id;
  final String name;
  final StockCategory category;
  final double currentStock;
  final double minStock;
  final String unit; // 'kg', 'L', 'btl', 'g', 'pcs'
  final int costPerUnit; // Rupiah per unit
  final int sellingPrice; // Selling price in POS if applicable
  final bool isPosProduct; // Whether synced to POS kasir
  final DateTime lastUpdated;
  final String supplier;
  final List<String> linkedProducts;
  final String? note;
  final IconData icon;

  const StockItem({
    required this.id,
    required this.name,
    required this.category,
    required this.currentStock,
    required this.minStock,
    required this.unit,
    required this.costPerUnit,
    this.sellingPrice = 0,
    this.isPosProduct = false,
    required this.lastUpdated,
    this.supplier = 'Supplier Utama',
    this.linkedProducts = const [],
    this.note,
    this.icon = Icons.inventory_2_rounded,
  });

  /// Dynamically computes status based on stock thresholds.
  StockStatus get status {
    if (currentStock <= minStock * 0.6) {
      return StockStatus.kritis;
    } else if (currentStock <= minStock) {
      return StockStatus.rendah;
    } else {
      return StockStatus.baik;
    }
  }

  /// Percentage ratio against minimum stock (0.0 to 1.0+).
  double get healthRatio {
    if (minStock <= 0) return 1.0;
    return (currentStock / (minStock * 2)).clamp(0.0, 1.0);
  }

  /// Ratio relative to minimum safety stock threshold (0.0 to 1.0).
  double get minThresholdRatio {
    if (minStock <= 0) return 1.0;
    return (currentStock / minStock).clamp(0.0, 1.0);
  }

  /// Percentage relative to minimum safety stock threshold.
  int get minThresholdPercentage {
    if (minStock <= 0) return 100;
    return (currentStock / minStock * 100).round();
  }

  /// Estimated total asset value.
  int get totalValue => (currentStock * costPerUnit).round();

  String get formattedCurrentStock {
    if (currentStock == currentStock.roundToDouble()) {
      return '${currentStock.toInt()} $unit';
    }
    return '${currentStock.toStringAsFixed(1)} $unit';
  }

  String get formattedMinStock {
    if (minStock == minStock.roundToDouble()) {
      return '${minStock.toInt()} $unit';
    }
    return '${minStock.toStringAsFixed(1)} $unit';
  }

  String get formattedCostPerUnit => formatRupiah(costPerUnit);
  String get formattedTotalValue => formatRupiah(totalValue);

  static String formatRupiah(int amount) {
    final str = amount.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) buffer.write('.');
      buffer.write(str[i]);
    }
    return 'Rp $buffer';
  }

  StockItem copyWith({
    String? id,
    String? name,
    StockCategory? category,
    double? currentStock,
    double? minStock,
    String? unit,
    int? costPerUnit,
    int? sellingPrice,
    bool? isPosProduct,
    DateTime? lastUpdated,
    String? supplier,
    List<String>? linkedProducts,
    String? note,
    IconData? icon,
  }) {
    return StockItem(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      currentStock: currentStock ?? this.currentStock,
      minStock: minStock ?? this.minStock,
      unit: unit ?? this.unit,
      costPerUnit: costPerUnit ?? this.costPerUnit,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      isPosProduct: isPosProduct ?? this.isPosProduct,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      supplier: supplier ?? this.supplier,
      linkedProducts: linkedProducts ?? this.linkedProducts,
      note: note ?? this.note,
      icon: icon ?? this.icon,
    );
  }
}

/// Represents an individual stock movement log (audit trail).
class StockLog {
  final String id;
  final String stockId;
  final String stockName;
  final StockLogType type;
  final double quantity; // positive delta
  final String unit;
  final String source; // 'POS', 'Restock', 'Stock Opname', 'AI Agent'
  final String? referenceCode;
  final String operatorName;
  final DateTime timestamp;
  final String? note;

  const StockLog({
    required this.id,
    required this.stockId,
    required this.stockName,
    required this.type,
    required this.quantity,
    required this.unit,
    required this.source,
    this.referenceCode,
    this.operatorName = 'Kasir',
    required this.timestamp,
    this.note,
  });

  String get formattedQuantity {
    final qtyStr = quantity == quantity.roundToDouble()
        ? quantity.toInt().toString()
        : quantity.toStringAsFixed(1);

    if (type == StockLogType.out) {
      return '-$qtyStr $unit';
    } else if (type == StockLogType.inStock) {
      return '+$qtyStr $unit';
    } else {
      return '±$qtyStr $unit';
    }
  }

  String get formattedDate {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inDays == 0 && now.day == timestamp.day) {
      final hour = timestamp.hour.toString().padLeft(2, '0');
      final min = timestamp.minute.toString().padLeft(2, '0');
      return 'Hari ini, $hour:$min';
    } else if (diff.inDays <= 1 || (now.day - timestamp.day == 1 && diff.inDays < 2)) {
      final hour = timestamp.hour.toString().padLeft(2, '0');
      final min = timestamp.minute.toString().padLeft(2, '0');
      return 'Kemarin, $hour:$min';
    } else {
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
        'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
      ];
      final monthName = months[timestamp.month - 1];
      final hour = timestamp.hour.toString().padLeft(2, '0');
      final min = timestamp.minute.toString().padLeft(2, '0');
      return '${timestamp.day} $monthName, $hour:$min';
    }
  }
}

/// Global repository & state notifier for Stock management.
class StockRepository extends ChangeNotifier {
  static final StockRepository instance = StockRepository._internal();
  StockRepository._internal() {
    _initDefaultData();
  }

  final List<StockItem> _items = [];
  final List<StockLog> _logs = [];

  List<StockItem> get items => List.unmodifiable(_items);
  List<StockLog> get logs => List.unmodifiable(_logs);

  void clearForNewUser() {
    _items.clear();
    _logs.clear();
    notifyListeners();
  }

  void loadDemoData() {
    _items.clear();
    _logs.clear();
    _initDefaultData();
    notifyListeners();
  }

  void setItems(List<StockItem> newItems) {
    _items.clear();
    _items.addAll(newItems);
    notifyListeners();
  }

  int get totalItemsCount => _items.length;
  int get lowStockCount =>
      _items.where((i) => i.status == StockStatus.rendah).length;
  int get criticalStockCount =>
      _items.where((i) => i.status == StockStatus.kritis).length;
  int get safeStockCount =>
      _items.where((i) => i.status == StockStatus.baik).length;

  int get totalInventoryValue =>
      _items.fold(0, (sum, item) => sum + item.totalValue);

  StockItem? getItemById(String id) {
    try {
      return _items.firstWhere((i) => i.id == id);
    } catch (_) {
      return null;
    }
  }

  List<StockLog> getLogsForStock(String stockId) {
    return _logs.where((l) => l.stockId == stockId).toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  /// Restock an existing item with purchase tracking.
  void restockItem({
    required String stockId,
    required double quantity,
    int? costPerUnit,
    String? supplier,
    String? note,
    String operatorName = 'Owner',
  }) {
    final index = _items.indexWhere((i) => i.id == stockId);
    if (index == -1) return;

    final current = _items[index];
    final updated = current.copyWith(
      currentStock: current.currentStock + quantity,
      costPerUnit: costPerUnit ?? current.costPerUnit,
      supplier: (supplier != null && supplier.isNotEmpty) ? supplier : current.supplier,
      lastUpdated: DateTime.now(),
    );
    _items[index] = updated;

    _logs.insert(
      0,
      StockLog(
        id: 'log_${DateTime.now().millisecondsSinceEpoch}',
        stockId: stockId,
        stockName: current.name,
        type: StockLogType.inStock,
        quantity: quantity,
        unit: current.unit,
        source: 'Restock / Pembelian',
        referenceCode: '#RC-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
        operatorName: operatorName,
        timestamp: DateTime.now(),
        note: note,
      ),
    );

    notifyListeners();
  }

  /// Adjust stock based on physical count (Stock Opname).
  void adjustStock({
    required String stockId,
    required double actualQuantity,
    required String reason,
    String? note,
    String operatorName = 'Owner',
  }) {
    final index = _items.indexWhere((i) => i.id == stockId);
    if (index == -1) return;

    final current = _items[index];
    final delta = (actualQuantity - current.currentStock).abs();
    final isDeduction = actualQuantity < current.currentStock;

    final updated = current.copyWith(
      currentStock: actualQuantity,
      lastUpdated: DateTime.now(),
    );
    _items[index] = updated;

    _logs.insert(
      0,
      StockLog(
        id: 'log_${DateTime.now().millisecondsSinceEpoch}',
        stockId: stockId,
        stockName: current.name,
        type: isDeduction ? StockLogType.out : StockLogType.inStock,
        quantity: delta,
        unit: current.unit,
        source: 'Opname: $reason',
        referenceCode: '#OP-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
        operatorName: operatorName,
        timestamp: DateTime.now(),
        note: note,
      ),
    );

    notifyListeners();
  }

  Future<void> fetchStocksFromBackend() async {
    try {
      final res = await ApiService.instance.get('/stocks');
      if (res != null && res['stockItems'] is List) {
        final List list = res['stockItems'];
        final List<StockItem> loaded = [];
        for (final item in list) {
          StockCategory cat = StockCategory.pemanis;
          final catStr = (item['category'] ?? '').toString().toLowerCase();
          if (catStr.contains('kopi') || catStr.contains('bean')) {
            cat = StockCategory.kopi;
          } else if (catStr.contains('susu') || catStr.contains('dairy') || catStr.contains('milk')) {
            cat = StockCategory.dairy;
          } else if (catStr.contains('sirup') || catStr.contains('perasa') || catStr.contains('syrup')) {
            cat = StockCategory.sirup;
          } else if (catStr.contains('kemas') || catStr.contains('cup')) {
            cat = StockCategory.kemasan;
          }

          loaded.add(StockItem(
            id: (item['stock_id'] ?? item['id'] ?? 'stock-${DateTime.now().millisecondsSinceEpoch}').toString(),
            name: (item['name'] ?? 'Bahan').toString(),
            category: cat,
            currentStock: (item['current_stock'] as num?)?.toDouble() ?? 0.0,
            minStock: (item['min_stock'] as num?)?.toDouble() ?? 5.0,
            unit: (item['unit'] ?? 'kg').toString(),
            costPerUnit: (item['cost_per_unit'] as num?)?.toInt() ?? 0,
            supplier: item['supplier'],
            lastUpdated: item['last_updated'] != null
                ? DateTime.tryParse(item['last_updated']) ?? DateTime.now()
                : DateTime.now(),
          ));
        }
        _items.clear();
        _items.addAll(loaded);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('⚠️ fetchStocksFromBackend error: $e');
    }
  }

  /// Add a brand new stock raw material.
  void addStockItem(StockItem item) {
    _items.add(item);
    _logs.insert(
      0,
      StockLog(
        id: 'log_${DateTime.now().millisecondsSinceEpoch}',
        stockId: item.id,
        stockName: item.name,
        type: StockLogType.inStock,
        quantity: item.currentStock,
        unit: item.unit,
        source: 'Stok Awal',
        operatorName: 'Owner',
        timestamp: DateTime.now(),
        note: 'Pendaftaran bahan baku baru',
      ),
    );
    notifyListeners();

    // Sync to backend
    ApiService.instance.post('/stocks', {
      'name': item.name,
      'category': item.category.label,
      'current_stock': item.currentStock,
      'min_stock': item.minStock,
      'unit': item.unit,
      'cost_per_unit': item.costPerUnit,
      'supplier': item.supplier,
    }).catchError((_) => null);
  }

  /// Update details of existing item.
  void updateStockItem(StockItem item) {
    final index = _items.indexWhere((i) => i.id == item.id);
    if (index != -1) {
      _items[index] = item;
      notifyListeners();
    }
    // Sync to backend
    ApiService.instance.put('/stocks/${item.id}', {
      'name': item.name,
      'category': item.category.label,
      'current_stock': item.currentStock,
      'min_stock': item.minStock,
      'unit': item.unit,
      'cost_per_unit': item.costPerUnit,
      'supplier': item.supplier,
    }).catchError((_) => null);
  }

  /// Delete stock item.
  void deleteStockItem(String stockId) {
    _items.removeWhere((i) => i.id == stockId);
    _logs.removeWhere((l) => l.stockId == stockId);
    notifyListeners();
    // Sync to backend
    ApiService.instance.delete('/stocks/$stockId').catchError((_) => null);
  }

  void _initDefaultData() {
    final now = DateTime.now();

    _items.addAll([
      StockItem(
        id: 'sugar',
        name: 'Sugar',
        category: StockCategory.pemanis,
        currentStock: 3.0,
        minStock: 5.0,
        unit: 'kg',
        costPerUnit: 16000,
        lastUpdated: now.subtract(const Duration(minutes: 28)),
        supplier: 'PT Sumber Manis Nusantara',
        linkedProducts: ['Iced Latte', 'Cappuccino', 'Chocolate', 'Matcha Latte', 'Croissant'],
        icon: Icons.grain_rounded,
        note: 'Gula pasir kristal putih premium',
      ),
      StockItem(
        id: 'fresh_milk',
        name: 'Fresh Milk',
        category: StockCategory.dairy,
        currentStock: 5.0,
        minStock: 8.0,
        unit: 'L',
        costPerUnit: 24000,
        lastUpdated: now.subtract(const Duration(hours: 2)),
        supplier: 'Greenfield Dairy Farm',
        linkedProducts: ['Iced Latte', 'Cappuccino', 'Matcha Latte', 'Chocolate'],
        icon: Icons.water_drop_rounded,
        note: 'Pasteurized Fresh Milk 1L per pack',
      ),
      StockItem(
        id: 'coffee_beans',
        name: 'Coffee Beans',
        category: StockCategory.kopi,
        currentStock: 8.0,
        minStock: 3.0,
        unit: 'kg',
        costPerUnit: 95000,
        lastUpdated: now.subtract(const Duration(hours: 4)),
        supplier: 'Aceh Gayo Specialty Roastery',
        linkedProducts: ['Iced Latte', 'Americano', 'Cappuccino'],
        icon: Icons.coffee_rounded,
        note: 'House Blend 70% Arabica Gayo & 30% Robusta Temanggung',
      ),
      StockItem(
        id: 'chocolate_syrup',
        name: 'Chocolate Syrup',
        category: StockCategory.sirup,
        currentStock: 6.0,
        minStock: 2.0,
        unit: 'btl',
        costPerUnit: 65000,
        lastUpdated: now.subtract(const Duration(days: 1)),
        supplier: 'Diva Flavor Indonesia',
        linkedProducts: ['Chocolate', 'Iced Latte'],
        icon: Icons.liquor_rounded,
        note: 'Botol 750ml rasa Dark Rich Chocolate',
      ),
      StockItem(
        id: 'caramel_syrup',
        name: 'Caramel Syrup',
        category: StockCategory.sirup,
        currentStock: 1.5,
        minStock: 2.0,
        unit: 'btl',
        costPerUnit: 68000,
        lastUpdated: now.subtract(const Duration(hours: 5)),
        supplier: 'Diva Flavor Indonesia',
        linkedProducts: ['Iced Latte', 'Cappuccino'],
        icon: Icons.liquor_rounded,
      ),
      StockItem(
        id: 'cup_16oz',
        name: 'Cup Plastic 16oz + Lid',
        category: StockCategory.kemasan,
        currentStock: 45.0,
        minStock: 100.0,
        unit: 'pcs',
        costPerUnit: 850,
        lastUpdated: now.subtract(const Duration(hours: 3)),
        supplier: 'Mitra Pack Tangerang',
        linkedProducts: ['Iced Latte', 'Americano', 'Chocolate', 'Matcha Latte'],
        icon: Icons.local_drink_rounded,
      ),
      StockItem(
        id: 'matcha_powder',
        name: 'Matcha Powder Uji',
        category: StockCategory.topping,
        currentStock: 1.2,
        minStock: 0.8,
        unit: 'kg',
        costPerUnit: 140000,
        lastUpdated: now.subtract(const Duration(days: 2)),
        supplier: 'Uji Tea Imports',
        linkedProducts: ['Matcha Latte'],
        icon: Icons.spa_rounded,
      ),
      StockItem(
        id: 'oat_milk',
        name: 'Oat Milk Barista',
        category: StockCategory.dairy,
        currentStock: 4.0,
        minStock: 3.0,
        unit: 'L',
        costPerUnit: 42000,
        lastUpdated: now.subtract(const Duration(days: 1)),
        supplier: 'Oatside Official',
        linkedProducts: ['Matcha Latte', 'Iced Latte'],
        icon: Icons.eco_rounded,
      ),
    ]);

    // Initial realistic logs for Sugar (matching screenshot)
    _logs.addAll([
      StockLog(
        id: 'log_1',
        stockId: 'sugar',
        stockName: 'Sugar',
        type: StockLogType.out,
        quantity: 2.0,
        unit: 'kg',
        source: 'POS',
        referenceCode: '#POS-8895',
        operatorName: 'Kasir Budi',
        timestamp: now.subtract(const Duration(days: 1, hours: 2)),
        note: 'Penjualan minuman shift sore',
      ),
      StockLog(
        id: 'log_2',
        stockId: 'sugar',
        stockName: 'Sugar',
        type: StockLogType.out,
        quantity: 1.5,
        unit: 'kg',
        source: 'POS',
        referenceCode: '#POS-8890',
        operatorName: 'Kasir Budi',
        timestamp: now.subtract(const Duration(days: 1, hours: 6)),
        note: 'Penjualan minuman shift pagi',
      ),
      StockLog(
        id: 'log_3',
        stockId: 'sugar',
        stockName: 'Sugar',
        type: StockLogType.inStock,
        quantity: 10.0,
        unit: 'kg',
        source: 'Restock / Pembelian',
        referenceCode: '#PO-2026-08',
        operatorName: 'Owner',
        timestamp: now.subtract(const Duration(days: 11)),
        note: 'Pembelian stok grosir mingguan',
      ),
      StockLog(
        id: 'log_4',
        stockId: 'coffee_beans',
        stockName: 'Coffee Beans',
        type: StockLogType.out,
        quantity: 0.8,
        unit: 'kg',
        source: 'POS',
        referenceCode: '#POS-8901',
        operatorName: 'Kasir Budi',
        timestamp: now.subtract(const Duration(hours: 3)),
        note: 'Espresso extraction batches',
      ),
      StockLog(
        id: 'log_5',
        stockId: 'fresh_milk',
        stockName: 'Fresh Milk',
        type: StockLogType.out,
        quantity: 3.0,
        unit: 'L',
        source: 'POS',
        referenceCode: '#POS-8900',
        operatorName: 'Kasir Budi',
        timestamp: now.subtract(const Duration(hours: 2)),
      ),
    ]);
  }
}
