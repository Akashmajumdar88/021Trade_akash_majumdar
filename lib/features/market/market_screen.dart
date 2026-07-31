import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../core/constants/stocks.dart';
import '../../core/utils/currency_utils.dart';
import '../../providers/market_feed_provider.dart';
import '../../widgets/price_flash_tile.dart';

class MarketScreen extends ConsumerWidget {
  const MarketScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── App bar ──────────────────────────────────────────────────
          SliverAppBar(
            pinned: true,
            backgroundColor: AppColors.surface,
            expandedHeight: 110,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding:
                  const EdgeInsets.only(left: 16, bottom: 52),
              title: _AppBarTitle(),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(38),
              child: _MarketSummaryBar(),
            ),
          ),
          // ── Section header ───────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding:
                  const EdgeInsets.fromLTRB(16, 20, 16, 8),
              child: Row(
                children: [
                  const Text(
                    'Market Overview',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  const Spacer(),
                  _LiveBadge(),
                ],
              ),
            ),
          ),
          // ── Stock list ───────────────────────────────────────────────
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
                  itemCount: kStocks.length,
                  separatorBuilder: (_, __) => const Divider(
                    height: 1,
                    indent: 70,
                    endIndent: 0,
                  ),
                  itemBuilder: (ctx, i) {
                    final stock = kStocks[i];
                    return PriceFlashTile(
                      key: ValueKey(stock.symbol),
                      symbol: stock.symbol,
                      subtitle: stock.name,
                      onTap: () => context
                          .push('/trade?symbol=${stock.symbol}'),
                    );
                  },
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

class _AppBarTitle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.accent, Color(0xFF00B4D8)],
            ),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Text(
            '021',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 13,
              letterSpacing: 1,
            ),
          ),
        ),
        const SizedBox(width: 8),
        const Text(
          'Trade',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
      ],
    );
  }
}

class _LiveBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
            color: AppColors.green.withOpacity(0.35), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _PulseDot(),
          const SizedBox(width: 5),
          const Text(
            'LIVE',
            style: TextStyle(
              color: AppColors.green,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _PulseDot extends StatefulWidget {
  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Container(
        width: 7,
        height: 7,
        decoration: BoxDecoration(
          color: AppColors.green
              .withOpacity(0.5 + _ctrl.value * 0.5),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

/// Advancers / decliners summary bar below the app bar.
class _MarketSummaryBar extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prices = ref.watch(marketFeedProvider);
    int adv = 0, dec = 0;
    double totalPct = 0;
    for (final t in prices.values) {
      if (t.changePercent > 0) adv++;
      if (t.changePercent < 0) dec++;
      totalPct += t.changePercent;
    }
    final avgPct = prices.isNotEmpty ? totalPct / prices.length : 0.0;

    return Container(
      height: 38,
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Icon(Icons.trending_up_rounded,
              color: AppColors.green, size: 13),
          const SizedBox(width: 4),
          Text('$adv Adv',
              style: const TextStyle(
                  color: AppColors.green,
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
          const SizedBox(width: 14),
          Icon(Icons.trending_down_rounded,
              color: AppColors.red, size: 13),
          const SizedBox(width: 4),
          Text('$dec Dec',
              style: const TextStyle(
                  color: AppColors.red,
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
          const Spacer(),
          Text(
            'Avg ${CurrencyUtils.formatChangePercent(avgPct)}  ·  ${kTickIntervalMs}ms/tick',
            style: const TextStyle(
                color: AppColors.textMuted, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
