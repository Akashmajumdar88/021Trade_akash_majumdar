import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/watchlist.dart';
import '../data/services/persistence_service.dart';

class WatchlistNotifier extends StateNotifier<List<Watchlist>> {
  final PersistenceService _persistence;

  WatchlistNotifier(this._persistence) : super([]) {
    _load();
  }

  void _load() {
    state = _persistence.loadWatchlists();
  }

  void _save() {
    _persistence.saveWatchlists(state);
  }

  // ── Watchlist-level CRUD ──────────────────────────────────────────────────

  void createWatchlist(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    state = [...state, Watchlist.create(trimmed)];
    _save();
  }

  void renameWatchlist(String id, String newName) {
    final trimmed = newName.trim();
    if (trimmed.isEmpty) return;
    state = state
        .map((w) => w.id == id ? w.copyWith(name: trimmed) : w)
        .toList();
    _save();
  }

  void deleteWatchlist(String id) {
    state = state.where((w) => w.id != id).toList();
    _save();
  }

  // ── Stock-level operations ────────────────────────────────────────────────

  /// Adds [symbol] to the end of the watchlist if not already present.
  void addStock(String watchlistId, String symbol) {
    state = state.map((w) {
      if (w.id != watchlistId) return w;
      if (w.symbols.contains(symbol)) return w;
      return w.copyWith(symbols: [...w.symbols, symbol]);
    }).toList();
    _save();
  }

  /// Removes [symbol] from the specified watchlist.
  void removeStock(String watchlistId, String symbol) {
    state = state.map((w) {
      if (w.id != watchlistId) return w;
      return w.copyWith(
          symbols: w.symbols.where((s) => s != symbol).toList());
    }).toList();
    _save();
  }

  /// Handles the reorder index adjustment that [ReorderableListView] requires.
  void reorderStocks(String watchlistId, int oldIndex, int newIndex) {
    state = state.map((w) {
      if (w.id != watchlistId) return w;
      final symbols = [...w.symbols];
      // ReorderableListView passes newIndex *before* the removal, so adjust.
      if (oldIndex < newIndex) newIndex -= 1;
      final item = symbols.removeAt(oldIndex);
      symbols.insert(newIndex, item);
      return w.copyWith(symbols: symbols);
    }).toList();
    _save();
  }
}

final watchlistProvider =
    StateNotifierProvider<WatchlistNotifier, List<Watchlist>>(
  (ref) => WatchlistNotifier(ref.watch(persistenceServiceProvider)),
);
