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
    // Providers live in main()'s MultiProvider (parent of this widget).
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'StoreFlow',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      routerConfig: _router,
    );
  }
}
