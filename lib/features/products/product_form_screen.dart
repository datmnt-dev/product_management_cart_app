import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app/router.dart';
import '../../core/theme/app_radii.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/validators.dart';
import '../../data/models/product_model.dart';
import '../../shared/widgets/confirm_dialog.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/product_image.dart';
import '../../shared/widgets/section_header.dart';
import '../../state/product_controller.dart';

class ProductFormScreen extends StatefulWidget {
  const ProductFormScreen({this.productId, super.key});
  final String? productId;

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _skuController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController(text: '0');
  final _imageUrlController = TextEditingController();

  Product? _editingProduct;
  ProductCategory _category = ProductCategory.other;
  ProductStatus _status = ProductStatus.active;
  bool _isSaving = false;
  bool _dirty = false;
  bool _initialized = false;

  // Snapshots for dirty detection
  late String _initialSku;
  late String _initialName;
  late String _initialDescription;
  late String _initialPrice;
  late String _initialStock;
  late String _initialImage;
  late ProductCategory _initialCategory;
  late ProductStatus _initialStatus;

  bool get _isEditing => widget.productId != null;

  @override
  void initState() {
    super.initState();
    final id = widget.productId;
    if (id != null) {
      _editingProduct = context.read<ProductController>().findById(id);
      final product = _editingProduct;
      if (product != null) {
        _skuController.text = product.sku;
        _nameController.text = product.name;
        _descriptionController.text = product.description;
        _priceController.text = product.price.toStringAsFixed(0);
        _stockController.text = product.stockQuantity.toString();
        _imageUrlController.text = product.imageUrl;
        _category = product.category;
        _status = product.status;
      }
    }
    _captureInitial();
    _initialized = true;
    for (final c in [
      _skuController,
      _nameController,
      _descriptionController,
      _priceController,
      _stockController,
      _imageUrlController,
    ]) {
      c.addListener(_markDirtyIfNeeded);
    }
    _imageUrlController.addListener(() => setState(() {}));
  }

  void _captureInitial() {
    _initialSku = _skuController.text;
    _initialName = _nameController.text;
    _initialDescription = _descriptionController.text;
    _initialPrice = _priceController.text;
    _initialStock = _stockController.text;
    _initialImage = _imageUrlController.text;
    _initialCategory = _category;
    _initialStatus = _status;
    _dirty = false;
  }

  void _markDirtyIfNeeded() {
    if (!_initialized) return;
    final dirty =
        _skuController.text != _initialSku ||
        _nameController.text != _initialName ||
        _descriptionController.text != _initialDescription ||
        _priceController.text != _initialPrice ||
        _stockController.text != _initialStock ||
        _imageUrlController.text != _initialImage ||
        _category != _initialCategory ||
        _status != _initialStatus;
    if (dirty != _dirty) {
      setState(() => _dirty = dirty);
    }
  }

