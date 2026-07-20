import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radii.dart';
import '../../data/models/product_model.dart';

/// Compact product status / badge chip for catalog cards.
class StatusChip extends StatelessWidget {
  const StatusChip({
    required this.label,
    required this.background,
    required this.foreground,
    super.key,
  });

  final String label;
  final Color background;
  final Color foreground;

  factory StatusChip.productStatus(
    ProductStatus status, {
    required Brightness brightness,
  }) {
    switch (status) {
      case ProductStatus.active:
        return StatusChip(
          label: status.label,
          background: AppColors.success(brightness).withValues(alpha: .15),
          foreground: AppColors.success(brightness),
        );
      case ProductStatus.draft:
        return StatusChip(
          label: status.label,
          background: AppColors.warning(brightness).withValues(alpha: .18),
          foreground: AppColors.warning(brightness),
        );
      case ProductStatus.archived:
        return StatusChip(
          label: status.label,
          background: Colors.blueGrey.withValues(alpha: .15),
          foreground: Colors.blueGrey.shade700,
        );
    }
  }

  factory StatusChip.newBadge(ColorScheme scheme) {
    return StatusChip(
      label: 'MỚI',
      background: scheme.secondary,
      foreground: scheme.onSecondary,
    );
  }

  factory StatusChip.outOfStock(ColorScheme scheme) {
    return StatusChip(
      label: 'Hết hàng',
      background: scheme.errorContainer.withValues(alpha: .7),
      foreground: scheme.onErrorContainer,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: AppRadii.borderSm,
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foreground,
          fontSize: 11,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
