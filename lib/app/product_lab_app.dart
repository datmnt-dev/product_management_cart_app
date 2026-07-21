import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/theme/app_theme.dart';
import '../state/auth_controller.dart';
import '../state/order_alert_controller.dart';
import '../state/order_controller.dart';
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
    // Provide alerts *under* MultiProvider (auth/orders/prefs) but *above*
    // MaterialApp / go_router / AppShell — so shell can always read them.
    // Creating here (not only in main) also survives partial hot-reload better.
    return ChangeNotifierProvider<OrderAlertController>(
      create: (ctx) => OrderAlertController(
        authController: widget.authController,
        orderController: ctx.read<OrderController>(),
        preferences: ctx.read<SharedPreferences>(),
      ),
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        title: 'StoreFlow',
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: ThemeMode.system,
        routerConfig: _router,
      ),
    );
  }
}
