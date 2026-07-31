import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/models/order.dart';
import '../features/holdings/holdings_screen.dart';
import '../features/market/market_screen.dart';
import '../features/trade/buy_sell_ticket.dart';
import '../features/trade/order_confirmation_screen.dart';
import '../features/watchlist/watchlist_screen.dart';
import 'theme.dart';

class AppRouter {
  AppRouter._();

  static final router = GoRouter(
    initialLocation: '/market',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => _AppShell(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/market',
                builder: (ctx, state) => const MarketScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/watchlist',
                builder: (ctx, state) => const WatchlistScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/holdings',
                builder: (ctx, state) => const HoldingsScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/trade',
        builder: (ctx, state) {
          final params = state.uri.queryParameters;
          final symbol = params['symbol'] ?? 'RELIANCE';
          final sideStr = params['side'];
          final side = sideStr == 'sell' ? OrderSide.sell : OrderSide.buy;
          return BuySellTicketScreen(symbol: symbol, initialSide: side);
        },
      ),
      GoRoute(
        path: '/order-confirmation',
        builder: (ctx, state) {
          final order = state.extra as Order;
          return OrderConfirmationScreen(order: order);
        },
      ),
    ],
  );
}

class _AppShell extends StatelessWidget {
  final StatefulNavigationShell shell;
  const _AppShell({required this.shell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: shell,
      bottomNavigationBar: _BottomNav(
        currentIndex: shell.currentIndex,
        onTap: (i) => shell.goBranch(
          i,
          initialLocation: i == shell.currentIndex,
        ),
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  const _BottomNav({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.divider, width: 1)),
      ),
      child: NavigationBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        selectedIndex: currentIndex,
        onDestinationSelected: onTap,
        indicatorColor: AppColors.accent.withOpacity(0.15),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.candlestick_chart_outlined),
            selectedIcon: Icon(Icons.candlestick_chart),
            label: 'Market',
          ),
          NavigationDestination(
            icon: Icon(Icons.bookmark_border_rounded),
            selectedIcon: Icon(Icons.bookmark_rounded),
            label: 'Watchlist',
          ),
          NavigationDestination(
            icon: Icon(Icons.pie_chart_outline_rounded),
            selectedIcon: Icon(Icons.pie_chart_rounded),
            label: 'Holdings',
          ),
        ],
      ),
    );
  }
}
