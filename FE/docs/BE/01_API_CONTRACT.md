# HỢP ĐỒNG GIAO TIẾP API (BACKEND API CONTRACT SPECIFICATION)
**Dự án:** Paper Chat with AI  
**Tiêu chuẩn:** RESTful JSON API + Server-Sent Events (SSE) cho Streaming  
**Base URL đề xuất:** `https://api.paperchat.ai/api/v1` (hoặc `http://localhost:8080/api/v1`)  
**Authorization:** `Bearer <JWT_ACCESS_TOKEN>` trong HTTP Header `Authorization`.

---

## 1. QUY CHUẨN CHUNG (GENERAL CONVENTIONS)

### 1.1. Format phản hồi chuẩn (Standard Response Format)
Tất cả các API trả về định dạng JSON thống nhất:
```json
{
  "success": true,
  "data": { ... },
  "message": "Thông điệp phản hồi (nếu có)"
}
```

### 1.2. Format phản hồi lỗi (Standard Error Format)
```json
{
  "success": false,
  "error": {
    "code": "INVALID_CREDENTIALS",
    "message": "Email hoặc mật khẩu không chính xác.",
    "details": []
  }
}
```

### 1.3. Mã lỗi HTTP Status Code
- `200 OK`: Thành công cho các tác vụ lấy dữ liệu (GET) hoặc cập nhật (PUT, PATCH).
- `201 Created`: Tạo mới tài nguyên thành công (POST).
- `204 No Content`: Xóa thành công (DELETE).
- `400 Bad Request`: Dữ liệu gửi lên sai định dạng hoặc thiếu trường bắt buộc.
- `401 Unauthorized`: Chưa đăng nhập hoặc Access Token đã hết hạn / không hợp lệ.
- `403 Forbidden`: Người dùng không có quyền truy cập tài nguyên này.
- `404 Not Found`: Không tìm thấy ID tài nguyên (Paper, Project, Note).
- `500 Internal Server Error`: Lỗi xử lý phía Backend hoặc kết nối AI Service.

---

## 2. PHÂN HỆ XÁC THỰC (AUTHENTICATION APIS)

### 2.1. Đăng ký tài khoản (Register)
* **Endpoint:** `POST /auth/register`
* **Request Body:**
```json
{
  "name": "Võ Tấn Thịnh",
  "email": "votanthinhcri28@gmail.com",
  "password": "Password123@"
}
```
* **Response (201 Created):**
```json
{
  "success": true,
  "data": {
    "user": {
      "id": "usr_987654321",
      "name": "Võ Tấn Thịnh",
      "email": "votanthinhcri28@gmail.com",
      "plan": "Free",
      "avatarUrl": null
    },
    "tokens": {
      "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6...",
      "refreshToken": "d8e8fca2dc6b4b9b9409b..."
    }
  }
}
```

---

### 2.2. Đăng nhập (Login)
* **Endpoint:** `POST /auth/login`
* **Request Body:**
```json
{
  "email": "votanthinhcri28@gmail.com",
  "password": "Password123@"
}
```
* **Response (200 OK):** (Cấu trúc tương tự đăng ký)

---

### 2.3. Đăng nhập Google (Google OAuth)
* **Endpoint:** `POST /auth/google`
* **Request Body:**
```json
{
  "idToken": "ya29.a0AfH6SM..."
}
```
* **Response (200 OK):** Trả về user & tokens.

---

### 2.4. Quên mật khẩu - Gửi mã xác thực (Forgot Password - Send OTP)
* **Endpoint:** `POST /auth/forgot-password`
* **Request Body:**
```json
{
  "email": "votanthinhcri28@gmail.com"
}
```
* **Response (200 OK):**
```json
{
  "success": true,
  "message": "Mã xác thực gồm 6 chữ số đã được gửi đến email của bạn."
}
```

---

### 2.5. Đặt lại mật khẩu với mã code (Verify OTP & Reset Password)
* **Endpoint:** `POST /auth/verify-reset-code`
* **Request Body:**
```json
{
  "email": "votanthinhcri28@gmail.com",
  "code": "849201",
  "newPassword": "NewSecurePassword123@"
}
```
* **Response (200 OK):**
```json
{
  "success": true,
  "message": "Mật khẩu đã được đặt lại thành công. Vui lòng đăng nhập lại."
}
```

---

### 2.6. Lấy thông tin tài khoản hiện tại (Get Profile)
* **Endpoint:** `GET /auth/me`
* **Headers:** `Authorization: Bearer <token>`
* **Response (200 OK):** Trả về thông tin chi tiết user hiện tại.

---

## 3. PHÂN HỆ QUẢN LÝ BÀI BÁO (PAPERS APIS)

