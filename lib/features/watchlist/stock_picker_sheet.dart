import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../core/constants/stocks.dart';
import '../../core/utils/currency_utils.dart';
import '../../providers/market_feed_provider.dart';
import '../../providers/watchlist_provider.dart';

/// A bottom sheet that lists all 10 stocks and lets the user add any
/// not already in the target watchlist.
class StockPickerSheet extends ConsumerWidget {
  final String watchlistId;

  const StockPickerSheet({super.key, required this.watchlistId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final watchlist = ref.watch(
      watchlistProvider.select((list) {
        for (final w in list) {
          if (w.id == watchlistId) return w;
        }
        return null;
      }),
    );

    // If the watchlist was deleted while this sheet was open, close it.
    if (watchlist == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) Navigator.of(context).pop();
      });
      return const SizedBox.shrink();
    }

    final already = watchlist.symbols.toSet();

    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (ctx, scrollCtrl) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // ── Handle ─────────────────────────────────────────────
              const SizedBox(height: 10),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              // ── Title ──────────────────────────────────────────────
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Text(
                      'Add Stocks',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Spacer(),
                    Text(
                      '10 available',
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              // ── Stock list ─────────────────────────────────────────
              Expanded(
                child: ListView.separated(
                  controller: scrollCtrl,
                  itemCount: kStocks.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, indent: 70),
                  itemBuilder: (_, i) {
                    final stock = kStocks[i];
                    final added = already.contains(stock.symbol);
                    return _StockPickerRow(
                      stock: stock,
                      isAdded: added,
                      onAdd: added
                          ? null
                          : () {
                              ref
                                  .read(watchlistProvider.notifier)
                                  .addStock(watchlistId, stock.symbol);
                            },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StockPickerRow extends ConsumerWidget {
  final StockInfo stock;
  final bool isAdded;
  final VoidCallback? onAdd;

  const _StockPickerRow({
    required this.stock,
    required this.isAdded,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tick = ref.watch(
        marketFeedProvider.select((m) => m[stock.symbol]));
    final price = tick?.price ?? stock.startingPrice;
    final pct = tick?.changePercent ?? 0.0;
    final isPos = pct >= 0;
    final changeColor = isPos ? AppColors.green : AppColors.red;

    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: _MiniAvatar(symbol: stock.symbol),
      title: Text(
        stock.symbol,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
          fontSize: 14,
        ),
      ),
      subtitle: Text(
        stock.name,
        style: const TextStyle(
            color: AppColors.textSecondary, fontSize: 12),
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                CurrencyUtils.formatPrice(price),
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              Text(
                CurrencyUtils.formatChangePercent(pct),
                style: TextStyle(
                    color: changeColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(width: 12),
          isAdded
              ? Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.green.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Added',
                    style: TextStyle(
                      color: AppColors.green,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
              : ElevatedButton(
                  onPressed: onAdd,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    textStyle: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  child: const Text('Add'),
                ),
        ],
      ),
    );
  }
}

class _MiniAvatar extends StatelessWidget {
  final String symbol;
  const _MiniAvatar({required this.symbol});

  static const _palette = [
    Color(0xFF3D7EFF), Color(0xFF00D68F), Color(0xFFFF6B6B),
    Color(0xFFFFB347), Color(0xFF9C27B0), Color(0xFF00BCD4),
    Color(0xFFFF5722), Color(0xFF4CAF50), Color(0xFFE91E63),
    Color(0xFF795548),
  ];
  Color get _color => _palette[symbol.codeUnitAt(0) % _palette.length];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: _color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _color.withOpacity(0.35)),
      ),
      alignment: Alignment.center,
      child: Text(
        symbol.length >= 2 ? symbol.substring(0, 2) : symbol,
        style: TextStyle(
            color: _color,
            fontWeight: FontWeight.w800,
            fontSize: 12),
      ),
    );
  }
}
