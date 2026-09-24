import 'package:flutter/material.dart';

import '../models/order.dart';

class StatusStepper extends StatelessWidget {
  const StatusStepper({
    super.key,
    required this.current,
  });

  final OrderStatus current;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Semantics(
      label: 'Order status ${current.label}',
      child: Column(
        children: [
          for (final OrderStatus status in OrderStatus.values)
            _StatusRow(
              status: status,
              current: current,
              colors: colors,
            ),
        ],
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({
    required this.status,
    required this.current,
    required this.colors,
  });

  final OrderStatus status;
  final OrderStatus current;
  final ColorScheme colors;

  @override
  Widget build(BuildContext context) {
    final bool completed = status.index < current.index;
    final bool active = status == current;
    final String marker = completed
        ? '✓'
        : active
            ? '●'
            : '○';
    final String stateLabel = completed
        ? 'completed'
        : active
            ? 'current'
            : 'upcoming';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(
              marker,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: completed || active ? colors.primary : colors.outline,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              status.label,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                    color: completed || active
                        ? colors.onSurface
                        : colors.onSurfaceVariant,
                  ),
            ),
          ),
          Text(
            stateLabel,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}
