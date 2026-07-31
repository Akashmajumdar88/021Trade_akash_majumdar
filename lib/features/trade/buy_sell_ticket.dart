import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../core/constants/stocks.dart';
import '../../core/utils/currency_utils.dart';
import '../../data/models/order.dart';
import '../../providers/holdings_provider.dart';
import '../../providers/market_feed_provider.dart';
import '../../providers/order_history_provider.dart';
import '../../providers/wallet_provider.dart';

class BuySellTicketScreen extends ConsumerStatefulWidget {
  final String symbol;
  final OrderSide initialSide;

  const BuySellTicketScreen({
    super.key,
    required this.symbol,
    this.initialSide = OrderSide.buy,
  });

  @override
  ConsumerState<BuySellTicketScreen> createState() =>
      _BuySellTicketScreenState();
}

class _BuySellTicketScreenState
    extends ConsumerState<BuySellTicketScreen> {
  late OrderSide _side;
  final _qtyCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String? _error;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _side = widget.initialSide;
  }

  @override
  void dispose() {
    _qtyCtrl.dispose();
    super.dispose();
  }

  // ─── Computed helpers ────────────────────────────────────────────────────

  int? get _parsedQty {
    final v = int.tryParse(_qtyCtrl.text.trim());
    return (v != null && v > 0) ? v : null;
  }

  double _orderValue(double price) =>
      double.parse((_parsedQty! * price).toStringAsFixed(2));

  // ─── Submission ──────────────────────────────────────────────────────────

  void _submit() {
    setState(() => _error = null);
    if (!(_formKey.currentState?.validate() ?? false)) return;

    // Capture LTP at submit time (not form-open time).
    final ltp = ref.read(marketFeedProvider)[widget.symbol]?.price;
    if (ltp == null) {
      setState(() => _error = 'Price data unavailable. Try again.');
      return;
    }

    final qty = _parsedQty!;
    final total = _orderValue(ltp);

    if (_side == OrderSide.buy) {
      final balance = ref.read(walletProvider);
      if (total > balance) {
        setState(() => _error =
            'Insufficient balance. Need ₹${total.toStringAsFixed(2)}, have ₹${balance.toStringAsFixed(2)}.');
        return;
      }
      setState(() => _loading = true);
      ref.read(walletProvider.notifier).deduct(total);
      ref.read(holdingsProvider.notifier).buy(widget.symbol, qty, ltp);
    } else {
      final holding =
          ref.read(holdingsProvider.notifier).getHolding(widget.symbol);
      if (holding == null || holding.quantity < qty) {
        setState(() => _error =
            'Insufficient holdings. You hold ${holding?.quantity ?? 0} shares.');
        return;
      }
      setState(() => _loading = true);
      ref.read(holdingsProvider.notifier).sell(widget.symbol, qty);
      ref.read(walletProvider.notifier).credit(total);
    }

    final order = Order.create(
      symbol: widget.symbol,
      side: _side,
      quantity: qty,
      price: ltp,
    );
    ref.read(orderHistoryProvider.notifier).addOrder(order);

    // Navigate to confirmation, replacing this screen.
    context.pushReplacement('/order-confirmation', extra: order);
  }

  // ─── Build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isBuy = _side == OrderSide.buy;
    final sideColor = isBuy ? AppColors.green : AppColors.red;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          kStockMap[widget.symbol]?.name ?? widget.symbol,
          style: const TextStyle(fontSize: 16),
        ),
        leading: BackButton(
            onPressed: () =>
                context.canPop() ? context.pop() : context.go('/market')),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Stock summary card ───────────────────────────────────
              _StockCard(symbol: widget.symbol),
              const SizedBox(height: 24),

              // ── Buy / Sell toggle ────────────────────────────────────
              _SideToggle(
                side: _side,
                onChanged: (s) => setState(() {
                  _side = s;
                  _error = null;
                }),
              ),
              const SizedBox(height: 20),

              // ── Quantity input ───────────────────────────────────────
              _QuantityField(
                controller: _qtyCtrl,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),

              // ── Order summary card ───────────────────────────────────
              _OrderSummaryCard(
                symbol: widget.symbol,
                side: _side,
                parsedQty: _parsedQty,
              ),
              const SizedBox(height: 16),

              // ── Balance info ─────────────────────────────────────────
              _BalanceRow(side: _side, symbol: widget.symbol),
              const SizedBox(height: 20),

              // ── Inline error ─────────────────────────────────────────
              if (_error != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: AppColors.red.withOpacity(0.4)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded,
                          color: AppColors.red, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _error!,
                          style: const TextStyle(
                              color: AppColors.red, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // ── Submit button ────────────────────────────────────────
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: sideColor,
                  ),
                  child: _loading
                      ? const CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        )
                      : Text(
                          isBuy ? 'Place Buy Order' : 'Place Sell Order',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Subwidgets ───────────────────────────────────────────────────────────────

class _StockCard extends ConsumerWidget {
  final String symbol;
  const _StockCard({required this.symbol});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tick = ref.watch(marketFeedProvider.select((m) => m[symbol]));
    final price = tick?.price ?? 0;
    final change = tick?.change ?? 0;
    final pct = tick?.changePercent ?? 0;
    final isPos = pct >= 0;
    final cc = isPos ? AppColors.green : AppColors.red;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          _SymbolBadge(symbol: symbol),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(symbol,
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 16)),
                Text(kStockMap[symbol]?.name ?? '',
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(CurrencyUtils.formatPrice(price),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                    fontFeatures: [FontFeature.tabularFigures()],
                  )),
              Row(
                children: [
                  Icon(
                      isPos
                          ? Icons.arrow_drop_up_rounded
                          : Icons.arrow_drop_down_rounded,
                      color: cc,
                      size: 18),
                  Text(
                    '${CurrencyUtils.formatChange(change)} (${CurrencyUtils.formatChangePercent(pct)})',
                    style: TextStyle(
                        color: cc,
                        fontSize: 12,
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SideToggle extends StatelessWidget {
  final OrderSide side;
  final ValueChanged<OrderSide> onChanged;
  const _SideToggle({required this.side, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          _SideButton(
            label: 'Buy',
            icon: Icons.arrow_upward_rounded,
            isSelected: side == OrderSide.buy,
            color: AppColors.green,
            onTap: () => onChanged(OrderSide.buy),
          ),
          _SideButton(
            label: 'Sell',
            icon: Icons.arrow_downward_rounded,
            isSelected: side == OrderSide.sell,
            color: AppColors.red,
            onTap: () => onChanged(OrderSide.sell),
          ),
        ],
      ),
    );
  }
}

class _SideButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _SideButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            border: Border.all(
                color: isSelected ? color.withOpacity(0.5) : Colors.transparent,
                width: 1.5),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  color: isSelected ? color : AppColors.textSecondary,
                  size: 18),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? color : AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuantityField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _QuantityField(
      {required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      onChanged: onChanged,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 22,
          fontWeight: FontWeight.w700),
      decoration: const InputDecoration(
        labelText: 'Quantity (shares)',
        prefixIcon: Icon(Icons.numbers_rounded,
            color: AppColors.textSecondary),
      ),
      validator: (v) {
        if (v == null || v.isEmpty) return 'Please enter a quantity';
        final n = int.tryParse(v);
        if (n == null || n <= 0) return 'Quantity must be a positive integer';
        return null;
      },
    );
  }
}

