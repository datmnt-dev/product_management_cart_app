import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/product_lab_app.dart';
import 'data/services/local_database.dart';
import 'state/auth_controller.dart';
import 'state/cart_controller.dart';
import 'state/order_controller.dart';
import 'state/product_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final database = await LocalDatabase.open();
  final preferences = await SharedPreferences.getInstance();
  final authController = AuthController(
    database: database,
    preferences: preferences,
  );

  await authController.bootstrap();

  runApp(
    MultiProvider(
      providers: [
        Provider<LocalDatabase>.value(value: database),
        ChangeNotifierProvider<AuthController>.value(value: authController),
        ChangeNotifierProvider(create: (_) => ProductController(database)),
        ChangeNotifierProvider(create: (_) => CartController()),
        ChangeNotifierProvider(create: (_) => OrderController(database)),
      ],
      child: ProductLabApp(authController: authController),
    ),
  );
}