### 3.1. Tải lên PDF & Trích xuất bằng AI (Upload & Extract PDF)
* **Endpoint:** `POST /papers/upload`
* **Headers:** `Content-Type: multipart/form-data`
* **Request Form-Data:**
  - `file`: File nhị phân `.pdf` (tối đa 50MB).
* **Quy trình BE thực hiện:**
  1. Lưu file PDF vào Cloud Storage (AWS S3, Google Cloud Storage hoặc MinIO).
  2. Dùng OCR / thư viện PDF Parser (`PyPDF`, `PDFMiner`, `Unstructured`) để trích xuất văn bản thô.
  3. Gửi tóm tắt văn bản đến LLM để trích xuất có cấu trúc: Tiêu đề, Danh sách tác giả, Năm xuất bản, Danh mục chủ đề (Collection), Thẻ phân loại (Tags), Tóm tắt (Abstract).
  4. Cắt đoạn văn bản thành các trang/phần (`pages`).
* **Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "tempFileId": "tmp_pdf_1789981290",
    "fileName": "Attention_Is_All_You_Need.pdf",
    "fileUrl": "https://storage.paperchat.ai/papers/1789981290.pdf",
    "fileSizeBytes": 2215480,
    "extractedMetadata": {
      "title": "Attention Is All You Need",
      "authors": ["Ashish Vaswani", "Noam Shazeer", "Niki Parmar", "Jakob Uszkoreit"],
      "year": 2017,
      "collection": "Deep Learning",
      "tags": ["Transformer", "Attention", "NLP"],
      "abstractText": "The dominant sequence transduction models are based on complex recurrent or convolutional neural networks... We propose the Transformer, a model architecture eschewing recurrence and instead relying entirely on an attention mechanism to draw global dependencies between input and output."
    },
    "pages": [
      {
        "pageNumber": 1,
        "sectionTitle": "1. Introduction",
        "content": "Recurrent neural networks, long short-term memory and gated recurrent neural networks in particular, have been firmly established as state of the art approaches in sequence modeling..."
      },
      {
        "pageNumber": 2,
        "sectionTitle": "2. Model Architecture",
        "content": "The Transformer follows this overall architecture using stacked self-attention and point-wise, fully connected layers for both the encoder and decoder..."
      }
    ]
  }
}
```

---

### 3.2. Lưu bài báo vào Thư viện (Save Paper)
* **Endpoint:** `POST /papers`
* **Request Body:**
```json
{
  "title": "Attention Is All You Need",
  "authors": ["Ashish Vaswani", "Noam Shazeer", "Niki Parmar"],
  "year": 2017,
  "collection": "Deep Learning",
  "tags": ["Transformer", "NLP"],
  "abstractText": "The dominant sequence transduction models...",
  "pdfUrl": "https://storage.paperchat.ai/papers/1789981290.pdf",
  "pages": [
    {
      "pageNumber": 1,
      "sectionTitle": "1. Introduction",
      "content": "Recurrent neural networks..."
    }
  ]
}
```
* **Response (201 Created):**
```json
{
  "success": true,
  "data": {
    "id": "paper_1789982000",
    "title": "Attention Is All You Need",
    "authors": ["Ashish Vaswani", "Noam Shazeer", "Niki Parmar"],
    "year": 2017,
    "collection": "Deep Learning",
    "tags": ["Transformer", "NLP"],
    "abstractText": "The dominant sequence transduction models...",
    "isFavorite": false,
    "totalPages": 2,
    "createdAt": "2026-09-21T08:00:00Z"
  }
}
```

---

### 3.3. Lấy danh sách bài báo trong Thư viện (Get Papers List)
* **Endpoint:** `GET /papers`
* **Query Parameters:**
  - `search`: Từ khóa tìm kiếm trong tiêu đề, tác giả, abstract, tag.
  - `collection`: Tên bộ sưu tập cần lọc (VD: `Deep Learning`).
  - `tag`: Tên thẻ (VD: `Transformer`).
  - `isFavorite`: `true` để lấy danh sách bài báo đánh dấu sao.
  - `sort`: `yearDesc`, `yearAsc`, `titleAsc`, `titleDesc`.
  - `page`: Số trang (mặc định: `1`).
  - `limit`: Số phần tử trên 1 trang (mặc định: `20`).
* **Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "papers": [
      {
        "id": "paper_1789982000",
        "title": "Attention Is All You Need",
        "authors": ["Ashish Vaswani", "Noam Shazeer"],
        "year": 2017,
        "collection": "Deep Learning",
        "tags": ["Transformer", "NLP"],
        "abstractText": "The dominant sequence transduction models...",
        "isFavorite": true,
        "totalPages": 15,
        "createdAt": "2026-09-21T08:00:00Z"
      }
    ],
    "pagination": {
      "currentPage": 1,
      "totalPages": 3,
      "totalItems": 45,
      "limit": 20
    }
  }
}
```

