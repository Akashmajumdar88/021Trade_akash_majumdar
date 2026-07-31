import 'package:uuid/uuid.dart';

enum OrderSide { buy, sell }

/// An executed simulated market order.
class Order {
  final String id;
  final String symbol;
  final OrderSide side;
  final int quantity;

  /// Price at which the order was executed (LTP at submit time).
  final double price;

  /// Total order value = quantity × price (pre-computed, stored for display).
  final double totalValue;

  final DateTime timestamp;

  const Order({
    required this.id,
    required this.symbol,
    required this.side,
    required this.quantity,
    required this.price,
    required this.totalValue,
    required this.timestamp,
  });

  /// Factory that captures the current timestamp and computes totalValue.
  factory Order.create({
    required String symbol,
    required OrderSide side,
    required int quantity,
    required double price,
  }) {
    // Round to 2 dp to avoid any floating-point drift in stored value.
    final total =
        double.parse((quantity * price).toStringAsFixed(2));
    return Order(
      id: const Uuid().v4(),
      symbol: symbol,
      side: side,
      quantity: quantity,
      price: price,
      totalValue: total,
      timestamp: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'symbol': symbol,
        'side': side.name,
        'quantity': quantity,
        'price': price,
        'totalValue': totalValue,
        'timestamp': timestamp.toIso8601String(),
      };

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] as String,
      symbol: json['symbol'] as String,
      side: OrderSide.values.byName(json['side'] as String),
      quantity: json['quantity'] as int,
      price: (json['price'] as num).toDouble(),
      totalValue: (json['totalValue'] as num).toDouble(),
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  @override
  String toString() =>
      'Order(id: $id, $side ${quantity}x $symbol @ ₹$price)';
}
