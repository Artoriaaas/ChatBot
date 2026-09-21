# TÀI LIỆU ĐẶC TẢ NGHIỆP VỤ FRONTEND (FE BUSINESS REQUIREMENTS)
**Dự án:** Paper Chat with AI (Hệ thống Nghiên cứu & Trò chuyện Bài báo Khoa học)  
**Nền tảng:** Flutter Multiplatform (Windows Desktop, Web, Android, iOS)  
**Phiên bản:** 1.0.0

---

## 1. TỔNG QUAN DỰ ÁN
**Paper Chat with AI** là ứng dụng hỗ trợ các nhà nghiên cứu, giảng viên và sinh viên đọc hiểu, quản lý và đối thoại với tài liệu khoa học (PDF) thông qua trí tuệ nhân tạo (AI/LLM). 

Ứng dụng cho phép:
1. Đăng ký, đăng nhập và khôi phục tài khoản qua Email/Mật khẩu hoặc Google Auth.
2. Tải trực tiếp file PDF bài báo từ máy tính, trích xuất tự động siêu dữ liệu (Metadata) và nội dung học thuật.
3. Đọc bài báo với giao diện chuyên dụng: phân trang, phóng to/thu nhỏ, highlight tô màu và ghi chú trực tiếp.
4. Trò chuyện chuyên sâu với AI (RAG Chat) theo từng bài báo đơn lẻ hoặc theo nhóm bài báo trong một Dự án (Multi-paper Project Chat).
5. Quản lý dự án nghiên cứu, ghi chú nổi linh hoạt (có thể kéo thả trên màn hình) và đa ngôn ngữ (Tiếng Việt & Tiếng Anh).

---

## 2. KIẾN TRÚC & QUẢN LÝ TRẠNG THÁI FRONTEND
- **Pattern:** MVVM (Model - View - ViewModel) kết hợp `ChangeNotifier` và `ListenableBuilder`.
- **Theme & Design System:** Hỗ trợ Light Mode & Dark Mode tự động, hệ thống Token màu sắc hiện đại (`AppColorsExtension`), Typography chuẩn học thuật.
- **Đa ngôn ngữ (i18n):** Song ngữ Tiếng Việt (`AppStrings.vi`) và Tiếng Anh (`AppStrings.en`), chuyển đổi tức thì không cần tải lại app.

---

## 3. CHI TIẾT NGHIỆP VỤ TỪNG PHÂN HỆ

### 3.1. Phân hệ Xác thực (Authentication)
* **Màn hình:** `LoginScreen` (bao gồm tab Đăng nhập & Đăng ký), Modal Quên mật khẩu.
* **Quy trình nghiệp vụ:**
  1. **Đăng nhập (Sign In):**
     - Nhập Email và Mật khẩu. Hỗ trợ hiển thị/ẩn mật khẩu.
     - Validate định dạng email và mật khẩu tối thiểu 6 ký tự.
     - Tùy chọn đăng nhập nhanh thông qua Google (`Google Sign-In`).
  2. **Đăng ký (Sign Up):**
     - Nhập Họ tên, Email, Mật khẩu và Xác nhận mật khẩu.
     - Kiểm tra mật khẩu khớp và thông báo lỗi trực quan.
  3. **Quên mật khẩu (Forgot Password Flow):**
     - **Bước 1:** Nhập email tài khoản và nhấn "Gửi mã xác nhận".
     - **Bước 2:** Hệ thống hiển thị ô nhập mã OTP (6 số) và mật khẩu mới.
     - **Bước 3:** Nhấn "Đặt lại mật khẩu" để hoàn tất và quay về màn hình đăng nhập.
  4. **Quản lý phiên (Session):**
     - Lưu trữ trạng thái đăng nhập của người dùng.
     - Hiển thị thông tin Avatar, Tên, Email và Gói dịch vụ (Free/Pro) ở chân Menu Sidebar.
     - Nút "Đăng xuất" xóa phiên và quay lại màn hình Login.

---

### 3.2. Phân hệ Thư viện & Quản lý Tài liệu (Library & Import Paper)
* **Màn hình:** `LibraryScreen`, `ImportPaperDialog`.
* **Quy trình nghiệp vụ:**
  1. **Hiển thị danh sách bài báo:**
     - Dạng lưới (Grid Card) hoặc danh sách chi tiết.
     - Mỗi card hiển thị: Tiêu đề, Tác giả, Năm xuất bản, Bộ sưu tập (Chủ đề), Thẻ Tags, Tóm tắt (Abstract) ngắn gọn, số trang, nút Yêu thích (Star).
  2. **Tìm kiếm & Lọc (Search & Filter):**
     - Thanh tìm kiếm tức thì theo từ khóa (Tiêu đề, Tác giả, Abstract, Tags).
     - Bộ lọc theo Bộ sưu tập (Dropdown).
     - Lọc theo Thẻ Tags (Chip filter dạng cuộn ngang).
     - Lọc nhanh danh sách bài báo Yêu thích (Favorites).
     - Sắp xếp (Sort): Năm mới nhất, Năm cũ nhất, Tiêu đề A-Z, Tiêu đề Z-A.
  3. **Tải lên bài báo mới (PDF Upload Pipeline):**
     - Nhấn nút **"+" (Thêm bài báo)** hoặc phím tắt `Ctrl + O` để mở `ImportPaperDialog`.
     - Nhấn nút **"Chọn file từ máy tính"** để duyệt file `.pdf` qua native file picker.
     - Giao diện hiển thị tên file, kích thước tệp, thanh tiến trình AI trích xuất (Extraction Progress).
     - Các trường thông tin siêu dữ liệu (Metadata) hiển thị sẵn sàng:
       - **Tiêu đề bài báo** (Bắt buộc, tự động chuẩn hóa từ tên file).
       - **Tác giả** & **Năm xuất bản**.
       - **Bộ sưu tập** (Category) & **Thẻ phân loại** (Tags).
       - **Tóm tắt (Abstract)**.
     - Người dùng có thể chỉnh sửa bất kỳ ô nào trước khi nhấn **"Thêm vào thư viện"**.
     - Bài báo mới tạo lập tức xuất hiện ở đầu Thư viện và có thể mở đọc/chat ngay lập tức.

