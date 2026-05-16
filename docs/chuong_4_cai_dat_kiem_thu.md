# CHƯƠNG 4: CÀI ĐẶT VÀ KIỂM THỬ

## 4.1. Môi trường và công cụ phát triển

Quá trình xây dựng và phát triển ứng dụng nghe nhạc được thực hiện trên môi trường và các công cụ hiện đại, đảm bảo tính ổn định và khả năng mở rộng của hệ thống.

**4.1.1. Môi trường phần cứng**
- Máy tính phát triển: PC/Laptop chạy hệ điều hành Windows/macOS.
- Thiết bị kiểm thử: Máy ảo (Android Emulator / iOS Simulator) và thiết bị di động thật (Android/iOS) để đánh giá hiệu năng thực tế.

**4.1.2. Môi trường phần mềm và công cụ**
- **Ngôn ngữ lập trình:** Dart (cho Frontend) và SQL (cho Database).
- **Framework phát triển:** Flutter SDK – framework mã nguồn mở của Google hỗ trợ lập trình đa nền tảng (Android, iOS, Web) chỉ với một cơ sở mã (codebase).
- **Nền tảng Backend (BaaS):** Supabase – nền tảng thay thế Firebase mã nguồn mở, sử dụng cơ sở dữ liệu PostgreSQL mạnh mẽ.
- **Công cụ lập trình (IDE):** Visual Studio Code / Android Studio.
- **Quản lý phiên bản:** Git và GitHub.
- **Kiến trúc và quản lý trạng thái:** Sử dụng mẫu thiết kế (Pattern) BLoC (Business Logic Component) và Cubit thông qua thư viện `flutter_bloc` để tách biệt giao diện (UI) và logic nghiệp vụ. Sử dụng `get_it` cho Dependency Injection.

---

## 4.2. Cài đặt hệ thống Backend và Cơ sở dữ liệu

Backend của hệ thống được xây dựng hoàn toàn dựa trên các dịch vụ của Supabase.

**4.2.1. Cài đặt Cơ sở dữ liệu (PostgreSQL)**
Hệ thống sử dụng các bảng dữ liệu chính để quản lý:
- Bảng `profiles`: Quản lý thông tin người dùng (tên, avatar, email).
- Bảng `songs` / `albums`: Lưu trữ thông tin bài hát và album do hệ thống phát hành.
- Bảng `user_songs`: Quản lý nhạc do cộng đồng tải lên (trạng thái pending, approved, rejected).
- Bảng `listening_history`: Lưu vết lịch sử nghe nhạc của người dùng. Tích hợp các hàm (Stored Procedures) để tự động nhóm và tính toán top bài hát thịnh hành cho Bảng xếp hạng (ZingChart).

**4.2.2. Cài đặt Supabase Storage**
Hệ thống sử dụng Supabase Storage bucket để lưu trữ file tĩnh:
- `songs`: Chứa các file âm thanh (mp3, wav) của bài hát hệ thống.
- `user-audio`: Nơi lưu trữ an toàn các file nhạc do người dùng tải lên.
- `artworks`: Chứa hình ảnh bìa bài hát, avatar người dùng.

**4.2.3. Cấu hình bảo mật (RLS - Row Level Security)**
Để đảm bảo an toàn dữ liệu, hệ thống thiết lập các chính sách RLS trên Supabase. Ví dụ:
- Người dùng chỉ có quyền xem lịch sử nghe nhạc của chính mình.
- Chức năng Upload nhạc yêu cầu người dùng phải đăng nhập hợp lệ.
- Tính năng kiểm duyệt nhạc chỉ dành cho tài khoản có vai trò Quản trị viên (Admin).

---

## 4.3. Triển khai giao diện và chức năng ứng dụng

Ứng dụng được thiết kế theo xu hướng hiện đại (Glassmorphism, Dark Theme) mang lại trải nghiệm cao cấp cho người dùng.

**4.3.1. Trang Khám phá (Explore/Home)**
- Màn hình chính hiển thị các nội dung được cá nhân hóa: Banner sự kiện, Gợi ý dành cho bạn, Album mới phát hành, và Nhạc từ cộng đồng.
- Sử dụng `audio_service` kết hợp `just_audio` để đảm bảo nhạc vẫn tiếp tục phát khi ứng dụng chạy ngầm.

**4.3.2. Trình phát nhạc (Player & Mini Player)**
- **Mini Player:** Hiển thị xuyên suốt ở cạnh dưới màn hình, cho phép thao tác nhanh (Play, Pause, Next) mà không cản trở việc điều hướng.
- **Full Player:** Giao diện trực quan với hình nền mờ (blur background) lấy từ ảnh bìa bài hát. Hỗ trợ hiển thị thanh tiến trình (Seek bar), lặp bài, trộn bài và xem danh sách phát hiện tại.

