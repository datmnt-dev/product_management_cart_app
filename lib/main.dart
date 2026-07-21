import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/product_lab_app.dart';
import 'data/services/firestore_database.dart';
import 'firebase_options.dart';
import 'state/auth_controller.dart';
import 'state/cart_controller.dart';
import 'state/order_alert_controller.dart';
import 'state/order_controller.dart';
import 'state/product_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final database = FirestoreDatabase();
  final preferences = await SharedPreferences.getInstance();
  final authController = AuthController(
    database: database,
    preferences: preferences,
  );

  await authController.bootstrap();

  final cartController = CartController(preferences: preferences);
  final productController = ProductController(database, authController);
  final orderController = OrderController(database, authController);

  // Direct construction — never create OrderAlert via context.read in Provider.create.
  final alertController = OrderAlertController(
    authController: authController,
    orderController: orderController,
    preferences: preferences,
  );

  void syncCart() {
    final email = authController.currentUser?.email;
    if (email == null) {
      cartController.clearForLogout();
    } else {
      cartController.bindUser(email, productController.products);
    }
  }

  authController.addListener(syncCart);
  productController.addListener(syncCart);
  syncCart();

  // ignore: avoid_print
  print('StoreFlow boot: providers ready (OrderAlertController in main)');

  runApp(
    MultiProvider(
      providers: [
        Provider<FirestoreDatabase>.value(value: database),
        ChangeNotifierProvider<AuthController>.value(value: authController),
        ChangeNotifierProvider<ProductController>.value(
          value: productController,
        ),
        ChangeNotifierProvider<CartController>.value(value: cartController),
        ChangeNotifierProvider<OrderController>.value(value: orderController),
        ChangeNotifierProvider<OrderAlertController>.value(
          value: alertController,
        ),
      ],
      child: ProductLabApp(authController: authController),
    ),
  );
}
