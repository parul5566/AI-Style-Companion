/// Reusable UI widgets used across multiple screens.
import 'package:flutter/material.dart';
import '../../core/theme.dart';

/// Glassmorphism card container.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final VoidCallback? onTap;
  final double borderRadius;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.borderRadius = 16,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: AppTheme.divider.withOpacity(0.5)),
      ),
      child: child,
    );
    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: card);
    }
    return card;
  }
}

/// Loading spinner.
class LoadingSpinner extends StatelessWidget {
  final String? message;
  const LoadingSpinner({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: AppTheme.primary),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(message!, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ],
      ),
    );
  }
}

/// Error display widget.
class ErrorDisplay extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const ErrorDisplay({super.key, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppTheme.error),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ],
        ),
      ),
    );
  }
}

/// Empty state widget.
class EmptyState extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final VoidCallback? onAction;
  final String? actionLabel;

  const EmptyState({
    super.key,
    required this.title,
    this.subtitle,
    this.icon = Icons.checkroom_outlined,
    this.onAction,
    this.actionLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: AppTheme.textSecondary.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text(title, textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(subtitle!, textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium),
            ],
            if (onAction != null && actionLabel != null) ...[
              const SizedBox(height: 24),
              ElevatedButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

/// Chip group for multi-select (used in onboarding + filters).
class ChipSelector extends StatelessWidget {
  final List<String> options;
  final List<String> selected;
  final Function(String) onToggle;
  final bool singleSelect;

  const ChipSelector({
    super.key,
    required this.options,
    required this.selected,
    required this.onToggle,
    this.singleSelect = false,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((opt) {
        final isSelected = selected.contains(opt);
        return FilterChip(
          label: Text(opt),
          selected: isSelected,
          onSelected: (_) => onToggle(opt),
          selectedColor: AppTheme.primary,
          backgroundColor: AppTheme.surfaceLight,
          side: BorderSide(
            color: isSelected ? AppTheme.primary : Colors.transparent,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        );
      }).toList(),
    );
  }
}

/// Section header used on dashboard, wardrobe, etc.
class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionText;
  final VoidCallback? onAction;

  const SectionHeader({
    super.key,
    required this.title,
    this.actionText,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: Theme.of(context).textTheme.headlineSmall),
        if (actionText != null && onAction != null)
          TextButton(
            onPressed: onAction,
            child: Text(actionText!, style: const TextStyle(color: AppTheme.primary)),
          ),
      ],
    );
  }
}

/// Priority badge for missing pieces.
class PriorityBadge extends StatelessWidget {
  final String priority;

  const PriorityBadge({super.key, required this.priority});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (priority.toLowerCase()) {
      case 'high':
        color = AppTheme.error;
        break;
      case 'medium':
        color = AppTheme.warning;
        break;
      default:
        color = AppTheme.success;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        priority.toUpperCase(),
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700),
      ),
    );
  }
}

/// Styled snackbar helper.
void showAppSnackBar(BuildContext context, String message, {bool isError = false}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: isError ? AppTheme.error : AppTheme.success,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      duration: const Duration(seconds: 3),
    ),
  );
}
