# TÀI LIỆU KỸ THUẬT DỰ ÁN (PROJECT TECHNICAL DOCUMENTATION)
**Dự án:** Paper Chat with AI  
**Kho tài liệu:** Hướng dẫn kỹ thuật, Nghiệp vụ Frontend và Hợp đồng API Backend

---

## 📁 CẤU TRÚC THƯ MỤC TÀI LIỆU (`docs/`)

```text
docs/
├── README.md                           <- Tài liệu tổng quan này
├── FE/                                 <- Dành cho Đội ngũ Frontend
│   ├── 01_BUSINESS_REQUIREMENTS.md     <- Đặc tả toàn bộ nghiệp vụ, màn hình, tương tác FE
│   └── 02_PENDING_FEATURES.md          <- Các phần đang dùng Mock cần thay thế & Roadmap FE
└── BE/                                 <- Dành cho Đội ngũ Backend
    ├── 01_API_CONTRACT.md              <- Hợp đồng API chi tiết (Endpoints, Request/Response, Auth)
    └── 02_ARCHITECTURE_AI_RAG.md       <- Kiến trúc hệ thống, Database Schema & AI RAG Pipeline
```

---

## 📌 HƯỚNG DẪN DÀNH CHO BACKEND TEAM
1. Đọc file `docs/BE/02_ARCHITECTURE_AI_RAG.md` để nắm rõ cấu trúc Database (PostgreSQL / MongoDB), luồng xử lý OCR/Parser file PDF và kiến trúc Vector Search RAG.
2. Đọc file `docs/BE/01_API_CONTRACT.md` để triển khai đúng các Endpoint, định dạng JSON Request/Response và quy chuẩn mã lỗi mà Frontend đã thiết kế.

---

## 📌 HƯỚNG DẪN DÀNH CHO FRONTEND TEAM
1. Đọc file `docs/FE/01_BUSINESS_REQUIREMENTS.md` để nắm các luồng tương tác của người dùng.
2. Đọc file `docs/FE/02_PENDING_FEATURES.md` để biết vị trí các `Mock Repository` cần thay thế khi Backend bàn giao API thực tế.
