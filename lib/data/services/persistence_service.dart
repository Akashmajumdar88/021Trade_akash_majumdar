import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/holding.dart';
import '../models/order.dart';
import '../models/watchlist.dart';

// ─── SharedPreferences provider ─────────────────────────────────────────────
// Overridden in main.dart with the real instance.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError(
      'sharedPreferencesProvider must be overridden in main()'),
);

// ─── Storage keys ────────────────────────────────────────────────────────────
const _kWatchlists = 'watchlists_v1';
const _kHoldings = 'holdings_v1';
const _kWallet = 'wallet_balance_v1';
const _kOrders = 'order_history_v1';

/// Thin wrapper over SharedPreferences that handles JSON encode/decode for
/// each domain entity. All methods are synchronous for reads and async for
/// writes (fire-and-forget is fine since we persist on every mutation).
class PersistenceService {
  final SharedPreferences _prefs;
  PersistenceService(this._prefs);

  // ── Watchlists ─────────────────────────────────────────────────────────────

  List<Watchlist> loadWatchlists() {
    final raw = _prefs.getString(_kWatchlists);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list
          .map((e) => Watchlist.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveWatchlists(List<Watchlist> watchlists) =>
      _prefs.setString(
          _kWatchlists, jsonEncode(watchlists.map((w) => w.toJson()).toList()));

  // ── Holdings ───────────────────────────────────────────────────────────────

  List<Holding> loadHoldings() {
    final raw = _prefs.getString(_kHoldings);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list
          .map((e) => Holding.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveHoldings(List<Holding> holdings) =>
      _prefs.setString(
          _kHoldings, jsonEncode(holdings.map((h) => h.toJson()).toList()));

  // ── Wallet ─────────────────────────────────────────────────────────────────

  double loadWallet(double defaultBalance) =>
      _prefs.getDouble(_kWallet) ?? defaultBalance;

  Future<void> saveWallet(double balance) =>
      _prefs.setDouble(_kWallet, balance);

  // ── Order history ──────────────────────────────────────────────────────────

  List<Order> loadOrders() {
    final raw = _prefs.getString(_kOrders);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list
          .map((e) => Order.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveOrders(List<Order> orders) =>
      _prefs.setString(
          _kOrders, jsonEncode(orders.map((o) => o.toJson()).toList()));
}

// ─── Service provider ────────────────────────────────────────────────────────
final persistenceServiceProvider = Provider<PersistenceService>(
  (ref) => PersistenceService(ref.watch(sharedPreferencesProvider)),
);
