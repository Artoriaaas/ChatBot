# KẾ HOẠCH FIX: LỖI FORMAT IN ĐẬM/IN NGHIÊNG & NÂNG CẤP KHU VỰC REFERENCE Ở CUỐI ĐOẠN CHAT

---

## 1. PHÂN TÍCH NGUYÊN NHÂN GỐC RỄ (ROOT CAUSE ANALYSIS)

### 1.1. Bug 1: Lỗi format chữ in đậm (`**`), in nghiêng (`*`), và lộ cú pháp Markdown
- **Hiện tượng (như trong ảnh 1 & 2):**
  - Dòng `**Tác giả**: R Michael Churchill, Matt Landreman...` hiển thị nguyên xi 2 dấu `**` phía trước và `**:` phía sau. Dấu `**` không biến thành chữ in đậm, trong khi toàn bộ nội dung phía sau lại bị ép thành chữ in nghiêng.
  - Trong ảnh 2, các đoạn trích từ bài báo khi hiển thị ra màn hình vẫn còn nguyên các ký tự `#`, `## Abstract`, `## 1. Introduction` và cú pháp liên kết nội bộ `[\\[1\\]](cite:b0)[\\[2\\]](cite:b1)`.
- **Nguyên nhân kỹ thuật:**
  1. **Hiển thị bằng widget `Text()` thay vì `MarkdownBody`:**
     - Trong [message_bubble.dart](file:///d:/Tai_lieu/Ky_8/PRM232/ChatBot/FE/lib/features/chat/widgets/message_bubble.dart#L275-L284) (phần Quoted Source Snippet Card ở cuối chat), đoạn trích dẫn được render bằng:
       ```dart
       Text(
         message.citations.first.excerpt,
         maxLines: 3,
         style: AppTypography.caption.copyWith(
           color: colors.textSecondary,
           fontStyle: FontStyle.italic, // <--- ÉP TOÀN BỘ TEXT IN NGHIÊNG
         ),
       )
       ```
       Vì sử dụng widget `Text(...)` thuần túy của Flutter, nó **không thể parse cú pháp Markdown** (`**`, `*`, `#`), khiến chuỗi `**Tác giả**:` bị in ra dạng text thô, đồng thời thuộc tính `fontStyle: FontStyle.italic` làm toàn bộ đoạn trích bị nghiêng ngả.
     - Tương tự trong hộp thoại xem trước trích dẫn [message_bubble.dart](file:///d:/Tai_lieu/Ky_8/PRM232/ChatBot/FE/lib/features/chat/widgets/message_bubble.dart#L453), `citation.excerpt` cũng đang được nhét vào widget `Text(...)`, dẫn tới việc lộ toàn bộ mã Markdown thô như trong Ảnh 2.
  2. **Thiếu định nghĩa `strong:` và `em:` trong `MarkdownStyleSheet`:**
     - Cả ở [reader_pane.dart](file:///d:/Tai_lieu/Ky_8/PRM232/ChatBot/FE/lib/features/reader/widgets/reader_pane.dart#L430-L485) và [message_bubble.dart](file:///d:/Tai_lieu/Ky_8/PRM232/ChatBot/FE/lib/features/chat/widgets/message_bubble.dart#L210-L224), `MarkdownStyleSheet` chỉ định nghĩa `p`, `h1`, `h2`, `h3`, `code`, `a` mà **bỏ quên thuộc tính `strong` (in đậm) và `em` (in nghiêng)**.
     - Khi dùng GoogleFonts `Inter`, nếu không khai báo rõ ràng `strong: AppTypography.body.copyWith(fontWeight: FontWeight.bold)` thì parser có thể kế thừa sai font weight hoặc không áp dụng được độ đậm mong muốn.

---

### 1.2. Bug 2: Format khu vực Reference ở cuối đoạn chat đang bị quá thô
- **Hiện tượng:**
  - Ở cuối mỗi tin nhắn của AI bot, giao diện hiện tại gồm một hàng chip rời rạc, theo sau là một chiếc thẻ hình chữ nhật to, viền đơn điệu, font chữ bị cắt cụt 3 dòng nghiêng.
  - Card này bị **"hardcode"** chỉ hiển thị nguồn đầu tiên (`message.citations.first`), dù câu trả lời có trích dẫn `[1]`, `[2]`, `[4]` hay nhiều nguồn khác nhau. Khi người dùng click vào các chip khác, card bên dưới không hề cập nhật theo!
  - Không có thông tin tên bài báo, không phân biệt rõ ràng các trích dẫn, nhìn giống một khối text thô hơn là một thành phần giao diện chỉn chu của một công cụ nghiên cứu khoa học.

---

## 2. THIẾT KẾ GIẢI PHÁP CHI TIẾT (SOLUTION DESIGN)

### 2.1. Giải pháp cho Bug 1: Chuẩn hóa Markdown & Xử lý sạch Excerpt
1. **Bổ sung đầy đủ style in đậm & in nghiêng vào toàn bộ `MarkdownStyleSheet`:**
   - Trong cả `ReaderPane` và `MessageBubble`:
     ```dart
     strong: AppTypography.body.copyWith(
       fontWeight: FontWeight.bold,
       color: colors.textPrimary,
     ),
     em: AppTypography.body.copyWith(
       fontStyle: FontStyle.italic,
       color: colors.textPrimary,
     ),
     ```
2. **Viết hàm tiền xử lý làm sạch trích đoạn `cleanExcerptForDisplay(String raw)`:**
   - Khi hiển thị đoạn trích dẫn ngắn (snippet/preview):
     - Chuyển đổi các cú pháp cite kỹ thuật như `[\\[1\\]](cite:b0)` thành số trích dẫn sạch `[1]`.
     - Loại bỏ các tiêu đề `#`, `##` ở đầu dòng nếu chỉ cần hiển thị nội dung tóm lược.
     - Giữ nguyên định dạng in đậm `**...**` và in nghiêng `*...*` hợp lệ để hiển thị bằng Markdown mini.
3. **Thay thế toàn bộ widget `Text(excerpt)` bằng `MarkdownBody` siêu nhẹ:**
   - Không ép `fontStyle: FontStyle.italic` cho toàn bộ khối văn bản.
   - Nội dung hiển thị tự nhiên: chữ thường là regular, tiêu đề/tác giả `**Tác giả**` hiển thị in đậm rõ nét.

---

### 2.2. Giải pháp cho Bug 2: Thiết kế lại toàn bộ khu vực Reference ở cuối đoạn chat (Modern References Inspector)

Thay thế cái thẻ thô cứng hiện tại bằng **Modern Source References Card**:

```
┌─────────────────────────────────────────────────────────────────────────────┐
│ 📚 Nguồn trích dẫn (3 tài liệu)                               [Thu gọn ▲]   │
│                                                                             │
│ [ Nguồn [1] • Trang 2 ]   [ Nguồn [2] • Trang 3 ]   [ Nguồn [4] • Trang 7 ] │
│ ─────────────────────────────────────────────────────────────────────────── │
│ 📄 DESC_Surrogate_Turbulence.pdf • Đoạn 3                                   │
│                                                                             │
│ "Tích hợp mô hình AI thay thế cho mô phỏng nhiễu loạn gyrokinetic vào bộ    │
│ tối ưu hóa cân bằng từ trường stellarator (DESC) và bộ giải vận chuyển..."   │
│                                                                             │
│                                       [ 📋 Sao chép ]   [ 🔍 Đến bài báo ➔ ]│
└─────────────────────────────────────────────────────────────────────────────┘
```

#### Các điểm cải tiến vượt bậc:
1. **Interactive Source Tabs / Pills:**
   - Người dùng bấm vào pill nào (`Nguồn [1]`, `Nguồn [2]`, `Nguồn [4]`), nội dung trích đoạn bên dưới lập tức chuyển đổi mượt mà sang nguồn đó với hiệu ứng animation nhẹ nhàng.
2. **Hiển thị đầy đủ ngữ cảnh:**
   - Tên bài báo / tệp tài liệu.
   - Vị trí cụ thể: `Trang X (hoặc Mục Y)`.
   - Toàn văn đoạn trích được format markdown chuẩn xác (in đậm tác giả, công thức toán học nếu có, không bị in nghiêng toàn phần).
3. **Nút tương tác tiện ích:**
   - Nút **"Đến bài báo ➔"**: nhảy ngay lập tức đến đúng trang và vị trí của đoạn trích trên `ReaderPane`.
   - Nút **"Sao chép"**: copy đoạn trích kèm thông tin nguồn vào bộ nhớ tạm.
   - Nút **"Thu gọn / Mở rộng"**: cho phép người dùng ẩn bớt phần nguồn nếu muốn màn hình chat gọn gàng.

---

## 3. CÁC FILE CẦN THAY ĐỔI & PHẠM VI ẢNH HƯỞNG

| File | Nội dung thay đổi |
|:---|:---|
| [message_bubble.dart](file:///d:/Tai_lieu/Ky_8/PRM232/ChatBot/FE/lib/features/chat/widgets/message_bubble.dart) | • Chuyển `MessageBubble` sang StatefulWidget để lưu trữ `selectedCitationIndex` và trạng thái `isExpanded`.<br>• Bổ sung `strong`, `em` vào `MarkdownStyleSheet`.<br>• Thay thế card cũ bằng **Modern Source References Card** đa nguồn.<br>• Nâng cấp `_showCitationPreviewDialog` render bằng `MarkdownBody` và làm sạch cú pháp cite nội bộ. |
| [reader_pane.dart](file:///d:/Tai_lieu/Ky_8/PRM232/ChatBot/FE/lib/features/reader/widgets/reader_pane.dart) | • Bổ sung rõ ràng `strong` và `em` trong `MarkdownStyleSheet` để đảm bảo văn bản bài báo hiển thị in đậm / in nghiêng đồng nhất với font Google Fonts Inter. |
| [citation_chip.dart](file:///d:/Tai_lieu/Ky_8/PRM232/ChatBot/FE/lib/features/chat/widgets/citation_chip.dart) | • Tinh chỉnh giao diện chip active / inactive khi được chọn trong reference bar. |
| [chat_citation_test.dart](file:///d:/Tai_lieu/Ky_8/PRM232/ChatBot/FE/test/chat_citation_test.dart) | • Bổ sung test kiểm tra render in đậm `**`, in nghiêng `*`, và hàm clean excerpt. |

---

## 4. CÁC BƯỚC THỰC HIỆN CỤ THỂ

- **Bước 1:** Bổ sung `strong` và `em` vào `MarkdownStyleSheet` trong [message_bubble.dart](file:///d:/Tai_lieu/Ky_8/PRM232/ChatBot/FE/lib/features/chat/widgets/message_bubble.dart) và [reader_pane.dart](file:///d:/Tai_lieu/Ky_8/PRM232/ChatBot/FE/lib/features/reader/widgets/reader_pane.dart).
- **Bước 2:** Viết hàm tiện ích làm sạch chuỗi markdown thô và giải mã `[\\[X\\]](cite:...)` thành text hiển thị sạch sẽ.
- **Bước 3:** Chuyển đổi [message_bubble.dart](file:///d:/Tai_lieu/Ky_8/PRM232/ChatBot/FE/lib/features/chat/widgets/message_bubble.dart) sang `StatefulWidget` để hỗ trợ tương tác chọn nguồn và đóng/mở khối references.
- **Bước 4:** Xây dựng component giao diện mới cho khối Reference ở cuối tin nhắn bot:
  - Header hiện đại có icon, số lượng nguồn, nút thu gọn.
  - Thanh chọn nguồn (Source Tabs/Pills).
  - Nội dung trích đoạn hiển thị qua `MarkdownBody` với typography thanh lịch.
  - Nút hành động "Đến bài báo" và "Sao chép".
- **Bước 5:** Cập nhật hộp thoại xem trước nguồn `_showCitationPreviewDialog` dùng `MarkdownBody` có style đồng bộ.
- **Bước 6:** Chạy kiểm thử tự động `flutter test` và kiểm tra giao diện trực quan.
