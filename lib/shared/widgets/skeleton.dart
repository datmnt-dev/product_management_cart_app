import 'package:flutter/material.dart';

import '../../core/theme/app_motion.dart';
import '../../core/theme/app_radii.dart';
import '../../core/theme/app_spacing.dart';

/// Soft shimmer placeholder block.
class SkeletonBox extends StatefulWidget {
  const SkeletonBox({
    this.width,
    this.height = 16,
    this.borderRadius,
    super.key,
  });

  final double? width;
  final double height;
  final BorderRadius? borderRadius;

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final reduce = AppMotion.reduceMotion(context);
    final radius = widget.borderRadius ?? AppRadii.borderMd;

    Widget box({required double opacity}) {
      return Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: cs.onSurface.withValues(alpha: opacity),
          borderRadius: radius,
        ),
      );
    }

    if (reduce) {
      return box(opacity: 0.08);
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;
        final opacity = 0.06 + (t * 0.08);
        return box(opacity: opacity);
      },
    );
  }
}

/// Placeholder matching a product grid card layout.
class ProductCardSkeleton extends StatelessWidget {
  const ProductCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Expanded(
            flex: 5,
            child: SkeletonBox(
              height: double.infinity,
              borderRadius: BorderRadius.zero,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBox(
                  width: double.infinity,
                  height: 14,
                  borderRadius: AppRadii.borderSm,
                ),
                const SizedBox(height: AppSpacing.xs),
                SkeletonBox(
                  width: 96,
                  height: 12,
                  borderRadius: AppRadii.borderSm,
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: SkeletonBox(
                        height: 16,
                        borderRadius: AppRadii.borderSm,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    SkeletonBox(
                      width: 36,
                      height: 36,
                      borderRadius: AppRadii.borderMd,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Simple grid of [ProductCardSkeleton] for list loading.
class ProductGridSkeleton extends StatelessWidget {
  const ProductGridSkeleton({
    this.itemCount = 6,
    this.crossAxisCount = 2,
    super.key,
  });

  final int itemCount;
  final int crossAxisCount;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: AppSpacing.pagePaddingLg,
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: itemCount,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: AppSpacing.sm,
        crossAxisSpacing: AppSpacing.sm,
        childAspectRatio: 0.65,
      ),
      itemBuilder: (context, index) => const ProductCardSkeleton(),
    );
  }
}
