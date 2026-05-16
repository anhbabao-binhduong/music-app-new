# Music App (Flutter + Supabase)

Ứng dụng nghe nhạc đa nền tảng (mobile/web/desktop) viết bằng Flutter.

## Mục tiêu dự án

Dựa trên code hiện tại, project tập trung vào:

- Phát nhạc online với hàng chờ (queue), điều khiển phát, phát nền.
- Quản lý thư viện cá nhân: yêu thích, lịch sử nghe, playlist.
- Xác thực người dùng bằng Supabase Auth (email/password + Google Sign-In).
- Tính năng cộng đồng: bình luận, upload bài hát người dùng.
- Khu vực quản trị (admin/moderator): duyệt bài upload, quản lý user/comment, thống kê.

## Công nghệ chính

- **Framework:** Flutter (SDK >= 3.10.0)
- **State management:** flutter_bloc (Bloc/Cubit)
- **Backend:** Supabase (Database, Auth, Storage, RPC)
- **Audio:** just_audio + audio_service + audio_session
- **Local storage:** Hive
- **Dependency injection:** get_it
- **Networking:** http, dio

## Cấu trúc thư mục chính

- `lib/main.dart`: Điểm vào app, thứ tự khởi tạo Hive → Supabase → DI → runApp.
- `lib/app.dart`: `MaterialApp`, theme mode, `RootPage`.
- `lib/core/`: constants, config, DI (`service_locator.dart`, `hive_initializer.dart`).
- `lib/domain/`: entities, repository contracts, use cases.
- `lib/data/`: models + repository implementations.
- `lib/presentation/bloc/`: các Bloc/Cubit theo feature.
- `lib/pages/`: các màn hình UI.
- `lib/services/`: audio/auth/playlist/lyrics/email services.
- `test/`: unit/widget/integration tests.

## Luồng khởi động (rút gọn)

1. `HiveInitializer.init()` mở toàn bộ box cần dùng.
2. `Supabase.initialize(...)` dùng `SupabaseConfig.url/anonKey`.
3. `setupServiceLocator()` đăng ký service/repository/cubit.
4. Tải danh sách bài hát từ Supabase (`SongRepository.fetchSongsFromSupabase()`).
5. Nạp queue audio ban đầu nếu user đã đăng nhập.
6. Lắng nghe `onAuthStateChange` để dọn dữ liệu khi sign-out.

## Chạy dự án

```bash
flutter pub get
flutter run
```

## Chạy app

- Windows: chạy file `run_web.bat`
- Mac/Linux: chạy file `run_web.sh`

## Tài liệu bổ sung

- Kiến trúc chi tiết: `docs/architecture.md`
- Ngữ cảnh cho AI agent: `AI_CONTEXT.md`
- API/DB inference từ code: `API.md`
- Việc cần làm & thiếu thông tin: `TODO.md`
- Biến cấu hình mẫu: `.env.example`

## Ghi chú quan trọng

- Hiện tại một số credentials đang hard-code trong source (`supabase_config.dart`, `emailjs_service.dart`, `supabase_auth_service.dart`).
- File `.env.example` được thêm để chuẩn hóa cấu hình; **cần refactor code để đọc từ env/dart-define**.
- Nếu có điểm chưa xác nhận từ code, tài liệu sẽ đánh dấu `TODO` thay vì suy đoán.

## Testing

Project có các test file trong `test/` (unit/widget/integration). Chạy bằng:

```bash
flutter test
```

## License

TODO: Chưa thấy file LICENSE trong project.

## Maintainers

TODO: Chưa thấy thông tin maintainer/owner trong codebase.

## Setup nhanh cho AI Agent

Đọc theo thứ tự:

1. `AI_CONTEXT.md`
2. `docs/architecture.md`
3. `API.md`
4. `TODO.md`
5. `lib/main.dart` + `lib/core/di/service_locator.dart`

Điều này giúp hiểu nhanh cấu trúc và luồng nghiệp vụ trước khi chỉnh sửa code.