import 'package:flutter/material.dart';

class ProductImage extends StatelessWidget {
  const ProductImage({
    required this.imageUrl,
    this.width = 84,
    this.height = 84,
    this.borderRadius = 12,
    super.key,
  });

  final String imageUrl;
  final double width;
  final double height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(borderRadius);
    final cs = Theme.of(context).colorScheme;

    if (imageUrl.trim().isEmpty) {
      return _Fallback(
        width: width,
        height: height,
        radius: radius,
        colorScheme: cs,
      );
    }

    return ClipRRect(
      borderRadius: radius,
      child: Image.network(
        imageUrl.trim(),
        width: width,
        height: height,
        fit: BoxFit.cover,
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
      width: width,
      height: height,
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
                size: width > 90 ? 28 : 20,
              ),
      ),
    );
  }
}