**4.3.3. Bảng xếp hạng (ZingChart)**
- Bảng xếp hạng thời gian thực dựa trên tổng lượt nghe thực tế của người dùng.
- Hiển thị trực quan top 100 bài hát thịnh hành, phân biệt nhạc hệ thống và nhạc cộng đồng tải lên một cách mượt mà.

**4.3.4. Hệ thống tải nhạc cộng đồng & Quản trị viên**
- Người dùng có thể chủ động tải lên file MP3 và hình ảnh bìa. Bài hát sẽ ở trạng thái chờ duyệt (Pending).
- Quản trị viên có trang Dashboard riêng để nghe thử, Phê duyệt (Approve) hoặc Từ chối (Reject) với lý do cụ thể, giúp đảm bảo chất lượng nội dung ứng dụng.

---

## 4.4. Kiểm thử phần mềm (Software Testing)

Kiểm thử là bước quan trọng để đảm bảo ứng dụng hoạt động đúng logic, không xảy ra lỗi trong quá trình sử dụng thực tế. Dự án áp dụng phương pháp Kiểm thử hộp đen (Black-box Testing).

**4.4.1. Mục tiêu kiểm thử**
- Đảm bảo các chức năng cốt lõi (Phát nhạc, Đăng nhập, Bảng xếp hạng) hoạt động ổn định.
- Phát hiện và xử lý các lỗi logic (Bug) trong luồng thao tác của người dùng.
- Kiểm tra tính toàn vẹn của dữ liệu giữa ứng dụng (Flutter) và máy chủ (Supabase).

**4.4.2. Các kịch bản kiểm thử (Test Cases)**

| Mã TC | Tên kịch bản (Test Case) | Các bước thực hiện | Kết quả mong đợi | Đánh giá |
| :--- | :--- | :--- | :--- | :--- |
| **TC_01** | Kiểm tra Đăng nhập thành công | 1. Mở app, chọn Đăng nhập.<br>2. Nhập Email và Password hợp lệ.<br>3. Bấm Đăng nhập. | Chuyển hướng thành công vào Trang chủ. Hiển thị thông tin Profile đúng tài khoản. | **PASS** |
| **TC_02** | Trình phát nhạc chạy ngầm | 1. Bấm phát một bài hát.<br>2. Ẩn ứng dụng (chuyển sang app khác hoặc khóa màn hình). | Nhạc vẫn tiếp tục phát bình thường. Các nút điều khiển trên màn hình khóa hoạt động tốt. | **PASS** |
| **TC_03** | Chuyển bài hát tiếp theo | 1. Mở trình phát nhạc.<br>2. Bấm nút Next (Chuyển bài). | Âm thanh chuyển sang bài hát kế tiếp ngay lập tức, giao diện cập nhật đúng ảnh bìa mới. | **PASS** |
| **TC_04** | Tính lượt nghe Bảng xếp hạng | 1. Bấm phát bài hát A từ vị trí 0:00.<br>2. Nghe trên 5 giây.<br>3. Chuyển sang bài B, rồi quay lại bài A. | Hệ thống ghi nhận 2 dòng lịch sử nghe nhạc cho bài A vào Supabase. Bảng xếp hạng cộng thêm 2 lượt. | **PASS** |
| **TC_05** | Tải lên bài hát cộng đồng | 1. Vào thư viện, chọn Tải nhạc lên.<br>2. Chọn file MP3 hợp lệ, nhập tên.<br>3. Bấm Submit. | Thông báo tải lên thành công. Trạng thái bài hát chuyển thành "Chờ duyệt" (Pending). | **PASS** |
| **TC_06** | Admin duyệt bài hát | 1. Đăng nhập tài khoản Admin.<br>2. Mở Dashboard duyệt bài.<br>3. Bấm Approve bài hát chờ duyệt. | Bài hát chuyển sang trạng thái Approved và ngay lập tức xuất hiện ở màn hình Khám phá của mọi người dùng. | **PASS** |

---

## 4.5. Đánh giá kết quả

Sau quá trình cài đặt và thực thi các kịch bản kiểm thử:
- Hệ thống hoạt động **ổn định**, giao diện đáp ứng tốt trên các kích thước màn hình khác nhau.
- Tính năng phát nhạc bằng `just_audio` kết hợp `audio_service` hoạt động trơn tru cả khi chạy ngầm.
- Hệ thống cơ sở dữ liệu Supabase lưu trữ an toàn, phản hồi nhanh gọn các truy vấn lấy dữ liệu Bảng xếp hạng.
- Đã khắc phục thành công các rủi ro liên quan đến việc đếm sai lượt nghe (Play count) và chặn trùng lặp dữ liệu, đảm bảo bảng xếp hạng hoạt động minh bạch và chính xác tuyệt đối.
- **Kết luận:** Ứng dụng đáp ứng đầy đủ các yêu cầu đề ra ban đầu, sẵn sàng cho việc đóng gói và triển khai thực tế.
