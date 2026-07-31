# 021 Trading App — Flutter Assignment

A fully-featured simulated NSE equity trading app built with **Flutter + Riverpod**.

---

## Quick Start

```bash
git clone <repo-url>
cd tradeakashmajumdar
flutter pub get
flutter run
```

No backend, no code generation step, no extra config. Just `flutter pub get && flutter run`.

---

## Stack

| Layer | Choice |
|---|---|
| Framework | Flutter (stable channel) |
| State | `flutter_riverpod` v2 — `StateNotifier` + `Provider` |
| Navigation | `go_router` v14 — `StatefulShellRoute` for tabs |
| Persistence | `shared_preferences` — JSON per entity |
| Fonts | Google Fonts — Inter |

---

## Features

### 1. Watchlist
- Create, rename, and delete multiple watchlists
- Add stocks via a bottom-sheet picker (shows live prices)
- Drag-to-reorder with `ReorderableListView` (price binding follows the row via `ValueKey(symbol)`)
- Swipe / tap the delete icon to remove a stock
- Live prices update in-place; tapping a row opens the Buy/Sell ticket

### 2. Live Prices (Market Feed)
- All 10 NSE stocks shown with LTP, day change, and day % change
- Green / red flash animation on every price tick (per-cell, no cross-cell rebuilds)
- Mock feed: `Timer.periodic` random-walk ±0.5% per tick, one stock per tick
- Tick rate controlled by `kTickIntervalMs` in `lib/core/constants/stocks.dart`
  - Default: **200 ms** (5 ticks/sec overall)
  - Stress test: **20 ms** (50 ticks/sec overall)
- Single source of truth: `marketFeedProvider` (StateNotifier)

### 3. Buy / Sell Ticket
- Pre-filled from watchlist or holdings row (symbol + side)
- Live LTP on the form updates in real time
- Execution price captured at **submit time** (not form-open time)
- Buy: validates wallet balance ≥ qty × LTP
- Sell: validates held quantity ≥ qty
- Fractional / zero / negative quantities blocked by validator
- Inline error message below form
- On success: wallet deducted / credited, holdings updated, order recorded, confirmation screen shown

### 4. Holdings
- Lists all current positions with symbol, qty, avg cost, LTP, current value, P&L (₹ and %)
- Live P&L updates as prices tick
- Sortable: P&L descending (default), Current Value descending, Symbol A→Z
- Aggregate summary at top: total invested, current value, total P&L, available cash
- Tapping a row opens the Sell ticket pre-filled for that stock
- Empty state with navigation to Market

---

## Architecture

```
lib/
├── main.dart                    # ProviderScope + SharedPrefs override
├── app/
│   ├── app.dart                 # MaterialApp.router
│   ├── router.dart              # GoRouter + StatefulShellRoute (3 tabs)
│   └── theme.dart               # Dark trading theme (AppColors + AppTheme)
├── core/
│   ├── constants/stocks.dart    # 10 stocks, kTickIntervalMs, kInitialWalletBalance
│   └── utils/currency_utils.dart
├── data/
│   ├── models/                  # price_tick, watchlist, holding, order
│   └── services/persistence_service.dart
├── providers/
│   ├── market_feed_provider.dart   # Timer-based random-walk feed
│   ├── watchlist_provider.dart
│   ├── holdings_provider.dart      # + sortedHoldingsProvider
│   ├── wallet_provider.dart
│   └── order_history_provider.dart
├── features/
│   ├── market/market_screen.dart
│   ├── watchlist/{screen, detail, picker}
│   ├── trade/{ticket, confirmation}
│   └── holdings/holdings_screen.dart
└── widgets/price_flash_tile.dart   # Reusable animated price row
```

---

## Performance Notes

- **Cell-level granularity**: every widget uses `ref.watch(marketFeedProvider.select((m) => m[symbol]))` — only the affected cell rebuilds on a tick.
- **Flash animation**: `AnimationController` + `ref.listen` — no setState on every tick unless this cell's symbol changed.
- **sortedHoldingsProvider**: watches only held-symbol prices (loop of `.select` calls), so it only rebuilds when a held stock ticks or the sort order changes.
- State updates use the spread-operator copy `{ ...state, symbol: newTick }` so Riverpod can detect only the changed entry.

---

## Configuring Tick Rate

Open `lib/core/constants/stocks.dart` and change:

```dart
const int kTickIntervalMs = 200; // default: 5 ticks/sec overall
// → set to 20 for 50+ ticks/sec stress test
```

---

## Starting Prices

| Symbol | Name | Price (₹) |
|---|---|---|
| RELIANCE | Reliance Industries | 2,850.75 |
| TCS | Tata Consultancy Services | 4,125.50 |
| INFY | Infosys Ltd. | 1,890.25 |
| HDFCBANK | HDFC Bank Ltd. | 1,720.60 |
| ICICIBANK | ICICI Bank Ltd. | 1,285.30 |
| SBIN | State Bank of India | 892.45 |
| ITC | ITC Ltd. | 478.90 |
| LT | Larsen & Toubro Ltd. | 3,650.15 |
| BHARTIARTL | Bharti Airtel Ltd. | 1,920.80 |
| AXISBANK | Axis Bank Ltd. | 1,175.35 |

Initial wallet: **₹10,00,000**
