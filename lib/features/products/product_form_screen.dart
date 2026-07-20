import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app/router.dart';
import '../../core/utils/validators.dart';
import '../../data/models/product_model.dart';
import '../../shared/widgets/product_image.dart';
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
    _imageUrlController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _skuController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final controller = context.read<ProductController>();
    final price = double.parse(_priceController.text.replaceAll(',', '.'));
    final stockQuantity = int.parse(_stockController.text.trim());

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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã thêm sản phẩm mới thành công!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      context.go(AppRoutes.productDetails(created.id));
    }

    if (mounted) setState(() => _isSaving = false);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (_isEditing && _editingProduct == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Lỗi')),
        body: Center(
          child: FilledButton.icon(
            onPressed: () => context.go(AppRoutes.products),
            icon: const Icon(Icons.arrow_back),
            label: const Text('Quay lại cửa hàng'),
          ),
        ),
      );
    }

    final title = _isEditing ? 'Cập nhật thông tin' : 'Đăng bán sản phẩm';

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            // ── Live bordered image preview ──
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: cs.outlineVariant.withValues(alpha: .5),
                  width: 1.5,
                ),
              ),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: ProductImage(
                      imageUrl: _imageUrlController.text,
                      width: double.infinity,
                      height: 220,
                      borderRadius: 18,
                    ),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: .75),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.photo_library_outlined,
                            size: 12,
                            color: Colors.white,
                          ),
                          SizedBox(width: 5),
                          Text(
                            'Ảnh xem trước',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Form input controls ──
            Form(
              key: _formKey,
              child: Column(
                children: [
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
                  const SizedBox(height: 16),
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
                  const SizedBox(height: 16),
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
                  const SizedBox(height: 16),
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
                      }
                    },
                  ),
                  const SizedBox(height: 16),
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
                  const SizedBox(height: 16),
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
                  const SizedBox(height: 16),
                  DropdownButtonFormField<ProductStatus>(
                    initialValue: _status,
                    decoration: const InputDecoration(
                      labelText: 'Trạng thái',
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
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _imageUrlController,
                    keyboardType: TextInputType.url,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _save(),
                    decoration: const InputDecoration(
                      labelText: 'Đường dẫn hình ảnh (URL)',
                      hintText: 'https://images.unsplash.com/...',
                      prefixIcon: Icon(Icons.image_search_outlined),
                    ),
                  ),
                  const SizedBox(height: 30),
                  FilledButton(
                    onPressed: _isSaving ? null : _save,
                    child: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
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
    );
  }
}
