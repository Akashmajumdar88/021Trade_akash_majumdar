import 'package:uuid/uuid.dart';

/// A named watchlist containing an ordered list of stock symbols.
class Watchlist {
  final String id;
  final String name;

  /// Ordered list of stock symbols in this watchlist.
  final List<String> symbols;

  const Watchlist({
    required this.id,
    required this.name,
    required this.symbols,
  });

  /// Creates a new empty watchlist with a generated UUID.
  factory Watchlist.create(String name) {
    return Watchlist(
      id: const Uuid().v4(),
      name: name,
      symbols: const [],
    );
  }

  Watchlist copyWith({String? id, String? name, List<String>? symbols}) {
    return Watchlist(
      id: id ?? this.id,
      name: name ?? this.name,
      symbols: symbols ?? this.symbols,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'symbols': symbols,
      };

  factory Watchlist.fromJson(Map<String, dynamic> json) {
    return Watchlist(
      id: json['id'] as String,
      name: json['name'] as String,
      symbols: List<String>.from(json['symbols'] as List),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Watchlist &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Watchlist(id: $id, name: $name, symbols: $symbols)';
}
