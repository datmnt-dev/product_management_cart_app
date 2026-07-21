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

| Role | Tabs | Ghi chú |
| --- | --- | --- |
| **Customer** | Cửa hàng · Giỏ · Đơn | Chỉ đơn của chính mình |
| **Manager** | Kho · Thống kê | Quản lý sản phẩm, đơn hàng và doanh thu |
| **Admin** | Kho · Thống kê · **Quyền** | Quản trị **toàn hệ thống** |

- Staff **không** có tab Đơn / Giỏ; đơn hàng staff xem và xử lý trong **Thống kê**.
- Customer tab “Đơn” chỉ hiển thị lịch sử đơn của chính customer.
- Chi tiết / form SP: root navigator. Customer chỉ thấy SP **active**.

## Chức năng chính

- Firebase Auth (email/password + Google Sign-In), remember me, profile sheet logout.
- CRUD sản phẩm (staff): SKU, danh mục, giá, tồn kho, trạng thái, URL ảnh.
- Catalog: tìm kiếm, lọc danh mục / còn hàng, sắp xếp (giá, mới, tồn).
- Giỏ hàng **persist** theo user (SharedPreferences) + clamp theo tồn kho live.
- Checkout atomic: trừ kho + tạo đơn; form **họ tên / SĐT / địa chỉ / ghi chú**.
- Payment phase 1: chọn COD / chuyển khoản / ví mock; lưu `paymentMethod` + `paymentStatus`.
- Coupon phase 2: áp mã giảm giá tại checkout; validate ngày hiệu lực, lượt dùng, đơn tối thiểu.
- Tracking: `placed → confirmed → preparing → shipping → delivered` (+ `cancelled`).
- **Hủy đơn hoàn kho** (transaction + `stockRestored`).
- Customer: lịch sử đơn và xác nhận đã nhận khi đơn ở trạng thái `shipping`.
- Staff: xử lý đơn trong **Thống kê** (lọc status, xem email/SĐT), advance/cancel; staff chỉ vận hành tới `shipping`.
- Dashboard: biểu đồ DT, top 8 SP, mix status/payment, DT theo danh mục (chỉ tính đơn đã thanh toán).
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

Seed: 4 users, 10 products, 3 coupons, 9 orders, 1 `seedRuns` document (đủ edge case demo).

## Chạy app

```powershell
flutter pub get
flutter run -d chrome
# hoặc
flutter run -d windows
```

### Google Sign-In trên web

Trong Google Cloud Console, Web OAuth client phải có Authorized JavaScript
origins `http://localhost` và `http://localhost:7357`. Chạy app trên cổng cố
định để origin khớp:

```powershell
flutter run -d chrome --web-hostname localhost --web-port 7357
```

Web dùng Firebase Auth popup; Android và iOS dùng luồng native của
`google_sign_in`.

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
- Cart persist SharedPreferences theo email (không Firestore cart).
- Checkout + cancel restock dùng Firestore transaction; `stockRestored` chống double restock.
- Customer product rules cho phép ± stock (lab trust; client chỉ dùng checkout/cancel).
- UI ẩn draft/archived với customer là **UX-only**; rules product read vẫn `signedIn()`.
