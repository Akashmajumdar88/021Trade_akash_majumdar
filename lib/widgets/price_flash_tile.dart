import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/theme.dart';
import '../core/constants/stocks.dart';
import '../core/utils/currency_utils.dart';
import '../data/models/price_tick.dart';
import '../providers/market_feed_provider.dart';

/// A live price row that briefly flashes green (up) or red (down)
/// whenever the price for [symbol] changes.
///
/// Uses [ref.listen] + [AnimationController] for the flash — avoids
/// rebuilding the entire widget on every tick that doesn't affect this symbol.
class PriceFlashTile extends ConsumerStatefulWidget {
  final String symbol;

  /// Optional subtitle (e.g. full stock name).
  final String? subtitle;

  final VoidCallback? onTap;

  /// Optional trailing widget (e.g. delete button in watchlists).
  final Widget? trailing;

  const PriceFlashTile({
    super.key,
    required this.symbol,
    this.subtitle,
    this.onTap,
    this.trailing,
  });

  @override
  ConsumerState<PriceFlashTile> createState() => _PriceFlashTileState();
}

class _PriceFlashTileState extends ConsumerState<PriceFlashTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  Color _flashStart = Colors.transparent;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _ctrl.addListener(_onAnimTick);
  }

  @override
  void dispose() {
    _ctrl.removeListener(_onAnimTick);
    _ctrl.dispose();
    super.dispose();
  }

  void _onAnimTick() {
    // Only call setState when the widget is mounted and animation is running.
    if (mounted) setState(() {});
  }

  void _flash(bool isUp) {
    _flashStart = isUp
        ? AppColors.green.withOpacity(0.28)
        : AppColors.red.withOpacity(0.28);
    _ctrl.forward(from: 0);
  }

  Color get _currentFlashColor {
    if (_ctrl.value == 0) return Colors.transparent;
    // Lerp from _flashStart → transparent as animation progresses.
    return Color.lerp(
      _flashStart,
      Colors.transparent,
      Curves.easeOut.transform(_ctrl.value),
    )!;
  }

  @override
  Widget build(BuildContext context) {
    // Listen selectively — only fires when this symbol's price changes.
    ref.listen<PriceTick?>(
      marketFeedProvider.select((m) => m[widget.symbol]),
      (prev, next) {
        if (prev != null && next != null && prev.price != next.price) {
          _flash(next.price > prev.price);
        }
      },
    );

    final tick =
        ref.watch(marketFeedProvider.select((m) => m[widget.symbol]));

    if (tick == null) return const SizedBox.shrink();

    final isPositive = tick.changePercent >= 0;
    final changeColor = isPositive ? AppColors.green : AppColors.red;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onTap,
        splashColor: AppColors.accent.withOpacity(0.08),
        highlightColor: AppColors.accent.withOpacity(0.04),
        child: AnimatedContainer(
          duration: Duration.zero, // Driven by _ctrl, not AnimatedContainer.
          color: _currentFlashColor,
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                _SymbolAvatar(symbol: widget.symbol),
                const SizedBox(width: 12),
                // ── Symbol + name ────────────────────────────────────────
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.symbol,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          letterSpacing: 0.2,
                        ),
                      ),
                      if (widget.subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          widget.subtitle!,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11.5,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                // ── Price + change ───────────────────────────────────────
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      CurrencyUtils.formatPrice(tick.price),
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                    const SizedBox(height: 3),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: changeColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isPositive
                                ? Icons.arrow_drop_up_rounded
                                : Icons.arrow_drop_down_rounded,
                            color: changeColor,
                            size: 15,
                          ),
                          Text(
                            '${CurrencyUtils.formatChange(tick.change)}  '
                            '${CurrencyUtils.formatChangePercent(tick.changePercent)}',
                            style: TextStyle(
                              color: changeColor,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              fontFeatures: const [
                                FontFeature.tabularFigures()
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (widget.trailing != null) ...[
                  const SizedBox(width: 8),
                  widget.trailing!,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Coloured avatar that shows the first 2 characters of the symbol.
/// Colour is deterministically derived from the symbol string.
class _SymbolAvatar extends StatelessWidget {
  final String symbol;
  const _SymbolAvatar({required this.symbol});

  static const _palette = [
    Color(0xFF3D7EFF),
    Color(0xFF00D68F),
    Color(0xFFFF6B6B),
    Color(0xFFFFB347),
    Color(0xFF9C27B0),
    Color(0xFF00BCD4),
    Color(0xFFFF5722),
    Color(0xFF4CAF50),
    Color(0xFFE91E63),
    Color(0xFF795548),
  ];

  Color get _color =>
      _palette[symbol.codeUnitAt(0) % _palette.length];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: _color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _color.withOpacity(0.35), width: 1),
      ),
      alignment: Alignment.center,
      child: Text(
        symbol.length >= 2 ? symbol.substring(0, 2) : symbol,
        style: TextStyle(
          color: _color,
          fontWeight: FontWeight.w800,
          fontSize: 13,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

/// A convenient label that shows the symbol's stock name from [kStockMap].
String stockSubtitle(String symbol) =>
    kStockMap[symbol]?.name ?? symbol;
