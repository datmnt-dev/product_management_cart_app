import '../data/models/product_model.dart';
import 'product_controller.dart';

/// Pure product filter pipeline (design §5.1).
///
/// Order:
/// 1. raw products
/// 2. role gate (customers → active only)
/// 3. category
/// 4. staff statusFilter (ignored when [canManageProducts] is false)
/// 5. in-stock only (optional)
/// 6. search (name / description / sku)
/// 7. sort
List<Product> applyProductFilters({
  required List<Product> products,
  required bool canManageProducts,
  ProductCategory? category,
  ProductStatus? statusFilter,
  required String searchQuery,
  required ProductSort sort,
  bool inStockOnly = false,
}) {
  final query = searchQuery.trim().toLowerCase();

  final items = products.where((product) {
    // 2. Role gate
    if (!canManageProducts && product.status != ProductStatus.active) {
      return false;
    }

    // 3. Category
    if (category != null && product.category != category) {
      return false;
    }

    // 4. Staff status filter
    if (canManageProducts &&
        statusFilter != null &&
        product.status != statusFilter) {
      return false;
    }

    // 5. In stock
    if (inStockOnly && product.stockQuantity <= 0) {
      return false;
    }

    // 6. Search
    if (query.isEmpty) {
      return true;
    }
    return product.name.toLowerCase().contains(query) ||
        product.description.toLowerCase().contains(query) ||
        product.sku.toLowerCase().contains(query);
  }).toList();

  // 7. Sort
  switch (sort) {
    case ProductSort.priceAsc:
      items.sort((a, b) => a.price.compareTo(b.price));
    case ProductSort.priceDesc:
      items.sort((a, b) => b.price.compareTo(a.price));
    case ProductSort.newest:
      items.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    case ProductSort.stockDesc:
      items.sort((a, b) => b.stockQuantity.compareTo(a.stockQuantity));
  }

  return items;
}

/// Whether a single product is storefront-visible for the current role.
/// Staff see all statuses; customers only [ProductStatus.active].
/// UX-only — Firestore product reads remain open to signed-in users.
bool isProductVisibleToRole({
  required Product product,
  required bool canManageProducts,
}) {
  if (canManageProducts) {
    return true;
  }
  return product.status == ProductStatus.active;
}
