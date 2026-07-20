import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/product_lab_app.dart';
import 'data/services/firestore_database.dart';
import 'firebase_options.dart';
import 'state/auth_controller.dart';
import 'state/cart_controller.dart';
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

  runApp(
    MultiProvider(
      providers: [
        Provider<FirestoreDatabase>.value(value: database),
        ChangeNotifierProvider<AuthController>.value(value: authController),
        ChangeNotifierProvider(
          create: (_) => ProductController(database, authController),
        ),
        ChangeNotifierProvider(create: (_) => CartController()),
        ChangeNotifierProvider(
          create: (_) => OrderController(database, authController),
        ),
      ],
      child: ProductLabApp(authController: authController),
    ),
  );
}
