import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';

/// Surface-aligned bottom bar for detail/cart primary CTAs.
class PrimaryBottomBar extends StatelessWidget {
  const PrimaryBottomBar({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      elevation: 0,
      color: cs.surface,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: cs.surface,
          border: Border(
            top: BorderSide(color: cs.outlineVariant.withValues(alpha: .25)),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .04),
              blurRadius: 12,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        // bottom: false — shell NavigationBar already owns bottom safe inset.
        child: SafeArea(
          bottom: false,
          minimum: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
            AppSpacing.sm,
          ),
          child: child,
        ),
      ),
    );
  }
}