---

### 3.4. Lấy chi tiết bài báo kèm nội dung các trang (Get Paper Details & Pages)
* **Endpoint:** `GET /papers/{id}`
* **Response (200 OK):** Trả về đầy đủ thông tin bài báo cùng mảng `pages: [{ pageNumber, sectionTitle, content }]`.

---

### 3.5. Bật/Tắt yêu thích bài báo (Toggle Favorite)
* **Endpoint:** `PATCH /papers/{id}/favorite`
* **Response (200 OK):** `{ "success": true, "data": { "id": "paper_1789982000", "isFavorite": true } }`

---

### 3.6. Xóa bài báo (Delete Paper)
* **Endpoint:** `DELETE /papers/{id}`
* **Response (204 No Content)**

---

## 4. PHÂN HỆ TRÒ CHUYỆN AI & RAG (CHAT APIS)

### 4.1. Gửi tin nhắn trò chuyện với 1 bài báo (Chat Completion with 1 Paper)
* **Endpoint:** `POST /chat/completions`
* **Request Body:**
```json
{
  "paperId": "paper_1789982000",
  "message": "Cơ chế Self-Attention trong bài báo này hoạt động như thế nào?",
  "history": [
    { "role": "user", "text": "Chào bạn" },
    { "role": "assistant", "text": "Chào bạn! Tôi có thể giúp gì về bài báo này?" }
  ],
  "stream": false
}
```
* **Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "messageId": "msg_998877",
    "role": "assistant",
    "text": "Trong bài báo *Attention Is All You Need*, cơ chế **Scaled Dot-Product Attention** được tính toán bằng cách ánh xạ một truy vấn (Query - Q) và một tập hợp các cặp khóa-giá trị (Key - K, Value - V) tới đầu ra. Công thức cốt lõi là:\n\n$$\\text{Attention}(Q, K, V) = \\text{softmax}\\left(\\frac{QK^T}{\\sqrt{d_k}}\\right)V$$",
    "citations": [
      {
        "pageNumber": 2,
        "sectionTitle": "3.2.1 Scaled Dot-Product Attention",
        "quote": "We compute the attention function on a set of queries simultaneously, packed together into a matrix Q."
      }
    ],
    "createdAt": "2026-09-21T08:05:00Z"
  }
}
```

---

### 4.2. Trò chuyện dạng dòng thời gian thực (Streaming Chat with SSE)
* **Endpoint:** `GET /chat/stream` hoặc `POST /chat/stream`
* **Headers:** `Accept: text/event-stream`
* **Event Format:**
```text
data: {"chunk": "Trong bài báo ", "citations": []}
data: {"chunk": "*Attention Is All You Need*, ", "citations": []}
...
data: {"chunk": "", "done": true, "citations": [{"pageNumber": 2, "quote": "..."}]}
```

---

### 4.3. Trò chuyện với toàn bộ Dự án (Multi-paper Project Chat)
* **Endpoint:** `POST /chat/projects/{projectId}`
* **Request Body:**
```json
{
  "message": "Hãy so sánh phương pháp tiếp cận của các bài báo trong dự án này?",
  "history": []
}
```
* **BE thực hiện:** Thực hiện Vector Search đồng thời trên tất cả `paperIds` thuộc dự án đó, tổng hợp context và sinh câu trả lời so sánh có trích dẫn rõ tên bài báo và số trang.

---

## 5. PHÂN HỆ DỰ ÁN NGHIÊN CỨU (PROJECTS APIS)

* `GET /projects`: Lấy danh sách các dự án của người dùng.
* `POST /projects`: Tạo dự án mới (`{ "name": "LLM Optimization", "description": "...", "color": "0xFF3B82F6" }`).
* `PUT /projects/{id}`: Cập nhật thông tin dự án.
* `DELETE /projects/{id}`: Xóa dự án.
* `POST /projects/{id}/papers`: Gán bài báo vào dự án (`{ "paperIds": ["paper_1", "paper_2"] }`).
* `DELETE /projects/{id}/papers/{paperId}`: Gỡ bài báo khỏi dự án.

---

## 6. PHÂN HỆ GHI CHÚ (NOTES APIS)

* `GET /notes`: Lấy toàn bộ ghi chú (có thể lọc theo `paperId`).
* `POST /notes`: Tạo ghi chú mới (`{ "title": "Ý tưởng nghiên cứu", "content": "Markdown...", "paperId": "..." }`).
* `PUT /notes/{id}`: Sửa ghi chú.
* `DELETE /notes/{id}`: Xóa ghi chú.

