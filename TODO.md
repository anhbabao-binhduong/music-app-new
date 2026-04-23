# TODO.md

Danh sách việc cần làm / thiếu thông tin, **ưu tiên cho việc giúp AI và dev hiểu project tốt hơn**.

## Ưu tiên cao

- [ ] Di chuyển các credentials hard-code ra environment variables / `--dart-define`:
  - `lib/core/config/supabase_config.dart`
  - `lib/services/emailjs_service.dart`
  - `lib/services/supabase_auth_service.dart`
- [ ] Bổ sung tài liệu schema Supabase chính thức:
  - tables
  - relationships
  - indexes
  - RLS policies
  - storage buckets policies
- [ ] Bổ sung mô tả luồng auth hoàn chỉnh (register, login, Google sign-in, sign-out, session recovery).
- [ ] Ghi rõ quy ước ID type cho từng bảng (`songs.id`, `albums.id`, `user_songs.id`, …).

## Tài liệu

- [ ] Bổ sung ERD hoặc sơ đồ database vào `docs/architecture.md` hoặc `docs/database.md`.
- [ ] Bổ sung sequence flow cho các tác vụ quan trọng:
  - playback
  - upload song
  - admin approval
  - sync listening history
- [ ] Ghi rõ cách chạy project với môi trường local/dev/prod.
- [ ] Bổ sung file `LICENSE` nếu cần open-source/public distribution.
- [ ] Bổ sung maintainer / owner information trong `README.md`.

## Backend / API

- [ ] Tài liệu hóa đầy đủ RPC:
  - `get_chart_top_songs`
  - `get_chart_trends`
  - `get_user_comments_with_songs`
  - `get_admin_stats`
- [ ] Ghi sample JSON response cho từng RPC/table quan trọng.
- [ ] Xác nhận bucket `songs`, `user-audio`, `user-covers` đang public hay private + policy tương ứng.

## Code quality / cấu trúc

- [ ] Chuẩn hóa nơi truy cập data:
  - hiện tại có chỗ dùng repository, có chỗ cubit gọi Supabase trực tiếp.
- [ ] Quy định rõ module nào dùng Hive local-only, module nào sync Supabase.
- [ ] Xem lại mapping `SongEntity.audioUrl` vs `MediaItem.extras['url']` để tránh bug khi play.
- [ ] Rà soát xử lý lỗi và log debug trong audio/history/admin/upload.

## Testing

- [ ] Bổ sung tài liệu test strategy:
  - unit test cho repository/usecase
  - bloc/cubit tests
  - integration test cho auth/upload/playback flows
- [ ] Ghi rõ test nào cần Supabase thật / test doubles.

## Những gì AI còn chưa thể xác nhận chỉ từ code

- [ ] Schema đầy đủ của `albums`, `categories`, `downloads`.
- [ ] Chính xác các field của `AdminStats` model.
- [ ] Cấu hình deployment / CI/CD.
- [ ] Có hay không migration scripts cho Supabase.
