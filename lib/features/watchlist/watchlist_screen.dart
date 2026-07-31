import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../data/models/watchlist.dart';
import '../../providers/watchlist_provider.dart';
import 'watchlist_detail_screen.dart';

class WatchlistScreen extends ConsumerStatefulWidget {
  const WatchlistScreen({super.key});

  @override
  ConsumerState<WatchlistScreen> createState() => _WatchlistScreenState();
}

class _WatchlistScreenState extends ConsumerState<WatchlistScreen>
    with TickerProviderStateMixin {
  TabController? _tabController;
  int _prevLength = 0;
  int _targetTabIndex = 0; // index to jump to after rebuild

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  TabController _buildController(int length, {int initialIndex = 0}) {
    _tabController?.dispose();
    return TabController(
      length: length,
      vsync: this,
      initialIndex: initialIndex.clamp(0, length > 0 ? length - 1 : 0),
    );
  }

  // ─── Dialogs ──────────────────────────────────────────────────────────────

  Future<void> _showCreateDialog() async {
    final ctrl = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => _WatchlistNameDialog(
        title: 'New Watchlist',
        controller: ctrl,
        onConfirm: () => Navigator.pop(ctx, ctrl.text.trim()),
      ),
    );
    if (result != null && result.isNotEmpty && mounted) {
      ref.read(watchlistProvider.notifier).createWatchlist(result);
      // Jump to the new tab (it'll be appended at the end).
      _targetTabIndex = _prevLength; // current length = new last index
    }
  }

  Future<void> _showRenameDialog(Watchlist wl) async {
    final ctrl = TextEditingController(text: wl.name);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => _WatchlistNameDialog(
        title: 'Rename Watchlist',
        controller: ctrl,
        onConfirm: () => Navigator.pop(ctx, ctrl.text.trim()),
      ),
    );
    if (result != null && result.isNotEmpty && mounted) {
      ref.read(watchlistProvider.notifier).renameWatchlist(wl.id, result);
    }
  }

  Future<void> _showDeleteDialog(Watchlist wl) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Watchlist'),
        content:
            Text('Delete "${wl.name}"? This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
                foregroundColor: AppColors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      ref.read(watchlistProvider.notifier).deleteWatchlist(wl.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final watchlists = ref.watch(watchlistProvider);

    // Sync TabController when the list length changes.
    if (watchlists.length != _prevLength) {
      final goTo = _targetTabIndex.clamp(
          0, watchlists.isEmpty ? 0 : watchlists.length - 1);
      _tabController = _buildController(watchlists.length, initialIndex: goTo);
      _prevLength = watchlists.length;
      _targetTabIndex = 0;
    } else if (_tabController == null && watchlists.isNotEmpty) {
      _tabController = _buildController(watchlists.length);
      _prevLength = watchlists.length;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Watchlists'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'New Watchlist',
            onPressed: _showCreateDialog,
          ),
        ],
        bottom: watchlists.isNotEmpty && _tabController != null
            ? TabBar(
                controller: _tabController,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                tabs: watchlists
                    .map((w) => Tab(text: w.name))
                    .toList(),
              )
            : null,
      ),
      body: watchlists.isEmpty
          ? _EmptyState(onCreate: _showCreateDialog)
          : _tabController == null
              ? const SizedBox.shrink()
              : TabBarView(
                  controller: _tabController,
                  children: watchlists
                      .map((w) => WatchlistDetailScreen(
                            key: ValueKey(w.id),
                            watchlist: w,
                            onRename: () => _showRenameDialog(w),
                            onDelete: () => _showDeleteDialog(w),
                          ))
                      .toList(),
                ),
    );
  }
}

// ─── Empty state ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final VoidCallback onCreate;
  const _EmptyState({required this.onCreate});

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
              decoration: BoxDecoration(
                color: AppColors.card,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.bookmark_border_rounded,
                size: 36,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'No Watchlists Yet',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Create a watchlist to track your\nfavourite stocks.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: AppColors.textSecondary, fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Create Watchlist'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Watchlist name dialog ────────────────────────────────────────────────────

class _WatchlistNameDialog extends StatelessWidget {
  final String title;
  final TextEditingController controller;
  final VoidCallback onConfirm;

  const _WatchlistNameDialog({
    required this.title,
    required this.controller,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: TextField(
        controller: controller,
        autofocus: true,
        maxLength: 30,
        decoration: const InputDecoration(
          hintText: 'e.g. Tech Giants',
          counterText: '',
        ),
        onSubmitted: (_) => onConfirm(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: onConfirm,
          child: const Text('Save'),
        ),
      ],
    );
  }
}
