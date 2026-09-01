import 'package:flutter/widgets.dart';

/// Represents daily revenue with percent change
class DailyRevenue {
  final double amount;
  final double percentChange;

  const DailyRevenue({
    required this.amount,
    required this.percentChange,
  });
}

/// Represents an AI insight message
class AIInsight {
  final String message;
  final DateTime timestamp;

  const AIInsight({
    required this.message,
    required this.timestamp,
  });
}

/// Represents a low stock alert
class StockAlert {
  final String name;
  final double quantity;
  final String unit;
  final IconData iconData;

  const StockAlert({
    required this.name,
    required this.quantity,
    required this.unit,
    required this.iconData,
  });
}

/// Represents daily activity including transaction count and best seller info
class DailyActivity {
  final int transactionCount;
  final double percentChange;
  final String bestSellerName;
  final double bestSellerQty;
  final String bestSellerUnit;

  const DailyActivity({
    required this.transactionCount,
    required this.percentChange,
    required this.bestSellerName,
    required this.bestSellerQty,
    required this.bestSellerUnit,
  });
}
