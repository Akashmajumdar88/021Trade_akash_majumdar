/// Represents a currently held position in a stock.
class Holding {
  final String symbol;
  final int quantity;

  /// Weighted-average acquisition cost per share.
  final double avgCost;

  const Holding({
    required this.symbol,
    required this.quantity,
    required this.avgCost,
  });

  // ─── Computed metrics (require live LTP) ────────────────────────────────

  double investedValue() => quantity * avgCost;

  double currentValue(double ltp) => quantity * ltp;

  double pnl(double ltp) => currentValue(ltp) - investedValue();

  double pnlPercent(double ltp) {
    final invested = investedValue();
    if (invested == 0) return 0;
    return (pnl(ltp) / invested) * 100;
  }

  // ─── Boilerplate ─────────────────────────────────────────────────────────

  Holding copyWith({String? symbol, int? quantity, double? avgCost}) {
    return Holding(
      symbol: symbol ?? this.symbol,
      quantity: quantity ?? this.quantity,
      avgCost: avgCost ?? this.avgCost,
    );
  }

  Map<String, dynamic> toJson() => {
        'symbol': symbol,
        'quantity': quantity,
        'avgCost': avgCost,
      };

  factory Holding.fromJson(Map<String, dynamic> json) {
    return Holding(
      symbol: json['symbol'] as String,
      quantity: json['quantity'] as int,
      avgCost: (json['avgCost'] as num).toDouble(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Holding &&
          runtimeType == other.runtimeType &&
          symbol == other.symbol;

  @override
  int get hashCode => symbol.hashCode;

  @override
  String toString() =>
      'Holding(symbol: $symbol, qty: $quantity, avgCost: $avgCost)';
}
