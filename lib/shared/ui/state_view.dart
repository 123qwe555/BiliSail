import 'package:flutter/material.dart';

import 'apple_motion.dart';

final class StateView extends StatelessWidget {
  const StateView.loading({super.key, this.message = '正在加载…'})
    : icon = Icons.hourglass_empty_rounded,
      actionLabel = null,
      onAction = null,
      isLoading = true;

  const StateView.empty({
    super.key,
    required this.message,
    this.icon = Icons.inbox_outlined,
    this.actionLabel,
    this.onAction,
  }) : isLoading = false;

  const StateView.error({super.key, this.message = '加载失败，请稍后再试', this.onAction})
    : icon = Icons.wifi_off_rounded,
      actionLabel = '重试',
      isLoading = false;

  final String message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isLoading)
                const SizedBox.square(
                  dimension: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                AppleAppear(
                  fromScale: 0.86,
                  offsetY: 6,
                  child: Icon(
                    icon,
                    size: 44,
                    color: muted.withValues(alpha: .7),
                  ),
                ),
              const SizedBox(height: 20),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: muted,
                  fontSize: 15,
                  height: 1.4,
                  letterSpacing: -0.1,
                ),
              ),
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: 20),
                ApplePressable(
                  enabled: onAction != null,
                  child: OutlinedButton(
                    onPressed: onAction,
                    child: Text(actionLabel!),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
