const fs = require("fs");
const path = require("path");

const projectId = "product-management-cart-app";
const root = path.resolve(__dirname, "..");
const firebaseOptions = fs.readFileSync(
  path.join(root, "lib", "firebase_options.dart"),
  "utf8",
);
const apiKeyMatch = firebaseOptions.match(/static const FirebaseOptions web = FirebaseOptions\([\s\S]*?apiKey: '([^']+)'/);

if (!apiKeyMatch) {
  throw new Error("Cannot find Firebase Web API key in lib/firebase_options.dart");
}

const apiKey = apiKeyMatch[1];
const authBase = `https://identitytoolkit.googleapis.com/v1`;
const firestoreBase = `https://firestore.googleapis.com/v1/projects/${projectId}/databases/(default)/documents`;

const now = new Date();
const daysAgo = (days) => {
  const value = new Date(now);
  value.setDate(value.getDate() - days);
  return value;
};
const monthsAgo = (months) => {
  const value = new Date(now);
  value.setMonth(value.getMonth() - months);
  return value;
};

const accounts = [
  {
    fullName: "Admin Store",
    email: "admin@store.local",
    password: "123456",
    role: "admin",
  },
  {
    fullName: "Manager Store",
    email: "manager@store.local",
    password: "123456",
    role: "manager",
  },
  {
    fullName: "Customer Demo",
    email: "customer@store.local",
    password: "123456",
    role: "customer",
  },
  {
    fullName: "Edge Case Customer",
    email: "edge.customer@store.local",
    password: "123456",
    role: "customer",
  },
];

const products = [
  {
    id: "seed-iphone-15-pro",
    sku: "PHONE-IP15P-001",
    name: "iPhone 15 Pro Demo",
    description: "Điện thoại flagship, khung titanium, camera tốt cho edge case giá cao.",
    category: "phone",
    price: 28990000,
    stockQuantity: 12,
    status: "active",
    imageUrl: "https://images.unsplash.com/photo-1695048133142-1a20484d2569?auto=format&fit=crop&w=900&q=80",
    createdAt: monthsAgo(4),
    updatedAt: daysAgo(1),
  },
  {
    id: "seed-android-budget",
    sku: "PHONE-AND-LOW-002",
    name: "Android Budget A1",
    description: "Điện thoại phổ thông, giá thấp để kiểm tra sort tăng dần.",
    category: "phone",
    price: 2490000,
    stockQuantity: 40,
    status: "active",
    imageUrl: "https://images.unsplash.com/photo-1511707171634-5f897ff02aa9?auto=format&fit=crop&w=900&q=80",
    createdAt: monthsAgo(3),
    updatedAt: daysAgo(2),
  },
  {
    id: "seed-macbook-air",
    sku: "LAP-MBA-003",
    name: "MacBook Air M3 Demo",
    description: "Laptop mỏng nhẹ, pin lâu, dùng kiểm tra danh mục laptop.",
    category: "laptop",
    price: 27990000,
    stockQuantity: 7,
    status: "active",
    imageUrl: "https://images.unsplash.com/photo-1517336714731-489689fd1ca8?auto=format&fit=crop&w=900&q=80",
    createdAt: monthsAgo(2),
    updatedAt: daysAgo(3),
  },
  {
    id: "seed-gaming-laptop-low-stock",
    sku: "LAP-GAME-LOW-004",
    name: "Rift Gaming Laptop",
    description: "Laptop gaming tồn kho thấp để kiểm tra giới hạn số lượng giỏ hàng.",
    category: "laptop",
    price: 35990000,
    stockQuantity: 1,
    status: "active",
    imageUrl: "https://images.unsplash.com/photo-1603302576837-37561b2e2302?auto=format&fit=crop&w=900&q=80",
    createdAt: monthsAgo(2),
    updatedAt: daysAgo(4),
  },
  {
    id: "seed-headphone",
    sku: "ACC-ANC-005",
    name: "Breeze ANC Headphone",
    description: "Tai nghe chống ồn chủ động, âm trầm chắc, sạc USB-C.",
    category: "accessory",
    price: 2490000,
    stockQuantity: 18,
    status: "active",
    imageUrl: "https://images.unsplash.com/photo-1505740420928-5e560c06d30e?auto=format&fit=crop&w=900&q=80",
    createdAt: monthsAgo(1),
    updatedAt: daysAgo(5),
  },
  {
    id: "seed-watch-out-of-stock",
    sku: "ACC-WATCH-OOS-006",
    name: "Orbit Smart Watch Sold Out",
    description: "Sản phẩm hết hàng để kiểm tra trạng thái không thể thêm vào giỏ.",
    category: "accessory",
    price: 1890000,
    stockQuantity: 0,
    status: "active",
    imageUrl: "https://images.unsplash.com/photo-1523275335684-37898b6baf30?auto=format&fit=crop&w=900&q=80",
    createdAt: monthsAgo(1),
    updatedAt: daysAgo(6),
  },
  {
    id: "seed-air-fryer",
    sku: "HOME-FRY-007",
    name: "KitchenPro Air Fryer",
    description: "Nồi chiên không dầu gia dụng, kiểm tra category gia dụng.",
    category: "home",
    price: 3290000,
    stockQuantity: 15,
    status: "active",
    imageUrl: "https://images.unsplash.com/photo-1647606151059-16c75ef021bb?auto=format&fit=crop&w=900&q=80",
    createdAt: daysAgo(20),
    updatedAt: daysAgo(7),
  },
  {
    id: "seed-fan-draft",
    sku: "HOME-DRAFT-008",
    name: "Silent Fan Draft",
    description: "Bản nháp để manager/admin thấy trạng thái chưa bán.",
    category: "home",
    price: 790000,
    stockQuantity: 22,
    status: "draft",
    imageUrl: "https://images.unsplash.com/photo-1628359355624-855775b5c9c4?auto=format&fit=crop&w=900&q=80",
    createdAt: daysAgo(15),
    updatedAt: daysAgo(8),
  },
  {
    id: "seed-backpack-no-image",
    sku: "ACC-NOIMG-009",
    name: "Metro Work Backpack No Image",
    description: "Không có ảnh để kiểm tra fallback image widget.",
    category: "accessory",
    price: 890000,
    stockQuantity: 31,
    status: "active",
    imageUrl: "",
    createdAt: daysAgo(10),
    updatedAt: daysAgo(9),
  },
  {
    id: "seed-camera-archived",
    sku: "OTHER-ARCH-010",
    name: "Nova Pocket Camera Archived",
    description: "Sản phẩm ngừng bán để kiểm tra trạng thái archived.",
    category: "other",
    price: 5690000,
    stockQuantity: 4,
    status: "archived",
    imageUrl: "https://images.unsplash.com/photo-1516035069371-29a1b244cc32?auto=format&fit=crop&w=900&q=80",
    createdAt: monthsAgo(6),
    updatedAt: daysAgo(30),
  },
];