---

### 3.3. Phân hệ Đọc tài liệu (Reader)
* **Màn hình:** `ReaderScreen`.
* **Quy trình nghiệp vụ:**
  1. **Đọc bài báo đa trang:**
     - Thanh Tab Bar trên đầu hiển thị danh sách các bài báo đang mở, cho phép chuyển tab hoặc đóng tab (`Ctrl + W`).
     - Hiển thị từng trang bài báo với tiêu đề mục (`sectionTitle`) và nội dung chi tiết.
  2. **Công cụ đọc chuyên dụng:**
     - Điều hướng trang trước / trang sau, nhảy đến trang cụ thể.
     - Phóng to / Thu nhỏ cỡ chữ và khung nhìn (Zoom In / Zoom Out / Reset 100%).
     - Tìm kiếm văn bản trong tài liệu (In-paper search).
     - Thêm bài báo đang đọc vào một Dự án cụ thể.
  3. **Đánh dấu (Highlighting):**
     - Chọn văn bản và tô màu highlight: Vàng (Yellow), Xanh lá (Green), Xanh dương (Blue), Hồng (Pink).
  4. **Ghi chú nổi linh hoạt (Movable Floating Notes):**
     - Bấm nút Ghi chú để mở cửa sổ ghi chú nhanh.
     - Có thể **kéo thả di chuyển tự do** khắp màn hình (không bị cố định vị trí), thu gọn thành nút tròn nhỏ hoặc mở rộng để soạn thảo Markdown.

---

### 3.4. Phân hệ Trò chuyện AI (AI Chat & RAG)
* **Màn hình:** `ChatPanel` (bên cạnh Reader), `ProjectWorkspaceScreen` (Chat dự án).
* **Quy trình nghiệp vụ:**
  1. **Chat với 1 bài báo đơn lẻ (`ChatPanel`):**
     - Người dùng đặt câu hỏi về nội dung bài báo đang đọc.
     - Gợi ý câu hỏi nhanh (Quick Prompts): "Tóm tắt phương pháp", "Điểm hạn chế", "Kết quả thực nghiệm"...
     - Phản hồi từ AI hiển thị dạng hội thoại trực quan, có định dạng Markdown (tiêu đề, danh sách, công thức, khối mã).
     - **Trích dẫn minh chứng (Citations):** Mỗi câu trả lời kèm thẻ trích dẫn chính xác số trang (`Page X`) và đoạn trích văn bản tương ứng. Nhấp vào citation sẽ đưa người dùng đến đúng trang trong tài liệu.
  2. **Chat với nhóm bài báo trong Dự án (`Project Chat`):**
     - Trò chuyện tổng hợp trên toàn bộ các bài báo đã thêm vào Dự án.
     - AI có khả năng so sánh, tổng hợp kết quả giữa nhiều bài báo khác nhau trong cùng một chủ đề nghiên cứu.

---

### 3.5. Phân hệ Quản lý Dự án Nghiên cứu (Projects Tree)
* **Màn hình:** Sidebar Project Tree, `ProjectWorkspaceScreen`, `CreateProjectDialog`, `EditProjectDialog`, `AddPapersDialog`.
* **Quy trình nghiệp vụ:**
  1. **Tạo & Quản lý Dự án:**
     - Nhấn nút `+` cạnh mục DỰ ÁN trên Sidebar để mở hộp thoại tạo dự án (Tên dự án, Mô tả, Chọn màu đại diện).
     - Có menu chỉnh sửa tên dự án, đổi màu, gán thêm bài báo hoặc xóa dự án.
  2. **Cấu trúc cây thả xuống (Tree Dropdown):**
     - Dự án hiển thị mũi tên đóng/mở. Khi mở ra, liệt kê danh sách các bài báo thuộc dự án đó.
     - Nhấp vào bài báo con để mở đọc ngay trong ngữ cảnh dự án.
     - Nút chat nhanh icon AI trên thanh dự án mở thẳng không gian làm việc `ProjectWorkspaceScreen`.

---

### 3.6. Phân hệ Ghi chú (Notes Management)
* **Màn hình:** `NotesScreen`.
* **Quy trình nghiệp vụ:**
  1. Liệt kê toàn bộ các ghi chú đã tạo (ghi chú tự do hoặc ghi chú gắn liền với bài báo).
  2. Soạn thảo ghi chú hỗ trợ tiêu đề, nội dung, màu sắc nhãn.
  3. Tìm kiếm ghi chú theo từ khóa, lọc theo bài báo liên quan, xóa ghi chú.