  @override
  void dispose() {
    for (final c in [
      _skuController,
      _nameController,
      _descriptionController,
      _priceController,
      _stockController,
      _imageUrlController,
    ]) {
      c.removeListener(_markDirtyIfNeeded);
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final controller = context.read<ProductController>();
    final price = double.parse(_priceController.text.replaceAll(',', '.'));
    final stockQuantity = int.parse(_stockController.text.trim());

    try {
      if (_isEditing && _editingProduct != null) {
        final updated = _editingProduct!.copyWith(
          sku: _skuController.text.trim().toUpperCase(),
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          category: _category,
          price: price,
          stockQuantity: stockQuantity,
          status: _status,
          imageUrl: _imageUrlController.text.trim(),
        );
        await controller.updateProduct(updated);
        if (!mounted) return;
        _captureInitial();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã cập nhật sản phẩm thành công!'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.go(AppRoutes.productDetails(updated.id));
      } else {
        final created = await controller.addProduct(
          sku: _skuController.text,
          name: _nameController.text,
          description: _descriptionController.text,
          category: _category,
          price: price,
          stockQuantity: stockQuantity,
          status: _status,
          imageUrl: _imageUrlController.text,
        );
        if (!mounted) return;
        _captureInitial();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã thêm sản phẩm mới thành công!'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.go(AppRoutes.productDetails(created.id));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _handlePop(bool didPop, Object? result) async {
    if (didPop) return;
    if (!_dirty) {
      if (context.canPop()) {
        context.pop();
      } else {
        context.go(AppRoutes.products);
      }
      return;
    }
    final leave = await showConfirmDialog(
      context,
      title: 'Hủy thay đổi?',
      message: 'Bạn có thay đổi chưa lưu. Rời khỏi màn hình sẽ mất dữ liệu.',
      confirmLabel: 'Rời đi',
      isDestructive: true,
    );
    if (!leave || !mounted) return;
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.products);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (_isEditing && _editingProduct == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Sản phẩm')),
        body: EmptyState(
          icon: Icons.search_off,
          title: 'Không tìm thấy sản phẩm',
          message: 'Sản phẩm có thể đã bị xóa hoặc không tồn tại.',
          action: FilledButton.icon(
            onPressed: () => context.go(AppRoutes.products),
            icon: const Icon(Icons.arrow_back),
            label: const Text('Quay lại cửa hàng'),
          ),
        ),
      );
    }

    final title = _isEditing ? 'Cập nhật thông tin' : 'Đăng bán sản phẩm';

    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: _handlePop,
      child: Scaffold(
        appBar: AppBar(
          title: Text(title),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => _handlePop(false, null),
          ),
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              AppSpacing.xxxl,
            ),
            children: [
              const SectionHeader(
                title: 'Ảnh sản phẩm',
                icon: Icons.image_outlined,
              ),
              Container(
                decoration: BoxDecoration(
                  borderRadius: AppRadii.borderXxl,
                  border: Border.all(
                    color: cs.outlineVariant.withValues(alpha: .5),
                    width: 1.5,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: AppRadii.borderXxl,
                  child: ProductImage(
                    imageUrl: _imageUrlController.text,
                    width: double.infinity,
                    height: 200,
                    borderRadius: AppRadii.xxl,
                    cacheLogicalWidth: 480,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _imageUrlController,
                keyboardType: TextInputType.url,
                decoration: const InputDecoration(
                  labelText: 'Đường dẫn hình ảnh (URL)',
                  hintText: 'https://images.unsplash.com/...',
                  prefixIcon: Icon(Icons.image_search_outlined),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SectionHeader(
                      title: 'Thông tin cơ bản',
                      icon: Icons.info_outline,
                    ),
                    TextFormField(
                      controller: _skuController,
                      textInputAction: TextInputAction.next,
                      textCapitalization: TextCapitalization.characters,
                      decoration: const InputDecoration(
                        labelText: 'Mã SKU',
                        hintText: 'Ví dụ: SKU-PHONE-001',
                        prefixIcon: Icon(Icons.qr_code_2_outlined),
                      ),
                      validator: (v) => Validators.requiredText(v, 'mã SKU'),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                      controller: _nameController,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Tên sản phẩm',
                        prefixIcon: Icon(Icons.shopping_bag_outlined),
                      ),
                      validator: (v) =>
                          Validators.requiredText(v, 'tên sản phẩm'),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                      controller: _descriptionController,
                      minLines: 3,
                      maxLines: 5,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Mô tả chi tiết',
                        prefixIcon: Icon(Icons.description_outlined),
                        alignLabelWithHint: true,
                      ),
                      validator: (v) =>
                          Validators.requiredText(v, 'mô tả sản phẩm'),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    DropdownButtonFormField<ProductCategory>(
                      initialValue: _category,
                      decoration: const InputDecoration(
                        labelText: 'Danh mục',
                        prefixIcon: Icon(Icons.category_outlined),
                      ),
                      items: ProductCategory.values
                          .map(
                            (category) => DropdownMenuItem(
                              value: category,
                              child: Text(category.label),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _category = value);
                          _markDirtyIfNeeded();
                        }
                      },
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    const SectionHeader(
                      title: 'Giá & kho',
                      icon: Icons.payments_outlined,
                    ),
                    TextFormField(
                      controller: _priceController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Giá bán (VND)',
                        prefixIcon: Icon(Icons.sell_outlined),
                        suffixText: 'đ',
                      ),
                      validator: Validators.positivePrice,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                      controller: _stockController,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Tồn kho',
                        prefixIcon: Icon(Icons.inventory_2_outlined),
                        suffixText: 'sản phẩm',
                      ),
                      validator: (v) => Validators.nonNegativeInt(v, 'tồn kho'),
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    const SectionHeader(
                      title: 'Trạng thái',
                      icon: Icons.toggle_on_outlined,
                    ),
                    DropdownButtonFormField<ProductStatus>(
                      initialValue: _status,
                      decoration: const InputDecoration(
                        labelText: 'Trạng thái hiển thị',
                        prefixIcon: Icon(Icons.toggle_on_outlined),
                      ),
                      items: ProductStatus.values
                          .map(
                            (status) => DropdownMenuItem(
                              value: status,
                              child: Text(status.label),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _status = value);
                          _markDirtyIfNeeded();
                        }
                      },
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    FilledButton(
                      onPressed: _isSaving ? null : _save,
                      child: _isSaving
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: cs.onPrimary,
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.cloud_upload_outlined),
                                const SizedBox(width: 8),
                                Text(
                                  _isEditing ? 'Lưu thay đổi' : 'Đăng bán ngay',
                                ),
                              ],
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