const orderTemplates = [
  {
    id: "seed-order-today-mixed",
    userEmail: "customer@store.local",
    createdAt: now,
    status: "placed",
    items: [
      line("seed-android-budget", 2),
      line("seed-headphone", 1),
    ],
  },
  {
    id: "seed-order-yesterday-low-stock",
    userEmail: "customer@store.local",
    createdAt: daysAgo(1),
    status: "confirmed",
    items: [
      line("seed-gaming-laptop-low-stock", 1),
    ],
  },
  {
    id: "seed-order-this-month-home",
    userEmail: "edge.customer@store.local",
    createdAt: daysAgo(8),
    status: "preparing",
    items: [
      line("seed-air-fryer", 1),
      line("seed-backpack-no-image", 2),
    ],
  },
  {
    id: "seed-order-previous-month",
    userEmail: "customer@store.local",
    createdAt: monthsAgo(1),
    status: "shipping",
    items: [
      line("seed-iphone-15-pro", 1),
      line("seed-headphone", 2),
    ],
  },
  {
    id: "seed-order-this-year-expensive",
    userEmail: "edge.customer@store.local",
    createdAt: monthsAgo(3),
    status: "delivered",
    items: [
      line("seed-macbook-air", 1),
    ],
  },
  {
    id: "seed-order-last-year",
    userEmail: "customer@store.local",
    createdAt: new Date(now.getFullYear() - 1, 10, 15, 9, 30, 0),
    status: "cancelled",
    items: [
      line("seed-android-budget", 1),
      line("seed-air-fryer", 1),
    ],
  },
];

function line(productId, quantity) {
  return { productId, quantity };
}

function buildOrder(template) {
  const items = template.items.map((item) => {
    const product = products.find((value) => value.id === item.productId);
    if (!product) {
      throw new Error(`Missing product for order line: ${item.productId}`);
    }
    return {
      productId: product.id,
      name: product.name,
      unitPrice: product.price,
      quantity: item.quantity,
      imageUrl: product.imageUrl,
    };
  });
  const totalAmount = items.reduce(
    (total, item) => total + item.unitPrice * item.quantity,
    0,
  );
  const status = template.status || "placed";
  const createdAt = template.createdAt;
  const statusHistory = buildStatusHistory(status, createdAt, template.userEmail);
  return {
    id: template.id,
    userEmail: template.userEmail,
    items,
    totalAmount,
    createdAt,
    updatedAt: statusHistory[statusHistory.length - 1].at,
    status,
    statusHistory,
  };
}

