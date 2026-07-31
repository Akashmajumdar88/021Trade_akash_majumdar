/// Formatting helpers for currency and percentage values.
/// All display formatting is isolated here to ensure consistency.
class CurrencyUtils {
  CurrencyUtils._();

  /// Formats a price with ₹ prefix and 2 decimal places.
  static String formatPrice(double price) {
    return '₹${price.toStringAsFixed(2)}';
  }

  /// Formats an absolute change with sign prefix (no ₹).
  static String formatChange(double change) {
    final sign = change >= 0 ? '+' : '';
    return '$sign${change.toStringAsFixed(2)}';
  }

  /// Formats a percentage change with sign prefix.
  static String formatChangePercent(double pct) {
    final sign = pct >= 0 ? '+' : '';
    return '$sign${pct.toStringAsFixed(2)}%';
  }

  /// Formats P&L in ₹ with sign.
  static String formatPnl(double pnl) {
    final sign = pnl >= 0 ? '+' : '';
    return '$sign₹${pnl.toStringAsFixed(2)}';
  }

  /// Formats P&L percentage with sign.
  static String formatPnlPercent(double pct) {
    final sign = pct >= 0 ? '+' : '';
    return '$sign${pct.toStringAsFixed(2)}%';
  }

  /// Compact Indian number formatting (lakhs / crores) for large values.
  static String formatINR(double value) {
    final absVal = value.abs();
    final sign = value < 0 ? '-' : '';
    if (absVal >= 10000000) {
      return '${sign}₹${(absVal / 10000000).toStringAsFixed(2)} Cr';
    } else if (absVal >= 100000) {
      return '${sign}₹${(absVal / 100000).toStringAsFixed(2)} L';
    } else {
      return '${sign}₹${absVal.toStringAsFixed(2)}';
    }
  }

  /// Precise multiplication that avoids floating-point drift in displayed values.
  /// Uses string round-trip at 6 significant decimals for intermediate precision.
  static double preciseMultiply(double a, double b) {
    return double.parse((a * b).toStringAsFixed(6));
  }

  /// Weighted average cost: (qty1*price1 + qty2*price2) / (qty1+qty2).
  static double weightedAvgCost(
      int qty1, double price1, int qty2, double price2) {
    final totalCost = preciseMultiply(qty1.toDouble(), price1) +
        preciseMultiply(qty2.toDouble(), price2);
    final totalQty = qty1 + qty2;
    return double.parse((totalCost / totalQty).toStringAsFixed(6));
  }
}
