import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../core/utils/currency_utils.dart';
import '../../data/models/order.dart';

class OrderConfirmationScreen extends StatelessWidget {
  final Order order;

  const OrderConfirmationScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final isBuy = order.side == OrderSide.buy;
    final sideColor = isBuy ? AppColors.green : AppColors.red;
    final sideLabel = isBuy ? 'Buy' : 'Sell';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Order Confirmed'),
        centerTitle: true,
        backgroundColor: AppColors.surface,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            // ── Success icon ─────────────────────────────────────────
            Center(
              child: _SuccessRing(color: sideColor),
            ),
            const SizedBox(height: 24),
            // ── Headline ─────────────────────────────────────────────
            Center(
              child: Text(
                'Order Placed!',
                style: TextStyle(
                  color: sideColor,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Center(
              child: Text(
                '$sideLabel order for ${order.symbol} executed',
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 14),
              ),
            ),
            const SizedBox(height: 32),
            // ── Order details card ────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.divider),
              ),
              child: Column(
                children: [
                  _DetailRow(
                    label: 'Order ID',
                    value: order.id.substring(0, 8).toUpperCase(),
                    isMono: true,
                  ),
                  _DetailRow(label: 'Symbol', value: order.symbol),
                  _DetailRow(
                    label: 'Side',
                    value: sideLabel,
                    valueColor: sideColor,
                  ),
                  _DetailRow(
                      label: 'Quantity',
                      value: '${order.quantity} shares'),
                  _DetailRow(
                      label: 'Execution Price',
                      value: CurrencyUtils.formatPrice(order.price)),
                  const Divider(height: 24),
                  _DetailRow(
                    label: 'Total Value',
                    value: CurrencyUtils.formatINR(order.totalValue),
                    labelStyle: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                    valueStyle: TextStyle(
                      color: sideColor,
                      fontWeight: FontWeight.w800,
                      fontSize: 17,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(height: 8),
                  _DetailRow(
                    label: 'Time',
                    value: _formatTime(order.timestamp),
                    valueColor: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // ── Stock info ────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: sideColor.withOpacity(0.07),
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: sideColor.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Icon(
                    isBuy
                        ? Icons.trending_up_rounded
                        : Icons.trending_down_rounded,
                    color: sideColor,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      isBuy
                          ? 'Shares added to your Holdings. Monitor live P&L in the Holdings tab.'
                          : 'Shares sold. Proceeds credited to your wallet.',
                      style: TextStyle(
                          color: sideColor,
                          fontSize: 13,
                          height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            // ── Actions ───────────────────────────────────────────────
            ElevatedButton(
              onPressed: () => context.go('/holdings'),
              child: const Text('View Holdings'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => context.go('/market'),
              child: const Text('Back to Market'),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    final s = dt.second.toString().padLeft(2, '0');
    final day = '${dt.day}/${dt.month}/${dt.year}';
    return '$day  $h:$m:$s';
  }
}

// ─── Subwidgets ───────────────────────────────────────────────────────────────

class _SuccessRing extends StatefulWidget {
  final Color color;
  const _SuccessRing({required this.color});

  @override
  State<_SuccessRing> createState() => _SuccessRingState();
}

class _SuccessRingState extends State<_SuccessRing>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _scale = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: Container(
        width: 90,
        height: 90,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.color.withOpacity(0.12),
          border: Border.all(color: widget.color.withOpacity(0.5), width: 2),
        ),
        child: Icon(Icons.check_rounded, color: widget.color, size: 44),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool isMono;
  final TextStyle? labelStyle;
  final TextStyle? valueStyle;

  const _DetailRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.isMono = false,
    this.labelStyle,
    this.valueStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: labelStyle ??
                  const TextStyle(
                      color: AppColors.textSecondary, fontSize: 13)),
          Text(
            value,
            style: valueStyle ??
                TextStyle(
                  color: valueColor ?? AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  fontFamily: isMono ? 'monospace' : null,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
          ),
        ],
      ),
    );
  }
}
