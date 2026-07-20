import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../state/auth_controller.dart';
import 'router.dart';

class ProductLabApp extends StatefulWidget {
  const ProductLabApp({required this.authController, super.key});

  final AuthController authController;

  @override
  State<ProductLabApp> createState() => _ProductLabAppState();
}

class _ProductLabAppState extends State<ProductLabApp> {
  late final _router = buildAppRouter(widget.authController);

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Product Cart Lab',
      theme: AppTheme.light(),
      routerConfig: _router,
    );
  }
}
