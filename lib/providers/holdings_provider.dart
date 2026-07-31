import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/utils/currency_utils.dart';
import '../data/models/holding.dart';
import '../data/services/persistence_service.dart';
import 'market_feed_provider.dart';

// ─── Sort order ───────────────────────────────────────────────────────────────

enum HoldingsSortOrder { pnlDesc, symbolAsc, valueDesc }

final holdingsSortProvider = StateProvider<HoldingsSortOrder>(
  (ref) => HoldingsSortOrder.pnlDesc,
);

// ─── Holdings notifier ────────────────────────────────────────────────────────

class HoldingsNotifier extends StateNotifier<List<Holding>> {
  final PersistenceService _persistence;

  HoldingsNotifier(this._persistence) : super([]) {
    _load();
  }

  void _load() {
    state = _persistence.loadHoldings();
  }

  void _save() {
    _persistence.saveHoldings(state);
  }

  /// Upserts a holding after a Buy order.
  /// Updates quantity and recalculates weighted-average cost.
  void buy(String symbol, int quantity, double price) {
    final idx = state.indexWhere((h) => h.symbol == symbol);

    if (idx == -1) {
      // New position.
      state = [
        ...state,
        Holding(symbol: symbol, quantity: quantity, avgCost: price),
      ];
    } else {
      final existing = state[idx];
      final newAvgCost = CurrencyUtils.weightedAvgCost(
          existing.quantity, existing.avgCost, quantity, price);
      final updated = [...state];
      updated[idx] = existing.copyWith(
          quantity: existing.quantity + quantity, avgCost: newAvgCost);
      state = updated;
    }
    _save();
  }

  /// Reduces quantity after a Sell order.
  /// Removes the holding entirely when quantity reaches zero.
  /// Returns [false] if the symbol is not held or [quantity] exceeds held qty.
  bool sell(String symbol, int quantity) {
    final idx = state.indexWhere((h) => h.symbol == symbol);
    if (idx == -1) return false;

    final existing = state[idx];
    if (existing.quantity < quantity) return false;

    final updated = [...state];
    if (existing.quantity == quantity) {
      updated.removeAt(idx);
    } else {
      updated[idx] =
          existing.copyWith(quantity: existing.quantity - quantity);
    }
    state = updated;
    _save();
    return true;
  }

  /// Returns the holding for [symbol], or null if not held.
  Holding? getHolding(String symbol) {
    for (final h in state) {
      if (h.symbol == symbol) return h;
    }
    return null;
  }
}

final holdingsProvider =
    StateNotifierProvider<HoldingsNotifier, List<Holding>>(
  (ref) => HoldingsNotifier(ref.watch(persistenceServiceProvider)),
);

// ─── Sorted holdings derived provider ────────────────────────────────────────
// Rebuilds when holdings change, sort order changes, OR when any held stock's
// price changes (via per-symbol .select calls in the loop).

final sortedHoldingsProvider = Provider<List<Holding>>((ref) {
  final holdings = ref.watch(holdingsProvider);
  final sortOrder = ref.watch(holdingsSortProvider);

  if (holdings.isEmpty) return const [];

  // For price-dependent sorts, collect the current LTP for each held symbol
  // by watching only those specific entries in the market feed map.
  // This avoids rebuilding when unrelated stocks tick.
  final prices = <String, double>{};
  for (final h in holdings) {
    prices[h.symbol] = ref.watch(
          marketFeedProvider.select((m) => m[h.symbol]?.price),
        ) ??
        h.avgCost;
  }

  final sorted = [...holdings];

  switch (sortOrder) {
    case HoldingsSortOrder.pnlDesc:
      sorted.sort((a, b) {
        final aPnl = a.pnl(prices[a.symbol]!);
        final bPnl = b.pnl(prices[b.symbol]!);
        return bPnl.compareTo(aPnl);
      });
    case HoldingsSortOrder.symbolAsc:
      sorted.sort((a, b) => a.symbol.compareTo(b.symbol));
    case HoldingsSortOrder.valueDesc:
      sorted.sort((a, b) {
        final aVal = a.currentValue(prices[a.symbol]!);
        final bVal = b.currentValue(prices[b.symbol]!);
        return bVal.compareTo(aVal);
      });
  }

  return sorted;
});
