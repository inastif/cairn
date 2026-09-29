import 'package:cairn/theme/app_colors.dart';
import 'package:cairn/theme/app_tokens.dart';
import 'package:flutter/material.dart';

class LoadingView extends StatelessWidget {
  const LoadingView({super.key, this.message = 'Chargement de vos données'});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Semantics(
        liveRegion: true,
        label: message,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox.square(
              dimension: 28,
              child: CircularProgressIndicator(strokeWidth: 2.5, color: context.colors.accent),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(message, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}

/// Erreur expliquée en langage clair, avec une action pour s'en sortir.
class ErrorView extends StatelessWidget {
  const ErrorView({required this.message, super.key, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return _MessageView(
      icon: Icons.cloud_off_outlined,
      title: 'Données indisponibles',
      message: message,
      actionLabel: onRetry == null ? null : 'Réessayer',
      onAction: onRetry,
    );
  }
}

class EmptyView extends StatelessWidget {
  const EmptyView({
    required this.title,
    required this.message,
    super.key,
    this.icon = Icons.inbox_outlined,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return _MessageView(
      icon: icon,
      title: title,
      message: message,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }
}

class _MessageView extends StatelessWidget {
  const _MessageView({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final label = actionLabel;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 36, color: context.colors.textTertiary),
              const SizedBox(height: AppSpacing.lg),
              Text(title, style: text.titleMedium, textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.sm),
              Text(message, style: text.bodyMedium, textAlign: TextAlign.center),
              if (label != null && onAction != null) ...[
                const SizedBox(height: AppSpacing.xl),
                FilledButton(onPressed: onAction, child: Text(label)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
