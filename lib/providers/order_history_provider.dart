import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/order.dart';
import '../data/services/persistence_service.dart';

/// Maintains the chronological history of all executed orders.
class OrderHistoryNotifier extends StateNotifier<List<Order>> {
  final PersistenceService _persistence;

  OrderHistoryNotifier(this._persistence) : super([]) {
    _load();
  }

  void _load() {
    state = _persistence.loadOrders();
  }

  void _save() {
    _persistence.saveOrders(state);
  }

  /// Prepends the new order so the list is always newest-first.
  void addOrder(Order order) {
    state = [order, ...state];
    _save();
  }
}

final orderHistoryProvider =
    StateNotifierProvider<OrderHistoryNotifier, List<Order>>(
  (ref) => OrderHistoryNotifier(ref.watch(persistenceServiceProvider)),
);
