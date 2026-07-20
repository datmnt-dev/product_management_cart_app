import 'package:flutter_test/flutter_test.dart';
import 'package:product_management_cart_app/data/models/product_model.dart';
import 'package:product_management_cart_app/state/product_controller.dart';
import 'package:product_management_cart_app/state/product_filters.dart';

Product _product({
  required String id,
  ProductStatus status = ProductStatus.active,
  ProductCategory category = ProductCategory.phone,
  double price = 100,
  String name = 'Phone',
  String sku = 'SKU-1',
  String description = 'Desc',
  DateTime? updatedAt,
}) {
  final now = updatedAt ?? DateTime(2026, 1, 1);
  return Product(
    id: id,
    sku: sku,
    name: name,
    description: description,
    category: category,
    price: price,
    stockQuantity: 5,
    status: status,
    imageUrl: '',
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  group('applyProductFilters §5.1', () {
    final catalog = [
      _product(id: 'active', status: ProductStatus.active, price: 300),
      _product(
        id: 'draft',
        status: ProductStatus.draft,
        price: 200,
        name: 'Draft phone',
        sku: 'DRF-1',
      ),
      _product(
        id: 'archived',
        status: ProductStatus.archived,
        price: 100,
        category: ProductCategory.laptop,
        name: 'Old laptop',
        sku: 'ARC-1',
      ),
      _product(
        id: 'oos-active',
        status: ProductStatus.active,
        price: 150,
        name: 'Out of stock still active',
        sku: 'OOS-1',
      ),
    ];

    test('customer role gate keeps only active (including OOS active)', () {
      final result = applyProductFilters(
        products: catalog,
        canManageProducts: false,
        category: null,
        statusFilter: ProductStatus.draft, // must be ignored for customers
        searchQuery: '',
        sort: ProductSort.newest,
      );

      expect(result.map((p) => p.id), containsAll(['active', 'oos-active']));
      expect(result.any((p) => p.id == 'draft'), isFalse);
      expect(result.any((p) => p.id == 'archived'), isFalse);
    });

    test('staff sees all statuses when statusFilter is null', () {
      final result = applyProductFilters(
        products: catalog,
        canManageProducts: true,
        category: null,
        statusFilter: null,
        searchQuery: '',
        sort: ProductSort.newest,
      );

      expect(result.length, catalog.length);
    });

    test('staff statusFilter draft only', () {
      final result = applyProductFilters(
        products: catalog,
        canManageProducts: true,
        category: null,
        statusFilter: ProductStatus.draft,
        searchQuery: '',
        sort: ProductSort.newest,
      );

      expect(result.map((p) => p.id), ['draft']);
    });

    test('category filter applies after role gate', () {
      final result = applyProductFilters(
        products: catalog,
        canManageProducts: true,
        category: ProductCategory.laptop,
        statusFilter: null,
        searchQuery: '',
        sort: ProductSort.newest,
      );

      expect(result.map((p) => p.id), ['archived']);
    });

    test('search matches name description sku', () {
      final byName = applyProductFilters(
        products: catalog,
        canManageProducts: true,
        category: null,
        statusFilter: null,
        searchQuery: 'draft phone',
        sort: ProductSort.newest,
      );
      expect(byName.map((p) => p.id), ['draft']);

      final bySku = applyProductFilters(
        products: catalog,
        canManageProducts: true,
        category: null,
        statusFilter: null,
        searchQuery: 'oos-1',
        sort: ProductSort.newest,
      );
      expect(bySku.map((p) => p.id), ['oos-active']);
    });

    test('sort price ascending and descending', () {
      final asc = applyProductFilters(
        products: catalog,
        canManageProducts: true,
        category: null,
        statusFilter: null,
        searchQuery: '',
        sort: ProductSort.priceAsc,
      );
      expect(asc.first.id, 'archived');
      expect(asc.last.id, 'active');

      final desc = applyProductFilters(
        products: catalog,
        canManageProducts: true,
        category: null,
        statusFilter: null,
        searchQuery: '',
        sort: ProductSort.priceDesc,
      );
      expect(desc.first.id, 'active');
      expect(desc.last.id, 'archived');
    });
  });

  group('isProductVisibleToRole', () {
    test('customers only see active', () {
      expect(
        isProductVisibleToRole(
          product: _product(id: 'a', status: ProductStatus.active),
          canManageProducts: false,
        ),
        isTrue,
      );
      expect(
        isProductVisibleToRole(
          product: _product(id: 'd', status: ProductStatus.draft),
          canManageProducts: false,
        ),
        isFalse,
      );
    });

    test('staff see draft and archived', () {
      expect(
        isProductVisibleToRole(
          product: _product(id: 'd', status: ProductStatus.draft),
          canManageProducts: true,
        ),
        isTrue,
      );
      expect(
        isProductVisibleToRole(
          product: _product(id: 'x', status: ProductStatus.archived),
          canManageProducts: true,
        ),
        isTrue,
      );
    });
  });
}
