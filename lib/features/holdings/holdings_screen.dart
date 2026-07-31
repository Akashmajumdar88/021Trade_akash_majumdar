import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../core/utils/currency_utils.dart';
import '../../data/models/holding.dart';
import '../../providers/holdings_provider.dart';
import '../../providers/market_feed_provider.dart';
import '../../providers/wallet_provider.dart';


class HoldingsScreen extends ConsumerWidget {
  const HoldingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sorted = ref.watch(sortedHoldingsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Holdings'),
        actions: [
          _SortMenu(),
        ],
      ),
      body: sorted.isEmpty
          ? const _EmptyHoldings()
          : CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // ── Aggregate summary ────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
                    child: _AggregateSummaryCard(),
                  ),
                ),
                // ── Sort label ───────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: Row(
                      children: [
                        Text(
                          '${sorted.length} holding${sorted.length == 1 ? '' : 's'}',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        _SortLabel(),
                      ],
                    ),
                  ),
                ),
                // ── Holdings list ────────────────────────────────────
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  sliver: SliverToBoxAdapter(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: sorted.length,
                        separatorBuilder: (_, __) =>
                            const Divider(height: 1, indent: 70),
                        itemBuilder: (ctx, i) => _HoldingRow(
                          key: ValueKey(sorted[i].symbol),
                          holding: sorted[i],
                          onTap: () => context.push(
                              '/trade?symbol=${sorted[i].symbol}&side=sell'),
                        ),
                      ),
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 32)),
              ],
            ),
    );
  }
}

// ─── Aggregate summary ────────────────────────────────────────────────────────

class _AggregateSummaryCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final holdings = ref.watch(holdingsProvider);
    final balance = ref.watch(walletProvider);

    double totalInvested = 0;
    double totalCurrent = 0;

    for (final h in holdings) {
      final ltp = ref.watch(
            marketFeedProvider.select((m) => m[h.symbol]?.price),
          ) ??
          h.avgCost;
      totalInvested += h.investedValue();
      totalCurrent += h.currentValue(ltp);
    }

    final totalPnl = totalCurrent - totalInvested;
    final totalPnlPct =
        totalInvested > 0 ? (totalPnl / totalInvested) * 100 : 0.0;
    final isPos = totalPnl >= 0;
    final pnlColor = isPos ? AppColors.green : AppColors.red;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.card,
            AppColors.card.withBlue(45),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.pie_chart_rounded,
                  color: AppColors.textSecondary, size: 16),
              SizedBox(width: 6),
              Text('Portfolio Summary',
                  style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5)),
            ],
          ),
          const SizedBox(height: 14),
          // Total P&L — prominent display
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                CurrencyUtils.formatPnl(totalPnl),
                style: TextStyle(
                  color: pnlColor,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: pnlColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    CurrencyUtils.formatPnlPercent(totalPnlPct),
                    style: TextStyle(
                      color: pnlColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text('Total P&L',
              style: TextStyle(
                  color: AppColors.textSecondary, fontSize: 12)),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _StatCell(
                  label: 'Invested',
                  value: CurrencyUtils.formatINR(totalInvested),
                ),
              ),
              Container(
                  width: 1,
                  height: 32,
                  color: AppColors.divider),
              Expanded(
                child: _StatCell(
                  label: 'Current Value',
                  value: CurrencyUtils.formatINR(totalCurrent),
                  valueColor: isPos ? AppColors.green : AppColors.red,
                ),
              ),
              Container(
                  width: 1,
                  height: 32,
                  color: AppColors.divider),
              Expanded(
                child: _StatCell(
                  label: 'Available Cash',
                  value: CurrencyUtils.formatINR(balance),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _StatCell(
      {required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            value,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: valueColor ?? AppColors.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 13,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 3),
          Text(label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 11)),
        ],
      ),
    );
  }
}

// ─── Individual holding row ───────────────────────────────────────────────────

class _HoldingRow extends ConsumerWidget {
  final Holding holding;
  final VoidCallback onTap;

