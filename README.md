# EmbraceAI

Ứng dụng nhật ký cảm xúc: ghi lại tâm trạng mỗi ngày, xem lại xu hướng theo thời gian.

Toàn bộ dữ liệu nằm trong SQLite trên máy. App không gọi mạng, không gửi nhật ký đi đâu.

## Chạy thử

```bash
flutter run
```

Kiểm tra trước khi commit:

```bash
flutter analyze && flutter test
```

Build APK:

```bash
flutter build apk --release
```

## Tính năng

- **Ghi nhật ký** — chọn 1 trong 5 mức tâm trạng, viết ghi chú tự do, gắn thẻ (Công việc, Gia đình, Sức khỏe…). Ghi chú có thể để trống nếu chỉ muốn đánh dấu tâm trạng.
- **Gợi ý câu hỏi** — mỗi mức tâm trạng có bộ câu hỏi gợi mở riêng, để không phải nhìn vào ô trống.
- **Ghi lùi ngày** — đổi được ngày giờ của dòng nhật ký, vì thường người ta viết muộn hơn lúc chuyện xảy ra.
- **Thống kê** — chuỗi ngày liên tiếp, đường tâm trạng 14 ngày (chạm để xem từng ngày), phân bố 5 mức, thẻ hay nhắc tới.

## Cấu trúc

```
lib/
├── main.dart                  # Khởi tạo DB, locale tiếng Việt, cắm provider
├── app.dart                   # MaterialApp + localization
├── core/theme.dart            # Màu, typography, khoảng cách dùng chung
├── models/
│   ├── mood.dart              # 5 mức tâm trạng, điểm 1..5, màu
│   └── journal_entry.dart     # Model + chuyển đổi sang/từ hàng DB
├── data/
│   ├── app_database.dart      # Mở SQLite, tạo bảng
│   └── journal_repository.dart# CRUD — UI không chạm thẳng vào SQL
├── state/journal_store.dart   # ChangeNotifier: dữ liệu + toàn bộ thống kê
├── services/
│   └── reflection_service.dart# Sinh câu hỏi gợi mở
├── screens/
│   ├── home_screen.dart       # Khung 2 tab + nút thêm
│   ├── journal_screen.dart    # Danh sách gom theo ngày
│   ├── editor_screen.dart     # Thêm / sửa / xoá
│   ├── entry_detail_screen.dart
│   └── insights_screen.dart   # Thống kê
└── widgets/                   # MoodPicker, EntryCard, biểu đồ, ô số liệu…
```

Luồng dữ liệu một chiều: `AppDatabase` → `JournalRepository` → `JournalStore` → màn hình.
Thống kê tính trực tiếp trong `JournalStore` thay vì truy vấn SQL riêng — một cuốn
nhật ký cá nhân hiếm khi vượt vài nghìn dòng nên giữ hết trong bộ nhớ là đủ nhanh.

## Lược đồ DB

Bảng `entries`, phiên bản 1:

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `id` | INTEGER PK | tự tăng |
| `mood` | INTEGER | điểm 1..5, **không** lưu tên enum để đổi enum sau này vẫn đọc được |
| `note` | TEXT | có thể rỗng |
| `tags` | TEXT | nối bằng `\|` |
| `created_at` | INTEGER | epoch millis |
| `updated_at` | INTEGER | epoch millis |

Đổi lược đồ thì tăng `_version` trong `app_database.dart` và thêm `onUpgrade`.

## Muốn thay gợi ý bằng model AI thật

`ReflectionService.promptFor` hiện trả về câu hỏi soạn sẵn, chạy ngoại tuyến.
Để dùng Claude API: đổi nó thành `Future<String>` và gọi API trong đó — chỗ duy nhất
gọi tới nó là `ReflectionCard`, nên không phải sửa các màn hình khác.

Lưu ý trước khi làm: nội dung nhật ký sẽ phải rời khỏi máy. Nên hỏi ý người dùng
trước, và đừng nhúng API key vào app — gọi qua backend của bạn.

## Kiểm thử

`flutter test` — 26 test: model, store (chuỗi ngày, trung bình, phân bố, thẻ),
và luồng UI thật (ghi mới, sửa, xoá, chuyển tab). `JournalStore` nhận
`JournalRepository` qua constructor nên test cắm repository giả trong bộ nhớ,
không cần SQLite.
