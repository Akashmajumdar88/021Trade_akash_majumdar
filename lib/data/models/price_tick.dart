/// Represents a single price tick emitted by the mock market feed.
class PriceTick {
  final String symbol;

  /// Current last traded price (LTP).
  final double price;

  /// Price before this tick (used to determine flash direction).
  final double prevPrice;

  /// Day's opening price (used for day change calculation).
  final double openPrice;

  /// Absolute day change: price − openPrice.
  final double change;

  /// Percentage day change: (change / openPrice) × 100.
  final double changePercent;

  final DateTime timestamp;

  const PriceTick({
    required this.symbol,
    required this.price,
    required this.prevPrice,
    required this.openPrice,
    required this.change,
    required this.changePercent,
    required this.timestamp,
  });

  /// True when this tick moved the price up vs the previous tick.
  bool get isUp => price > prevPrice;

  /// True when this tick moved the price down vs the previous tick.
  bool get isDown => price < prevPrice;

  /// True when the price did not change vs the previous tick.
  bool get isFlat => price == prevPrice;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PriceTick &&
          runtimeType == other.runtimeType &&
          symbol == other.symbol &&
          price == other.price &&
          timestamp == other.timestamp;

  @override
  int get hashCode => Object.hash(symbol, price, timestamp);
}
