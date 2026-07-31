import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/stocks.dart';
import '../data/services/persistence_service.dart';

/// Manages the user's simulated cash balance.
class WalletNotifier extends StateNotifier<double> {
  final PersistenceService _persistence;

  WalletNotifier(this._persistence) : super(kInitialWalletBalance) {
    _load();
  }

  void _load() {
    state = _persistence.loadWallet(kInitialWalletBalance);
  }

  void _save() {
    _persistence.saveWallet(state);
  }

  /// Returns true if the current balance is >= [amount].
  bool canAfford(double amount) => state >= amount;

  /// Deducts [amount] from the balance (Buy order side-effect).
  void deduct(double amount) {
    state = double.parse((state - amount).toStringAsFixed(2));
    _save();
  }

  /// Credits [amount] to the balance (Sell order side-effect).
  void credit(double amount) {
    state = double.parse((state + amount).toStringAsFixed(2));
    _save();
  }
}

final walletProvider = StateNotifierProvider<WalletNotifier, double>(
  (ref) => WalletNotifier(ref.watch(persistenceServiceProvider)),
);
