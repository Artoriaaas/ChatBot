# CÁC PHẦN CHƯA HOÀN THÀNH & LỘ TRÌNH PHÁT TRIỂN FRONTEND
**Dự án:** Paper Chat with AI  
**Tài liệu:** Frontend Pending Tasks & Roadmap

---

## 1. DANH SÁCH CÁC PHẦN ĐANG DÙNG MOCK CẦN ĐẤU NỐI API THỰC TẾ

Hiện tại giao diện Frontend đã hoàn chỉnh 100% về mặt tương tác, hoạt ảnh và trải nghiệm người dùng, nhưng dữ liệu đang được điều phối qua các Repository giả lập (`Mock Repositories`). Khi Backend xây dựng xong các Endpoint, Frontend cần thay thế như sau:

| STT | Phân hệ / Tính năng | Hiện trạng ở FE (Mock) | Việc cần làm khi có Backend API |
| :--- | :--- | :--- | :--- |
| **1** | **Xác thực (Auth)** | `MockAuthRepository` (lưu state người dùng trong RAM / giả lập độ trễ 600ms). | - Thay bằng `AuthRemoteRepository` gọi API `POST /api/v1/auth/login`, `POST /api/v1/auth/register`.<br>- Lưu trữ `accessToken` và `refreshToken` an toàn bằng `flutter_secure_storage`.<br>- Tích hợp SDK Firebase Auth hoặc Google Sign-In native để lấy OAuth ID token gửi lên Backend. |
| **2** | **Quên mật khẩu & OTP** | `LoginScreen` (mô phỏng xác nhận mã OTP bất kỳ 6 số). | - Gọi `POST /api/v1/auth/forgot-password` gửi mail thật.<br>- Gọi `POST /api/v1/auth/verify-reset-code` để xác thực mã code thật và đổi mật khẩu trên DB. |
| **3** | **Tải lên & Trích xuất PDF** | `ImportPaperDialog` (mô phỏng trích xuất sau 1 giây, tự suy ra tiêu đề từ tên file). | - Gửi file PDF nhị phân qua `POST /api/v1/papers/upload` dạng `multipart/form-data`.<br>- Backend xử lý OCR / PDF Parser bằng AI và trả về JSON metadata thực tế (Authors, Abstract, Year, Chunks). |
| **4** | **Kho lưu trữ Bài báo (Papers)** | `MockPaperRepository` (lưu danh sách 5 bài báo khởi tạo mẫu trong bộ nhớ). | - Thay bằng `PaperRemoteRepository` gọi `GET /api/v1/papers` (hỗ trợ phân trang `page`, `limit`).<br>- Gọi `POST /api/v1/papers` để lưu bài báo mới vào DB Backend.<br>- Gọi `PATCH /api/v1/papers/{id}/favorite` và `DELETE /api/v1/papers/{id}`. |
| **5** | **AI Chatbot & RAG** | `MockChatRepository` (trả về câu trả lời định sẵn với citation giả lập sau 800ms). | - Gọi `POST /api/v1/chat/completions` hoặc kết nối SSE (Server-Sent Events) `GET /api/v1/chat/stream`.<br>- Hỗ trợ hiển thị chữ chạy thời gian thực (Streaming text rendering).<br>- Nhận mảng `citations` thực tế từ vector search của Backend để link chính xác số trang. |
| **6** | **Dự án Nghiên cứu (Projects)** | `MockProjectsRepository` (lưu dự án và danh sách ID bài báo trong bộ nhớ). | - Gọi CRUD API cho Projects (`GET/POST/PUT/DELETE /api/v1/projects`).<br>- Gọi API thêm/xóa bài báo vào dự án (`POST/DELETE /api/v1/projects/{id}/papers`). |
| **7** | **Ghi chú (Notes)** | `NotesRepository` (lưu ghi chú cục bộ trong memory). | - Đồng bộ 2 chiều (Cloud Sync) giữa máy khách và Backend thông qua `GET/POST/PUT/DELETE /api/v1/notes`. |

---

## 2. CÁC TÍNH NĂNG FRONTEND CẦN HOÀN THIỆN THÊM (CHƯA XÂY DỰNG)

1. **Hiển thị PDF Render thực tế (`syncfusion_flutter_pdfviewer` hoặc `pdfx`)**:
   - Hiện tại màn hình đọc (`ReaderScreen`) đang render nội dung dưới dạng các khối văn bản phân trang (`PaperPage`).
   - Cần bổ sung chế độ xem kép: Có thể chuyển đổi giữa **Chế độ văn bản thông minh (Smart Reader)** và **Chế độ xem bản PDF gốc (Native PDF Canvas Viewer)**.
2. **Cơ chế Lưu đệm Offline (Offline Cache)**:
   - Tích hợp SQLite (`sqflite` hoặc `isar` / `drift`) để lưu trữ bài báo và ghi chú về máy, cho phép người dùng mở xem khi không có kết nối Internet.
3. **Thanh toán & Nâng cấp gói Pro (Stripe / Apple In-App Purchase / VNPay)**:
   - Hiện tại Avatar hiển thị nhãn `Free` / `Pro` nhưng chưa có trang bảng giá (Pricing Table) và cổng thanh toán để nâng hạn mức số lượng bài báo tải lên hoặc lượt chat AI.
4. **Xuất báo cáo & Trích dẫn (Export Citation & Summary)**:
   - Bổ sung nút xuất trích dẫn định dạng BibTeX, APA, MLA, Chicago từ bài báo.
   - Xuất biên bản ghi chú (Export Markdown/PDF Summary) sau khi đọc bài báo.
5. **Đồng bộ thời gian thực (WebSockets / Supabase Realtime)**:
   - Khi có người khác thêm bài báo vào Dự án chung (tính năng Teamwork tương lai), danh sách bài báo tự động cập nhật mà không cần tải lại trang.

