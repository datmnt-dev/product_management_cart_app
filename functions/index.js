"use strict";

const {onCall, HttpsError} = require("firebase-functions/v2/https");
const admin = require("firebase-admin");

admin.initializeApp();

const db = admin.firestore();
const FieldValue = admin.firestore.FieldValue;

const ALLOWED_PAYMENT_METHODS = new Set([
  "cash_on_delivery",
  "bank_transfer",
  "mock_wallet",
]);
const SHOPPER_ROLES = new Set(["customer", "seller"]);

exports.placeOrder = onCall({region: "us-central1"}, async (request) => {
  const uid = request.auth && request.auth.uid;
  const email = normalizeEmail(request.auth && request.auth.token.email);
  if (!uid || !email) {
    throw new HttpsError("unauthenticated", "Vui lòng đăng nhập lại.");
  }

  const payload = request.data || {};
  const rawItems = Array.isArray(payload.items) ? payload.items : [];
  const items = normalizeItems(rawItems);
  if (items.length === 0) {
    throw new HttpsError("invalid-argument", "Giỏ hàng đang trống.");
  }

  const paymentMethod = String(payload.paymentMethod || "cash_on_delivery");
  if (!ALLOWED_PAYMENT_METHODS.has(paymentMethod)) {
    throw new HttpsError("invalid-argument", "Phương thức thanh toán không hợp lệ.");
  }

  const userRef = db.collection("users").doc(uid);
  const userSnap = await userRef.get();
  if (!userSnap.exists) {
    throw new HttpsError("failed-precondition", "Không tìm thấy hồ sơ người dùng.");
  }
  const user = userSnap.data() || {};
  if (!SHOPPER_ROLES.has(String(user.role || ""))) {
    throw new HttpsError("permission-denied", "Tài khoản này không có quyền mua hàng.");
  }

  const now = admin.firestore.Timestamp.now();
  const orderRef = db.collection("orders").doc(`order-${Date.now()}-${uid.slice(0, 8)}`);
  const couponCode = normalizeCoupon(payload.couponCode);
  const couponRef = couponCode ? db.collection("coupons").doc(couponCode) : null;

  let committedOrder = null;

  await db.runTransaction(async (tx) => {
    const productRefs = items.map((item) => db.collection("products").doc(item.productId));
    const productSnaps = [];
    for (const ref of productRefs) {
      productSnaps.push(await tx.get(ref));
    }
    const couponSnap = couponRef ? await tx.get(couponRef) : null;

    const liveLines = [];
    for (let index = 0; index < items.length; index += 1) {
      const requested = items[index];
      const snap = productSnaps[index];
      if (!snap.exists) {
        throw new HttpsError("failed-precondition", `Sản phẩm không tồn tại (${requested.productId}).`);
      }
      const product = snap.data() || {};
      const stockQuantity = toInt(product.stockQuantity);
      if (product.status !== "active" || stockQuantity < requested.quantity) {
        throw new HttpsError(
          "failed-precondition",
          `Không đủ tồn kho cho "${String(product.name || snap.id)}".`,
        );
      }
      const unitPrice = toMoney(product.price);
      if (unitPrice <= 0) {
        throw new HttpsError("failed-precondition", `Giá sản phẩm "${String(product.name || snap.id)}" không hợp lệ.`);
      }
      liveLines.push({
        productId: snap.id,
        name: String(product.name || ""),
        unitPrice,
        quantity: requested.quantity,
        imageUrl: String(product.imageUrl || ""),
        category: String(product.category || "other"),
        sellerId: String(product.sellerId || ""),
        sellerName: String(product.sellerName || ""),
      });
      tx.update(productRefs[index], {
        stockQuantity: stockQuantity - requested.quantity,
        updatedAt: FieldValue.serverTimestamp(),
      });
    }

    const subtotalAmount = roundMoney(
      liveLines.reduce((total, line) => total + line.unitPrice * line.quantity, 0),
    );
    const couponResult = couponSnap ? applyCoupon(couponSnap, subtotalAmount, now.toDate()) : {
      code: "",
      discountAmount: 0,
    };
    if (couponRef && couponSnap) {
      tx.update(couponRef, {
        usedCount: toInt((couponSnap.data() || {}).usedCount) + 1,
        updatedAt: FieldValue.serverTimestamp(),
      });
    }
    const totalAmount = roundMoney(Math.max(0, subtotalAmount - couponResult.discountAmount));
    const paymentStatus = paymentMethod === "mock_wallet" ? "paid" : "unpaid";

    committedOrder = {
      id: orderRef.id,
      userEmail: email,
      items: liveLines,
      subtotalAmount,
      discountAmount: couponResult.discountAmount,
      couponCode: couponResult.code,
      totalAmount,
      createdAt: now,
      updatedAt: now,
      status: "placed",
      statusHistory: [{
        status: "placed",
        at: now,
        byEmail: email,
        note: "Khách đã gửi đơn hàng",
      }],
      stockRestored: false,
      customerName: cleanText(payload.customerName) || String(user.fullName || ""),
      phone: cleanText(payload.phone),
      shippingAddress: cleanText(payload.shippingAddress),
      note: cleanText(payload.note),
      paymentMethod,
      paymentStatus,
    };

    tx.set(orderRef, committedOrder);

    const linesBySeller = groupLinesBySeller(liveLines);
    for (const [sellerId, sellerLines] of Object.entries(linesBySeller)) {
      const fulfillmentRef = db.collection("sellerFulfillments").doc(`${orderRef.id}_${sellerId}`);
      tx.set(fulfillmentRef, {
        id: fulfillmentRef.id,
        orderId: orderRef.id,
        sellerId,
        sellerName: sellerLines[0].sellerName,
        customerEmail: email,
        customerName: committedOrder.customerName,
        phone: committedOrder.phone,
        shippingAddress: committedOrder.shippingAddress,
        items: sellerLines,
        status: "placed",
        createdAt: now,
        updatedAt: now,
      });
    }
  });

  return {order: serializeOrder(committedOrder)};
});

