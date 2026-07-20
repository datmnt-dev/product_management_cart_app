# Product Management Cart App

Flutter app quản lý sản phẩm, giỏ hàng, đặt hàng, phân quyền và thống kê doanh thu.

## Tài khoản demo

- Admin: `admin@store.local` / `123456`
- Manager: `manager@store.local` / `123456`
- Customer: `customer@store.local` / `123456`

## Chức năng chính

- Auth local, ghi nhớ đăng nhập và phân quyền theo vai trò.
- CRUD sản phẩm với SKU, danh mục, giá, tồn kho, trạng thái và ảnh.
- Giỏ hàng có kiểm tra tồn kho.
- Checkout tạo đơn hàng và tự động trừ tồn kho.
- Lịch sử đơn hàng theo khách hàng.
- Dashboard doanh thu, thống kê đơn hàng, xu hướng bán và sản phẩm bán chạy.

## Hướng database đề xuất

App đang dùng Firebase Auth + Cloud Firestore cho dữ liệu chính. Hive chỉ còn là phần service cũ trong source để tham khảo/migrate, không còn được wiring trong `main.dart`.

MongoDB vẫn dùng được nhưng nên đi qua backend API riêng, không nên cho Flutter app kết nối Mongo trực tiếp. Với phạm vi hiện tại, Firebase là backend chính cho auth, catalog, checkout và báo cáo doanh thu.

## Firebase phases

Phase 1 - Firebase app config:

```powershell
flutterfire configure --project=product-management-cart-app --platforms=android,ios,web,windows
flutter pub add firebase_core firebase_auth cloud_firestore
```

Phase 2 - Firestore database and rules:

```powershell
firebase firestore:databases:create "(default)" --project product-management-cart-app --location=asia-southeast1 --edition=standard
firebase deploy --only firestore:rules --project product-management-cart-app
```

Phase 3 - Seed full demo data:

```powershell
firebase deploy --only firestore:rules --project product-management-cart-app --config firebase.seed.json
node tools\seed_firestore.js
firebase deploy --only firestore:rules --project product-management-cart-app
node tools\verify_firestore_seed.js
```

Seed hiện có 4 users, 10 products, 6 orders và 1 seedRuns document. Dữ liệu phủ đủ vai trò, danh mục sản phẩm, trạng thái active/draft/archived, hết hàng/tồn kho thấp/không ảnh, lịch sử đơn hôm nay/tháng/năm/năm trước cho dashboard.
