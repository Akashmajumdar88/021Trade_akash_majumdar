import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../data/models/watchlist.dart';
import '../../providers/watchlist_provider.dart';
import '../../widgets/price_flash_tile.dart';
import 'stock_picker_sheet.dart';

/// Shows the stocks in a single [Watchlist] as a drag-reorderable list.
/// Each row is a live [PriceFlashTile] — price binding stays correct across
/// reorders because the [ValueKey] is the symbol, not the index.
class WatchlistDetailScreen extends ConsumerWidget {
  final Watchlist watchlist;
  final VoidCallback onRename;
  final VoidCallback onDelete;

  const WatchlistDetailScreen({
    super.key,
    required this.watchlist,
    required this.onRename,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the specific watchlist by id so we get live symbol updates.
    final currentWl = ref.watch(
      watchlistProvider.select((list) =>
          list.firstWhere((w) => w.id == watchlist.id,
              orElse: () => watchlist)),
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // ── Action bar ──────────────────────────────────────────────
          _ActionBar(
            watchlist: currentWl,
            onRename: onRename,
            onDelete: onDelete,
            onAddStock: () => _showStockPicker(context, currentWl),
          ),
          // ── Stock list ──────────────────────────────────────────────
          Expanded(
            child: currentWl.symbols.isEmpty
                ? _EmptyWatchlist(
                    onAdd: () => _showStockPicker(context, currentWl))
                : ReorderableListView.builder(
                    padding: const EdgeInsets.only(bottom: 24),
                    buildDefaultDragHandles: false,
                    itemCount: currentWl.symbols.length,
                    itemBuilder: (ctx, i) {
                      final symbol = currentWl.symbols[i];
                      return _WatchlistRow(
                        key: ValueKey(symbol),
                        symbol: symbol,
                        index: i,
                        watchlistId: currentWl.id,
                        onTap: () =>
                            context.push('/trade?symbol=$symbol'),
                      );
                    },
                    onReorder: (oldIdx, newIdx) {
                      ref
                          .read(watchlistProvider.notifier)
                          .reorderStocks(currentWl.id, oldIdx, newIdx);
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.small(
        heroTag: 'add_stock_${currentWl.id}',
        onPressed: () => _showStockPicker(context, currentWl),
        tooltip: 'Add Stock',
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  void _showStockPicker(BuildContext context, Watchlist wl) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StockPickerSheet(watchlistId: wl.id),
    );
  }
}

// ─── Action bar (rename / delete / stock count) ───────────────────────────────

class _ActionBar extends StatelessWidget {
  final Watchlist watchlist;
  final VoidCallback onRename;
  final VoidCallback onDelete;
  final VoidCallback onAddStock;

  const _ActionBar({
    required this.watchlist,
    required this.onRename,
    required this.onDelete,
    required this.onAddStock,
  });

  @override
  Widget build(BuildContext context) {
    final count = watchlist.symbols.length;
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
      child: Row(
        children: [
          Text(
            '$count ${count == 1 ? 'stock' : 'stocks'}',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          PopupMenuButton<_WatchlistAction>(
            icon: const Icon(Icons.more_vert_rounded,
                color: AppColors.textSecondary, size: 22),
            color: AppColors.card,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            onSelected: (action) {
              if (action == _WatchlistAction.rename) onRename();
              if (action == _WatchlistAction.delete) onDelete();
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: _WatchlistAction.rename,
                child: Row(
                  children: [
                    Icon(Icons.edit_rounded,
                        color: AppColors.textSecondary, size: 18),
                    SizedBox(width: 10),
                    Text('Rename',
                        style: TextStyle(color: AppColors.textPrimary)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: _WatchlistAction.delete,
                child: Row(
                  children: [
                    Icon(Icons.delete_outline_rounded,
                        color: AppColors.red, size: 18),
                    SizedBox(width: 10),
                    Text('Delete',
                        style: TextStyle(color: AppColors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

enum _WatchlistAction { rename, delete }

// ─── Individual row ───────────────────────────────────────────────────────────

class _WatchlistRow extends ConsumerWidget {
  final String symbol;
  final int index;
  final String watchlistId;
  final VoidCallback onTap;

  const _WatchlistRow({
    super.key,
    required this.symbol,
    required this.index,
    required this.watchlistId,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        PriceFlashTile(
          symbol: symbol,
          subtitle: stockSubtitle(symbol),
          onTap: onTap,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Delete button
              GestureDetector(
                onTap: () => ref
                    .read(watchlistProvider.notifier)
                    .removeStock(watchlistId, symbol),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Icon(Icons.remove_circle_outline_rounded,
                      color: AppColors.red.withOpacity(0.7), size: 20),
                ),
              ),
              // Drag handle
              ReorderableDragStartListener(
                index: index,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Icon(Icons.drag_handle_rounded,
                      color: AppColors.textMuted, size: 20),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, indent: 70),
      ],
    );
  }
}

// ─── Empty watchlist placeholder ──────────────────────────────────────────────

class _EmptyWatchlist extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyWatchlist({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_rounded,
                color: AppColors.textMuted, size: 48),
            const SizedBox(height: 16),
            const Text(
              'No stocks yet',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tap + to add stocks to this watchlist.',
              style: TextStyle(
                  color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Add Stocks'),
            ),
          ],
        ),
      ),
    );
  }
}