function normalizeItems(rawItems) {
  const quantities = new Map();
  for (const raw of rawItems) {
    const productId = cleanText(raw && raw.productId);
    const quantity = toInt(raw && raw.quantity);
    if (!productId || quantity <= 0 || quantity > 99) continue;
    quantities.set(productId, (quantities.get(productId) || 0) + quantity);
  }
  return Array.from(quantities.entries()).map(([productId, quantity]) => ({
    productId,
    quantity,
  }));
}

function applyCoupon(couponSnap, subtotalAmount, now) {
  if (!couponSnap.exists) {
    throw new HttpsError("failed-precondition", "Mã giảm giá không tồn tại.");
  }
  const coupon = couponSnap.data() || {};
  const usageLimit = toInt(coupon.usageLimit);
  const usedCount = toInt(coupon.usedCount);
  const startsAt = toDate(coupon.startsAt);
  const expiresAt = toDate(coupon.expiresAt);
  const active = coupon.isActive !== false;
  const hasUsageLeft = usageLimit <= 0 || usedCount < usageLimit;
  if (!active || !hasUsageLeft || now < startsAt || now > expiresAt) {
    throw new HttpsError("failed-precondition", "Mã giảm giá đã hết hạn hoặc không còn hiệu lực.");
  }
  const minOrderAmount = toMoney(coupon.minOrderAmount);
  if (subtotalAmount < minOrderAmount) {
    throw new HttpsError("failed-precondition", `Mã ${couponSnap.id} yêu cầu đơn tối thiểu ${minOrderAmount}.`);
  }
  const value = toMoney(coupon.value);
  const maxDiscountAmount = toMoney(coupon.maxDiscountAmount);
  const rawDiscount = coupon.type === "fixed_amount" ? value : subtotalAmount * value / 100;
  const capped = maxDiscountAmount > 0 ? Math.min(rawDiscount, maxDiscountAmount) : rawDiscount;
  const discountAmount = roundMoney(Math.max(0, Math.min(capped, subtotalAmount)));
  if (discountAmount <= 0) {
    throw new HttpsError("failed-precondition", "Mã giảm giá không áp dụng được cho đơn này.");
  }
  return {code: couponSnap.id, discountAmount};
}

function groupLinesBySeller(lines) {
  return lines.reduce((groups, line) => {
    if (!line.sellerId) return groups;
    groups[line.sellerId] = groups[line.sellerId] || [];
    groups[line.sellerId].push(line);
    return groups;
  }, {});
}

function serializeOrder(order) {
  return {
    ...order,
    createdAt: order.createdAt.toDate().toISOString(),
    updatedAt: order.updatedAt.toDate().toISOString(),
    statusHistory: order.statusHistory.map((event) => ({
      ...event,
      at: event.at.toDate().toISOString(),
    })),
  };
}

function normalizeEmail(value) {
  return cleanText(value).toLowerCase();
}

function normalizeCoupon(value) {
  return cleanText(value).toUpperCase().replace(/\s+/g, "");
}

function cleanText(value) {
  return String(value || "").trim();
}

function toInt(value) {
  const parsed = Number.parseInt(String(value || "0"), 10);
  return Number.isFinite(parsed) ? parsed : 0;
}

function toMoney(value) {
  const parsed = Number(value || 0);
  return Number.isFinite(parsed) ? parsed : 0;
}

function roundMoney(value) {
  return Math.round(value * 100) / 100;
}

function toDate(value) {
  if (value && typeof value.toDate === "function") return value.toDate();
  const parsed = new Date(value);
  return Number.isNaN(parsed.getTime()) ? new Date(0) : parsed;
}
