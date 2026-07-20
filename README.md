# StoreFlow — Product Management Cart App

Flutter app quản lý sản phẩm, giỏ hàng, đặt hàng, phân quyền và thống kê doanh thu.

| | |
| --- | --- |
| **UI brand** | StoreFlow |
| **Package name** | `product_management_cart_app` |
| **Backend** | Firebase Auth + Cloud Firestore |
| **Platforms** | Android, iOS, Web, Windows |

## Tài khoản demo (lab only)

| Role | Email | Password |
| --- | --- | --- |
| Admin | `admin@store.local` | `123456` |
| Manager | `manager@store.local` | `123456` |
| Customer | `customer@store.local` | `123456` |
| Edge customer | `edge.customer@store.local` | `123456` |

> Chỉ dùng cho môi trường demo / lab. Không dùng mật khẩu demo trên production.

## Phân quyền & điều hướng (shell)

App dùng `StatefulShellRoute` + bottom `NavigationBar` (rail trên màn rộng). Tab theo role:

| Role | Tabs |
| --- | --- |
| **Customer** | Cửa hàng · Giỏ · Đơn |
| **Manager** | Kho hàng · Thống kê |
| **Admin** | Kho hàng · Thống kê · Quyền |

- Staff **không** có tab Đơn / Giỏ — đơn hàng staff xem trong **Thống kê**.
- Chi tiết / form sản phẩm mở trên root navigator (không dual bottom bar).
- Customer chỉ thấy sản phẩm **active** (list + deep link UX).

## Chức năng chính

- Firebase Auth (đăng ký/đăng nhập), remember me, profile sheet logout.
- CRUD sản phẩm (staff): SKU, danh mục, giá, tồn kho, trạng thái, URL ảnh.
- Giỏ hàng session-local + kiểm tra tồn kho.
- Checkout Firestore transaction trừ kho → tạo order (status **Đã gửi đơn**) → clear cart.
- Tracking đơn: `placed → confirmed → preparing → shipping → delivered` (+ `cancelled`).
- Customer: hủy sớm, xác nhận đã nhận khi đang giao; Staff: xác nhận nhận đơn và tiến trạng thái trên Thống kê.
- Lịch sử đơn (customer) lọc theo status; dashboard doanh thu (staff) loại đơn hủy.
- Ma trận phân quyền (admin).

## Backend & seed

Backend chính: **Firebase Auth + Cloud Firestore**. Legacy Hive `LocalDatabase` đã gỡ.

### Chạy seed demo

```powershell
firebase deploy --only firestore:rules --project product-management-cart-app --config firebase.seed.json
node tools\seed_firestore.js
firebase deploy --only firestore:rules --project product-management-cart-app
node tools\verify_firestore_seed.js
```

Seed: 4 users, 10 products, 6 orders, 1 `seedRuns` document (đủ edge case demo).

## Chạy app

```powershell
flutter pub get
flutter run -d chrome
# hoặc
flutter run -d windows
```

## Kiểm tra

```powershell
flutter analyze
flutter test
```

## Cấu trúc (tóm tắt)

```
lib/
  app/           # router, shell navigator keys, ProductLabApp
  core/theme/    # design tokens + ThemeData light/dark
  data/          # models, FirestoreDatabase
  features/      # auth, products, cart, orders, statistics, roles
  shared/        # widgets, components, shell
  state/         # Auth/Product/Cart/Order controllers
```

## Ghi chú kỹ thuật

- Theme: `ThemeMode.system` (light + dark tokens).
- Cart không persist Firestore (session).
- Checkout lock chống double-tap; stock transaction trước khi tạo order.
- UI ẩn draft/archived với customer là **UX-only**; rules product read vẫn `signedIn()`.
