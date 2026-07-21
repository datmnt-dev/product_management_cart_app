import 'package:flutter/material.dart';

/// Network product image with decode-size hints and fallback.
class ProductImage extends StatelessWidget {
  const ProductImage({
    required this.imageUrl,
    this.width = 84,
    this.height = 84,
    this.borderRadius = 12,

    /// Logical width used for [Image.network.cacheWidth] when [width] is infinite.
    this.cacheLogicalWidth = 200,
    super.key,
  });

  final String imageUrl;
  final double width;
  final double height;
  final double borderRadius;
  final double cacheLogicalWidth;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(borderRadius);
    final cs = Theme.of(context).colorScheme;
    final dpr = MediaQuery.devicePixelRatioOf(context);

    if (imageUrl.trim().isEmpty) {
      return _Fallback(
        width: width,
        height: height,
        radius: radius,
        colorScheme: cs,
      );
    }

    final logicalW = width.isFinite && width > 0 ? width : cacheLogicalWidth;
    final logicalH = height.isFinite && height > 0 ? height : cacheLogicalWidth;
    final cacheW = (logicalW * dpr).round().clamp(48, 1200);
    final cacheH = (logicalH * dpr).round().clamp(48, 1200);

    return ClipRRect(
      borderRadius: radius,
      child: Image.network(
        imageUrl.trim(),
        width: width.isFinite ? width : null,
        height: height.isFinite ? height : null,
        fit: BoxFit.cover,
        cacheWidth: cacheW,
        cacheHeight: cacheH,
        filterQuality: FilterQuality.medium,
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          if (wasSynchronouslyLoaded) return child;
          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: frame != null
                ? child
                : _Fallback(
                    width: width,
                    height: height,
                    radius: radius,
                    colorScheme: cs,
                    showLoader: true,
                  ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return _Fallback(
            width: width,
            height: height,
            radius: radius,
            colorScheme: cs,
          );
        },
      ),
    );
  }
}

class _Fallback extends StatelessWidget {
  const _Fallback({
    required this.width,
    required this.height,
    required this.radius,
    required this.colorScheme,
    this.showLoader = false,
  });

  final double width;
  final double height;
  final BorderRadius radius;
  final ColorScheme colorScheme;
  final bool showLoader;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width.isFinite ? width : null,
      height: height.isFinite ? height : null,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: .5),
        borderRadius: radius,
      ),
      child: Center(
        child: showLoader
            ? SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: colorScheme.primary.withValues(alpha: .6),
                ),
              )
            : Icon(
                Icons.broken_image_outlined,
                color: colorScheme.onSurfaceVariant.withValues(alpha: .4),
                size: (width.isFinite && width > 90) ? 28 : 20,
              ),
      ),
    );
  }
}