function buildStatusHistory(status, createdAt, userEmail) {
  const pipeline = ["placed", "confirmed", "preparing", "shipping", "delivered"];
  if (status === "cancelled") {
    return [
      {
        status: "placed",
        at: createdAt,
        byEmail: userEmail,
        note: "Khách đã gửi đơn hàng",
      },
      {
        status: "cancelled",
        at: new Date(createdAt.getTime() + 60 * 60 * 1000),
        byEmail: userEmail,
        note: "Khách hủy đơn",
      },
    ];
  }
  const end = pipeline.indexOf(status);
  return pipeline.slice(0, Math.max(end, 0) + 1).map((step, index) => ({
    status: step,
    at: new Date(createdAt.getTime() + index * 2 * 60 * 60 * 1000),
    byEmail: index === 0 ? userEmail : "admin@store.local",
    note:
      step === "placed"
        ? "Khách đã gửi đơn hàng"
        : step === "confirmed"
          ? "Shop xác nhận đã nhận đơn"
          : step === "preparing"
            ? "Shop bắt đầu chuẩn bị hàng"
            : step === "shipping"
              ? "Shop bàn giao vận chuyển"
              : "Đã giao / hoàn thành",
  }));
}

async function main() {
  console.log("Seeding Firebase Auth accounts...");
  const seededAccounts = [];
  for (const account of accounts) {
    seededAccounts.push(await ensureAccount(account));
  }

  const admin = seededAccounts.find((account) => account.role === "admin");
  if (!admin) {
    throw new Error("Admin account was not created.");
  }

  console.log("Writing Firestore users...");
  for (const account of seededAccounts) {
    await writeDocument(`users/${account.uid}`, admin.idToken, {
      id: account.uid,
      fullName: account.fullName,
      email: account.email,
      passwordHash: "",
      role: account.role,
      createdAt: account.createdAt,
    });
  }

  console.log("Writing Firestore products...");
  for (const product of products) {
    await writeDocument(`products/${product.id}`, admin.idToken, product);
  }

  console.log("Writing Firestore orders...");
  for (const order of orderTemplates.map(buildOrder)) {
    await writeDocument(`orders/${order.id}`, admin.idToken, order);
  }

  await writeDocument(`seedRuns/product-management-cart-app`, admin.idToken, {
    id: "product-management-cart-app",
    seededAt: now,
    accountCount: seededAccounts.length,
    productCount: products.length,
    orderCount: orderTemplates.length,
    notes: "Seed data covers auth roles, product CRUD states, cart stock edges, checkout history, and revenue filters.",
  });

  console.log("Seed complete.");
  console.log("Demo password for all seeded accounts: 123456");
}

async function ensureAccount(account) {
  const payload = {
    email: account.email,
    password: account.password,
    returnSecureToken: true,
  };
  const signUp = await postJson(`${authBase}/accounts:signUp?key=${apiKey}`, payload);

  let authData = signUp;
  if (signUp.error?.message === "EMAIL_EXISTS") {
    authData = await postJson(
      `${authBase}/accounts:signInWithPassword?key=${apiKey}`,
      payload,
    );
  }
  if (authData.error) {
    throw new Error(`${account.email}: ${authData.error.message}`);
  }

  await postJson(`${authBase}/accounts:update?key=${apiKey}`, {
    idToken: authData.idToken,
    displayName: account.fullName,
    returnSecureToken: false,
  });

  return {
    ...account,
    uid: authData.localId,
    idToken: authData.idToken,
    createdAt: now,
  };
}

async function writeDocument(documentPath, idToken, data) {
  const response = await fetch(`${firestoreBase}/${documentPath}`, {
    method: "PATCH",
    headers: {
      Authorization: `Bearer ${idToken}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({ fields: toFirestoreFields(data) }),
  });

  if (!response.ok) {
    const body = await response.text();
    throw new Error(`${documentPath}: ${response.status} ${body}`);
  }
}

async function postJson(url, payload) {
  const response = await fetch(url, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(payload),
  });
  return response.json();
}

function toFirestoreFields(data) {
  return Object.fromEntries(
    Object.entries(data).map(([key, value]) => [key, toFirestoreValue(value)]),
  );
}

function toFirestoreValue(value) {
  if (value instanceof Date) {
    return { timestampValue: value.toISOString() };
  }
  if (Array.isArray(value)) {
    return { arrayValue: { values: value.map(toFirestoreValue) } };
  }
  if (value && typeof value === "object") {
    return { mapValue: { fields: toFirestoreFields(value) } };
  }
  if (typeof value === "number") {
    return Number.isInteger(value)
      ? { integerValue: value.toString() }
      : { doubleValue: value };
  }
  if (typeof value === "boolean") {
    return { booleanValue: value };
  }
  if (value === null || value === undefined) {
    return { nullValue: null };
  }
  return { stringValue: String(value) };
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
