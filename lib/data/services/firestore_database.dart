import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../models/coupon_model.dart';
import '../models/inventory_movement.dart';
import '../models/order_model.dart';
import '../models/seller_fulfillment.dart';
import '../models/product_model.dart';
import '../models/user_model.dart';
import '../models/user_role.dart';

class FirestoreDatabase {
  FirestoreDatabase({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    GoogleSignIn? googleSignIn,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance,
       _googleSignIn = googleSignIn ?? GoogleSignIn.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final GoogleSignIn _googleSignIn;
  var _googleInitialized = false;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');
  CollectionReference<Map<String, dynamic>> get _products =>
      _firestore.collection('products');
  CollectionReference<Map<String, dynamic>> get _orders =>
      _firestore.collection('orders');
  CollectionReference<Map<String, dynamic>> get _coupons =>
      _firestore.collection('coupons');
  CollectionReference<Map<String, dynamic>> get _inventoryMovements =>
      _firestore.collection('inventoryMovements');
  CollectionReference<Map<String, dynamic>> get _sellerFulfillments =>
      _firestore.collection('sellerFulfillments');

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

  Future<AppUser> signInWithGoogle() async {
    final userCredential = await _authenticateWithGoogle();
    final firebaseUser = userCredential.user!;

    final existing = await getUserById(firebaseUser.uid);
    if (existing != null) {
      return existing;
    }

    final email = firebaseUser.email?.trim().toLowerCase();
    if (email == null || email.isEmpty) {
      await _auth.signOut();
      throw FirebaseAuthException(
        code: 'missing-google-email',
        message: 'Tài khoản Google không có email hợp lệ.',
      );
    }

    final appUser = AppUser(
      id: firebaseUser.uid,
      fullName: firebaseUser.displayName?.trim().isNotEmpty == true
          ? firebaseUser.displayName!.trim()
          : email.split('@').first,
      email: email,
      passwordHash: '',
      role: AppRole.customer,
      createdAt: DateTime.now(),
    );
    await saveUser(appUser);
    return appUser;
  }

  Future<UserCredential> _authenticateWithGoogle() async {
    // Google Identity Services on web requires Firebase's browser popup flow.
    // google_sign_in.authenticate() is available only on mobile platforms.
    if (kIsWeb) {
      return _auth.signInWithPopup(GoogleAuthProvider());
    }

    if (!_googleInitialized) {
      await _googleSignIn.initialize();
      _googleInitialized = true;
    }

    final googleAccount = await _googleSignIn.authenticate();
    final idToken = googleAccount.authentication.idToken;
    if (idToken == null || idToken.isEmpty) {
      throw FirebaseAuthException(
        code: 'missing-google-id-token',
        message: 'Không lấy được Google ID token.',
      );
    }

    return _auth.signInWithCredential(
      GoogleAuthProvider.credential(idToken: idToken),
    );
  }

  Future<void> logout() async {
    await _auth.signOut();
    if (_googleInitialized) {
      await _googleSignIn.signOut();
    }
  }

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

  Stream<List<Coupon>> watchCoupons() => _coupons.snapshots().map((snapshot) {
    final items = snapshot.docs
        .map((doc) => Coupon.fromMap({'code': doc.id, ...doc.data()}))
        .toList();
    items.sort((a, b) => a.expiresAt.compareTo(b.expiresAt));
    return items;
  });
  Future<void> saveCoupon(Coupon coupon) =>
      _coupons.doc(Coupon.normalizeCode(coupon.code)).set(coupon.toMap());

  Stream<List<InventoryMovement>> watchInventoryMovements(String productId) =>
      _inventoryMovements
          .where('productId', isEqualTo: productId)
          .orderBy('createdAt', descending: true)
          .limit(20)
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map(
                  (doc) =>
                      InventoryMovement.fromMap({'id': doc.id, ...doc.data()}),
                )
                .toList(),
          );

  Future<void> adjustStock({
    required Product product,
    required int quantityDelta,
    required InventoryMovementType type,
    required String note,
  }) async {
    if (quantityDelta == 0) {
      throw StateError('Số lượng điều chỉnh phải khác 0.');
    }
    final email = _auth.currentUser?.email?.trim().toLowerCase();
    if (email == null || email.isEmpty) {
      throw StateError('Vui lòng đăng nhập lại.');
    }
    final productRef = _products.doc(product.id);
    final movementRef = _inventoryMovements.doc();
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(productRef);
      final data = snapshot.data();
      if (!snapshot.exists || data == null) {
        throw StateError('Sản phẩm không còn tồn tại.');
      }
      final current = Product.fromMap({'id': snapshot.id, ...data});
      final after = current.stockQuantity + quantityDelta;
      if (after < 0) {
        throw StateError(
          'Tồn kho không thể âm (hiện có ${current.stockQuantity}).',
        );
      }
      transaction.update(productRef, {
        'stockQuantity': after,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      transaction.set(
        movementRef,
        InventoryMovement(
          id: movementRef.id,
          productId: current.id,
          productName: current.name,
          type: type,
          quantityDelta: quantityDelta,
          stockBefore: current.stockQuantity,
          stockAfter: after,
          note: note.trim(),
          byEmail: email,
          createdAt: DateTime.now(),
        ).toMap(),
      );
    });
  }

  Future<AppliedCoupon> previewCoupon({
    required String code,
    required double subtotal,
  }) async {
    final normalized = Coupon.normalizeCode(code);
    if (normalized.isEmpty) {
      throw StateError('Vui lòng nhập mã giảm giá.');
    }
    final snapshot = await _coupons.doc(normalized).get();
    if (!snapshot.exists || snapshot.data() == null) {
      throw StateError('Mã giảm giá không tồn tại.');
    }
    final coupon = Coupon.fromMap({'code': snapshot.id, ...snapshot.data()!});
    return _applyCoupon(
      coupon: coupon,
      subtotal: subtotal,
      now: DateTime.now(),
    );
  }

  Future<bool> reduceStock(Map<String, int> quantitiesByProductId) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final productRefs = <String, DocumentReference<Map<String, dynamic>>>{
          for (final id in quantitiesByProductId.keys) id: _products.doc(id),
        };
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

  /// Atomically reduce stock and create the order.
  ///
  /// Prevents the inconsistent state where stock is reduced but order write fails.
  Future<OrderModel> placeOrderAtomic({
    required OrderModel order,
    required Map<String, int> quantitiesByProductId,
  }) async {
    final authEmail = _auth.currentUser?.email?.trim().toLowerCase();
    if (authEmail == null || authEmail.isEmpty) {
      throw StateError(
        'Phiên đăng nhập không có email. Vui lòng đăng nhập lại.',
      );
    }

    // Always bind order to Auth token email (rules compare against token.email).
    final normalized = order.copyWith(
      userEmail: authEmail,
      statusHistory: order.statusHistory
          .map(
            (e) => OrderStatusEvent(
              status: e.status,
              at: e.at,
              byEmail: e.byEmail.trim().isEmpty
                  ? authEmail
                  : e.byEmail.trim().toLowerCase(),
              note: e.note,
            ),
          )
          .toList(),
    );

    final orderRef = _orders.doc(normalized.id);
    final couponCode = Coupon.normalizeCode(normalized.couponCode);
    final couponRef = couponCode.isEmpty ? null : _coupons.doc(couponCode);
    late OrderModel committedOrder;

    await _firestore.runTransaction((transaction) async {
      // All reads first (Firestore transaction requirement).
      final productRefs = <String, DocumentReference<Map<String, dynamic>>>{
        for (final id in quantitiesByProductId.keys) id: _products.doc(id),
      };
      final snapshots = <String, DocumentSnapshot<Map<String, dynamic>>>{};
      for (final entry in productRefs.entries) {
        snapshots[entry.key] = await transaction.get(entry.value);
      }
      final couponSnapshot = couponRef == null
          ? null
          : await transaction.get(couponRef);

      for (final entry in quantitiesByProductId.entries) {
        final snapshot = snapshots[entry.key];
        final data = snapshot?.data();
        if (snapshot == null || !snapshot.exists || data == null) {
          throw StateError('Sản phẩm không tồn tại (${entry.key}).');
        }
        final product = Product.fromMap({'id': snapshot.id, ...data});
        if (!product.canBePurchased ||
            product.stockQuantity < entry.value ||
            entry.value <= 0) {
          throw StateError(
            'Không đủ tồn kho cho "${product.name}" '
            '(còn ${product.stockQuantity}, cần ${entry.value}).',
          );
        }
      }

      final liveLines = <OrderLine>[];
      for (final entry in quantitiesByProductId.entries) {
        final ref = productRefs[entry.key]!;
        final snapshot = snapshots[entry.key]!;
        final product = Product.fromMap({
          'id': snapshot.id,
          ...snapshot.data()!,
        });
        liveLines.add(
          OrderLine(
            productId: product.id,
            name: product.name,
            unitPrice: product.price,
            quantity: entry.value,
            imageUrl: product.imageUrl,
            category: product.category.key,
            sellerId: product.sellerId,
            sellerName: product.sellerName,
          ),
        );
        transaction.update(ref, {
          'stockQuantity': product.stockQuantity - entry.value,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      final liveSubtotal = liveLines.fold<double>(
        0,
        (total, item) => total + item.totalPrice,
      );
      var discountAmount = 0.0;
      var appliedCouponCode = '';
      if (couponRef != null) {
        if (couponSnapshot == null ||
            !couponSnapshot.exists ||
            couponSnapshot.data() == null) {
          throw StateError('Mã giảm giá không tồn tại.');
        }
        final coupon = Coupon.fromMap({
          'code': couponSnapshot.id,
          ...couponSnapshot.data()!,
        });
        final applied = _applyCoupon(
          coupon: coupon,
          subtotal: liveSubtotal,
          now: DateTime.now(),
        );
        discountAmount = applied.discountAmount;
        appliedCouponCode = applied.code;
        transaction.update(couponRef, {
          'usedCount': coupon.usedCount + 1,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      final liveTotal = (liveSubtotal - discountAmount).clamp(0, liveSubtotal);
      committedOrder = normalized.copyWith(
        items: liveLines,
        subtotalAmount: liveSubtotal,
        discountAmount: discountAmount,
        couponCode: appliedCouponCode,
        totalAmount: liveTotal.toDouble(),
      );
      transaction.set(orderRef, committedOrder.toMap());

      final linesBySeller = <String, List<OrderLine>>{};
      for (final line in liveLines) {
        if (line.sellerId.isEmpty) continue;
        (linesBySeller[line.sellerId] ??= []).add(line);
      }
      for (final entry in linesBySeller.entries) {
        final fulfillmentRef = _sellerFulfillments.doc(
          '${normalized.id}_${entry.key}',
        );
        final first = entry.value.first;
        transaction.set(
          fulfillmentRef,
          SellerFulfillment(
            id: fulfillmentRef.id,
            orderId: normalized.id,
            sellerId: entry.key,
            sellerName: first.sellerName,
            customerEmail: authEmail,
            customerName: normalized.customerName,
            phone: normalized.phone,
            shippingAddress: normalized.shippingAddress,
            items: entry.value,
            status: OrderStatus.placed,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ).toMap(),
        );
      }
    });

    return committedOrder;
  }

  /// Cancel order and restore stock in one transaction (idempotent via stockRestored).
  Future<OrderModel> cancelOrderAtomic({
    required OrderModel order,
    required String actorEmail,
    required String note,
  }) async {
    if (order.status == OrderStatus.cancelled) {
      throw StateError('Đơn đã bị hủy trước đó.');
    }
    if (order.stockRestored) {
      throw StateError('Đơn này đã hoàn kho trước đó.');
    }

    final orderRef = _orders.doc(order.id);
    final productIds = order.items
        .map((e) => e.productId)
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList();

    final when = DateTime.now();
    late OrderModel committedOrder;

    await _firestore.runTransaction((transaction) async {
      final orderSnap = await transaction.get(orderRef);
      if (!orderSnap.exists || orderSnap.data() == null) {
        throw StateError('Không tìm thấy đơn hàng.');
      }
      final live = OrderModel.fromMap({
        'id': orderSnap.id,
        ...orderSnap.data()!,
      });
      if (live.status == OrderStatus.cancelled || live.stockRestored) {
        throw StateError('Đơn đã hủy hoặc đã hoàn kho.');
      }

      final productRefs = <String, DocumentReference<Map<String, dynamic>>>{
        for (final id in productIds) id: _products.doc(id),
      };
      final snapshots = <String, DocumentSnapshot<Map<String, dynamic>>>{};
      for (final entry in productRefs.entries) {
        snapshots[entry.key] = await transaction.get(entry.value);
      }

      // Aggregate qty per product (multi-line same product).
      final restoreByProduct = <String, int>{};
      for (final line in live.items) {
        if (line.productId.isEmpty || line.quantity <= 0) continue;
        restoreByProduct[line.productId] =
            (restoreByProduct[line.productId] ?? 0) + line.quantity;
      }

      for (final entry in restoreByProduct.entries) {
        final snap = snapshots[entry.key];
        final data = snap?.data();
        if (snap == null || !snap.exists || data == null) {
          // Product removed — skip restock for that line only.
          continue;
        }
        final product = Product.fromMap({'id': snap.id, ...data});
        transaction.update(productRefs[entry.key]!, {
          'stockQuantity': product.stockQuantity + entry.value,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      // Re-build cancelled from live so we don't clobber concurrent edits.
      final finalCancelled = live.withStatusTransition(
        next: OrderStatus.cancelled,
        byEmail: actorEmail.trim().toLowerCase(),
        note: note,
        at: when,
        stockRestored: true,
      );
      committedOrder = finalCancelled;
      transaction.set(
        orderRef,
        finalCancelled.toMap(),
        SetOptions(merge: true),
      );
    });

    return committedOrder;
  }

  Stream<List<SellerFulfillment>> watchSellerFulfillments(String sellerId) =>
      _sellerFulfillments
          .where('sellerId', isEqualTo: sellerId)
          .snapshots()
          .map((snapshot) {
            final values = snapshot.docs
                .map(
                  (doc) =>
                      SellerFulfillment.fromMap({'id': doc.id, ...doc.data()}),
                )
                .toList();
            values.sort((a, b) => b.createdAt.compareTo(a.createdAt));
            return values;
          });

  Future<void> updateSellerFulfillmentStatus({
    required SellerFulfillment fulfillment,
    required OrderStatus next,
  }) async {
    if (next != fulfillment.status.nextStaffStatus) {
      throw StateError('Chuyển trạng thái giao hàng không hợp lệ.');
    }
    await _sellerFulfillments.doc(fulfillment.id).update({
      'status': next.key,
      'updatedAt': FieldValue.serverTimestamp(),
    });
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

  AppliedCoupon _applyCoupon({
    required Coupon coupon,
    required double subtotal,
    required DateTime now,
  }) {
    if (!coupon.isAvailable(now)) {
      throw StateError('Mã giảm giá đã hết hạn hoặc không còn hiệu lực.');
    }
    if (subtotal < coupon.minOrderAmount) {
      throw StateError(
        'Mã ${coupon.code} yêu cầu đơn tối thiểu '
        '${coupon.minOrderAmount.toStringAsFixed(0)}.',
      );
    }
    final discount = coupon.discountFor(subtotal);
    if (discount <= 0) {
      throw StateError('Mã giảm giá không áp dụng được cho đơn này.');
    }
    return AppliedCoupon(
      code: coupon.code,
      description: coupon.description.trim().isEmpty
          ? coupon.type.label
          : coupon.description,
      discountAmount: discount,
    );
  }
}