class _OrderSummaryCard extends ConsumerWidget {
  final String symbol;
  final OrderSide side;
  final int? parsedQty;

  const _OrderSummaryCard({
    required this.symbol,
    required this.side,
    required this.parsedQty,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tick = ref.watch(marketFeedProvider.select((m) => m[symbol]));
    final ltp = tick?.price ?? 0;
    final qty = parsedQty ?? 0;
    final orderValue =
        qty > 0 ? double.parse((qty * ltp).toStringAsFixed(2)) : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          _InfoRow(label: 'Order Type', value: 'Market Order'),
          _InfoRow(
              label: 'LTP',
              value: CurrencyUtils.formatPrice(ltp),
              valueStyle: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 15,
                fontFeatures: [FontFeature.tabularFigures()],
              )),
          _InfoRow(label: 'Quantity', value: qty > 0 ? qty.toString() : '—'),
          const Divider(height: 20),
          _InfoRow(
            label: 'Estimated Value',
            value: qty > 0
                ? CurrencyUtils.formatPrice(orderValue)
                : '—',
            valueStyle: TextStyle(
              color: side == OrderSide.buy
                  ? AppColors.green
                  : AppColors.red,
              fontWeight: FontWeight.w700,
              fontSize: 16,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _BalanceRow extends ConsumerWidget {
  final OrderSide side;
  final String symbol;
  const _BalanceRow({required this.side, required this.symbol});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balance = ref.watch(walletProvider);
    if (side == OrderSide.buy) {
      return Row(
        children: [
          const Icon(Icons.account_balance_wallet_outlined,
              color: AppColors.textSecondary, size: 16),
          const SizedBox(width: 6),
          const Text('Available balance: ',
              style: TextStyle(
                  color: AppColors.textSecondary, fontSize: 13)),
          Text(
            CurrencyUtils.formatINR(balance),
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      );
    } else {
      final holding =
          ref.watch(holdingsProvider.select((list) {
        for (final h in list) {
          if (h.symbol == symbol) return h;
        }
        return null;
      }));
      return Row(
        children: [
          const Icon(Icons.inventory_2_outlined,
              color: AppColors.textSecondary, size: 16),
          const SizedBox(width: 6),
          const Text('Held: ',
              style: TextStyle(
                  color: AppColors.textSecondary, fontSize: 13)),
          Text(
            holding != null
                ? '${holding.quantity} shares'
                : 'Not held',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      );
    }
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final TextStyle? valueStyle;

  const _InfoRow(
      {required this.label, required this.value, this.valueStyle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 13)),
          Text(
            value,
            style: valueStyle ??
                const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
          ),
        ],
      ),
    );
  }
}

class _SymbolBadge extends StatelessWidget {
  final String symbol;
  const _SymbolBadge({required this.symbol});

  static const _palette = [
    Color(0xFF3D7EFF), Color(0xFF00D68F), Color(0xFFFF6B6B),
    Color(0xFFFFB347), Color(0xFF9C27B0), Color(0xFF00BCD4),
    Color(0xFFFF5722), Color(0xFF4CAF50), Color(0xFFE91E63),
    Color(0xFF795548),
  ];
  Color get _c => _palette[symbol.codeUnitAt(0) % _palette.length];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: _c.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _c.withOpacity(0.35)),
      ),
      alignment: Alignment.center,
      child: Text(
        symbol.substring(0, symbol.length >= 2 ? 2 : 1),
        style: TextStyle(
            color: _c, fontWeight: FontWeight.w800, fontSize: 15),
      ),
    );
  }
}
