import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_radii.dart';
import '../../core/theme/app_spacing.dart';
import '../../data/models/product_model.dart';
import '../../state/product_controller.dart';

/// Horizontal category filter chips bound to [ProductController].
class CategoryChipBar extends StatelessWidget {
  const CategoryChipBar({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Consumer<ProductController>(
      builder: (context, ctrl, _) {
        final categories = <ProductCategory?>[null, ...ProductCategory.values];
        return SizedBox(
          height: 48,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              final isSelected = ctrl.category == category;

              return Padding(
                padding: const EdgeInsets.only(right: AppSpacing.xs),
                child: ChoiceChip(
                  label: Text(category?.label ?? 'Tất cả'),
                  selected: isSelected,
                  onSelected: (_) => ctrl.setCategory(category),
                  selectedColor: cs.primary,
                  labelStyle: TextStyle(
                    color: isSelected ? cs.onPrimary : cs.onSurface,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                  backgroundColor: cs.surface,
                  side: BorderSide(
                    color: isSelected
                        ? cs.primary
                        : cs.outlineVariant.withValues(alpha: .5),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  showCheckmark: false,
                  visualDensity: VisualDensity.compact,
                ),
              );
            },
          ),
        );
      },
    );
  }
}

/// Staff-only product status filter chips.
class StatusFilterChipBar extends StatelessWidget {
  const StatusFilterChipBar({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Consumer<ProductController>(
      builder: (context, ctrl, _) {
        final options = <(ProductStatus?, String)>[
          (null, 'Tất cả'),
          (ProductStatus.active, 'Đang bán'),
          (ProductStatus.draft, 'Nháp'),
          (ProductStatus.archived, 'Ngừng bán'),
        ];

        return SizedBox(
          height: 40,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            scrollDirection: Axis.horizontal,
            itemCount: options.length,
            separatorBuilder: (context, index) =>
                const SizedBox(width: AppSpacing.xs),
            itemBuilder: (context, index) {
              final (status, label) = options[index];
              final selected = ctrl.statusFilter == status;
              return FilterChip(
                label: Text(label),
                selected: selected,
                onSelected: (_) => ctrl.setStatusFilter(status),
                selectedColor: cs.primaryContainer,
                labelStyle: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                  color: selected ? cs.onPrimaryContainer : cs.onSurface,
                ),
                shape: RoundedRectangleBorder(borderRadius: AppRadii.borderMd),
                showCheckmark: false,
                visualDensity: VisualDensity.compact,
              );
            },
          ),
        );
      },
    );
  }
}
