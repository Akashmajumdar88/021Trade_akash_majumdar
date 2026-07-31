import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/stocks.dart';
import '../data/models/price_tick.dart';

/// The single source of truth for live market prices.
///
/// Uses a [Timer.periodic] to emit random-walk ticks for one randomly selected
/// stock per interval. All screens derive from this provider via
/// `.select((m) => m[symbol])` to ensure cell-level granularity rebuilds.
class MarketFeedNotifier extends StateNotifier<Map<String, PriceTick>> {
  MarketFeedNotifier() : super(const {}) {
    _init();
  }

  final _rng = Random();
  Timer? _timer;

  /// Stores each stock's day-open price (set once on startup, never changes).
  final Map<String, double> _openPrices = {};

  void _init() {
    final now = DateTime.now();
    final initial = <String, PriceTick>{};

    for (final stock in kStocks) {
      _openPrices[stock.symbol] = stock.startingPrice;
      initial[stock.symbol] = PriceTick(
        symbol: stock.symbol,
        price: stock.startingPrice,
        prevPrice: stock.startingPrice,
        openPrice: stock.startingPrice,
        change: 0.0,
        changePercent: 0.0,
        timestamp: now,
      );
    }

    state = initial;
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(
      Duration(milliseconds: kTickIntervalMs),
      (_) => _tick(),
    );
  }

  void _tick() {
    // Pick one stock at random per tick.
    final symbol = kAllSymbols[_rng.nextInt(kAllSymbols.length)];
    final current = state[symbol];
    if (current == null) return;

    // Brownian-motion random walk: ±0.5% max per tick.
    final factor = 1.0 + (_rng.nextDouble() - 0.5) * 0.01;
    final rawNew = current.price * factor;

    // Safety clamp so price doesn't drift too far from open (±30%).
    final open = _openPrices[symbol]!;
    final clamped = rawNew.clamp(open * 0.70, open * 1.30);

    // Round to 2 decimal places — this is the stored/displayed value.
    final newPrice = double.parse(clamped.toStringAsFixed(2));

    final change =
        double.parse((newPrice - open).toStringAsFixed(2));
    final changePercent =
        double.parse(((change / open) * 100).toStringAsFixed(2));

    // Spread operator copy avoids a full map rebuild; only the affected entry
    // reference changes so `.select()` subscribers for other symbols don't rebuild.
    state = {
      ...state,
      symbol: PriceTick(
        symbol: symbol,
        price: newPrice,
        prevPrice: current.price,
        openPrice: open,
        change: change,
        changePercent: changePercent,
        timestamp: DateTime.now(),
      ),
    };
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

/// Provides the live map of symbol → latest [PriceTick].
///
/// Usage in widgets:
/// ```dart
/// // Watch a single symbol (no cross-symbol rebuilds):
/// final tick = ref.watch(marketFeedProvider.select((m) => m['RELIANCE']));
/// ```
final marketFeedProvider =
    StateNotifierProvider<MarketFeedNotifier, Map<String, PriceTick>>(
  (ref) => MarketFeedNotifier(),
);