  const _HoldingRow({super.key, required this.holding, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ltp = ref.watch(
          marketFeedProvider.select((m) => m[holding.symbol]?.price),
        ) ??
        holding.avgCost;

    final pnl = holding.pnl(ltp);
    final pnlPct = holding.pnlPercent(ltp);
    final isPos = pnl >= 0;
    final pnlColor = isPos ? AppColors.green : AppColors.red;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Avatar
            _HoldingAvatar(symbol: holding.symbol, isPos: isPos),
            const SizedBox(width: 12),
            // Symbol + qty + avg cost
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    holding.symbol,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${holding.quantity} shares · avg ₹${holding.avgCost.toStringAsFixed(2)}',
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ),
            // LTP + P&L
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  CurrencyUtils.formatPrice(ltp),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(height: 3),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: pnlColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${CurrencyUtils.formatPnl(pnl)}  ${CurrencyUtils.formatPnlPercent(pnlPct)}',
                    style: TextStyle(
                      color: pnlColor,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HoldingAvatar extends StatelessWidget {
  final String symbol;
  final bool isPos;
  const _HoldingAvatar({required this.symbol, required this.isPos});

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
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: _c.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _c.withOpacity(0.35)),
      ),
      child: Stack(
        children: [
          Center(
            child: Text(
              symbol.length >= 2 ? symbol.substring(0, 2) : symbol,
              style: TextStyle(
                  color: _c,
                  fontWeight: FontWeight.w800,
                  fontSize: 13),
            ),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: isPos ? AppColors.green : AppColors.red,
                shape: BoxShape.circle,
                border: Border.all(
                    color: AppColors.card, width: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Sort controls ────────────────────────────────────────────────────────────

class _SortMenu extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(holdingsSortProvider);
    return PopupMenuButton<HoldingsSortOrder>(
      icon: const Icon(Icons.sort_rounded, color: AppColors.textSecondary),
      color: AppColors.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      tooltip: 'Sort by',
      initialValue: current,
      onSelected: (v) => ref.read(holdingsSortProvider.notifier).state = v,
      itemBuilder: (_) => [
        _sortItem(HoldingsSortOrder.pnlDesc, 'P&L (High → Low)', current),
        _sortItem(HoldingsSortOrder.valueDesc, 'Value (High → Low)', current),
        _sortItem(HoldingsSortOrder.symbolAsc, 'Symbol (A → Z)', current),
      ],
    );
  }

  PopupMenuItem<HoldingsSortOrder> _sortItem(
      HoldingsSortOrder val, String label, HoldingsSortOrder current) {
    final isSelected = val == current;
    return PopupMenuItem(
      value: val,
      child: Row(
        children: [
          Icon(
            isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
            color: isSelected ? AppColors.accent : AppColors.textMuted,
            size: 18,
          ),
          const SizedBox(width: 10),
          Text(label,
              style: TextStyle(
                  color: isSelected
                      ? AppColors.textPrimary
                      : AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _SortLabel extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sort = ref.watch(holdingsSortProvider);
    final label = switch (sort) {
      HoldingsSortOrder.pnlDesc => 'P&L ↓',
      HoldingsSortOrder.valueDesc => 'Value ↓',
      HoldingsSortOrder.symbolAsc => 'Symbol ↑',
    };
    return Text(
      'Sorted: $label',
      style: const TextStyle(
          color: AppColors.textMuted, fontSize: 12),
    );
  }
}

// ─── Empty state ──────────────────────────────────────────────────────────────

class _EmptyHoldings extends StatelessWidget {
  const _EmptyHoldings();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: AppColors.card,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.pie_chart_outline_rounded,
                  size: 36, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            const Text(
              'No Holdings Yet',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Place a Buy order from the Market\nor Watchlist tab to get started.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  height: 1.5),
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: () => GoRouter.of(context).go('/market'),
              icon: const Icon(Icons.candlestick_chart, size: 18),
              label: const Text('Go to Market'),
            ),
          ],
        ),
      ),
    );
  }
}
