import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/order_model.dart';
import '../models/product_model.dart';
import '../models/user_model.dart';
import '../models/user_role.dart';

class FirestoreDatabase {
  FirestoreDatabase({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');
  CollectionReference<Map<String, dynamic>> get _products =>
      _firestore.collection('products');
  CollectionReference<Map<String, dynamic>> get _orders =>
      _firestore.collection('orders');

  User? get firebaseUser => _auth.currentUser;

  Future<AppUser?> currentAppUser() async {
    final user = _auth.currentUser;
    if (user == null) {
      return null;
    }
    return getUserById(user.uid);
  }

  Future<AppUser?> getUserById(String id) async {
    final snapshot = await _users.doc(id).get();
    if (!snapshot.exists || snapshot.data() == null) {
      return null;
    }
    return AppUser.fromMap({'id': snapshot.id, ...snapshot.data()!});
  }

  Future<AppUser?> getUserByEmail(String email) async {
    final snapshot = await _users
        .where('email', isEqualTo: email.trim().toLowerCase())
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) {
      return null;
    }
    final doc = snapshot.docs.first;
    return AppUser.fromMap({'id': doc.id, ...doc.data()});
  }

  Future<AppUser> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim().toLowerCase(),
      password: password,
    );
    final user = credential.user!;
    await user.updateDisplayName(fullName.trim());

    final appUser = AppUser(
      id: user.uid,
      fullName: fullName.trim(),
      email: user.email ?? email.trim().toLowerCase(),
      passwordHash: '',
      role: AppRole.customer,
      createdAt: DateTime.now(),
    );
    await saveUser(appUser);
    await _auth.signOut();
    return appUser;
  }

  Future<AppUser> login({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim().toLowerCase(),
      password: password,
    );
    final user = credential.user!;
    final appUser = await getUserById(user.uid);
    if (appUser == null) {
      await _auth.signOut();
      throw FirebaseAuthException(
        code: 'missing-user-profile',
        message: 'Tài khoản chưa có hồ sơ người dùng trên Firestore.',
      );
    }
    return appUser;
  }

  Future<void> logout() => _auth.signOut();

  Future<void> saveUser(AppUser user) async {
    await _users.doc(user.id).set(user.toMap(), SetOptions(merge: true));
  }

  Stream<List<Product>> watchProducts() {
    return _products.orderBy('updatedAt', descending: true).snapshots().map((
      snapshot,
    ) {
      return snapshot.docs.map((doc) {
        return Product.fromMap({'id': doc.id, ...doc.data()});
      }).toList();
    });
  }

  Future<Product?> getProduct(String id) async {
    final snapshot = await _products.doc(id).get();
    if (!snapshot.exists || snapshot.data() == null) {
      return null;
    }
    return Product.fromMap({'id': snapshot.id, ...snapshot.data()!});
  }

  Future<void> saveProduct(Product product) async {
    await _products
        .doc(product.id)
        .set(product.toMap(), SetOptions(merge: true));
  }

  Future<void> deleteProduct(String id) async {
    await _products.doc(id).delete();
  }

  Future<bool> reduceStock(Map<String, int> quantitiesByProductId) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final productRefs = quantitiesByProductId.map((id, quantity) {
          return MapEntry(id, _products.doc(id));
        });

        final snapshots = <String, DocumentSnapshot<Map<String, dynamic>>>{};
        for (final entry in productRefs.entries) {
          snapshots[entry.key] = await transaction.get(entry.value);
        }

        for (final entry in quantitiesByProductId.entries) {
          final snapshot = snapshots[entry.key];
          final data = snapshot?.data();
          if (snapshot == null || !snapshot.exists || data == null) {
            throw StateError('missing-product');
          }
          final product = Product.fromMap({'id': snapshot.id, ...data});
          if (!product.canBePurchased ||
              product.stockQuantity < entry.value ||
              entry.value <= 0) {
            throw StateError('insufficient-stock');
          }
        }

        for (final entry in quantitiesByProductId.entries) {
          final ref = productRefs[entry.key]!;
          final snapshot = snapshots[entry.key]!;
          final product = Product.fromMap({
            'id': snapshot.id,
            ...snapshot.data()!,
          });
          transaction.update(ref, {
            'stockQuantity': product.stockQuantity - entry.value,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  Stream<List<OrderModel>> watchOrders({String? userEmail}) {
    final Stream<QuerySnapshot<Map<String, dynamic>>> snapshots;
    if (userEmail == null) {
      snapshots = _orders.orderBy('createdAt', descending: true).snapshots();
    } else {
      snapshots = _orders
          .where('userEmail', isEqualTo: userEmail.trim().toLowerCase())
          .snapshots();
    }

    return snapshots.map((snapshot) {
      final orders = snapshot.docs.map((doc) {
        return OrderModel.fromMap({'id': doc.id, ...doc.data()});
      }).toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return orders;
    });
  }

  Future<void> saveOrder(OrderModel order) async {
    await _orders.doc(order.id).set(order.toMap(), SetOptions(merge: true));
  }
}
