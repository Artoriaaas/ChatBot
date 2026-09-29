# Plan: Citation liên kết được (clickable) trong cả "File gốc" và "Trích xuất AI"

## 1. Mục tiêu
Khi người dùng bấm vào số trích dẫn `[1]`, `[2]`... trong:
- **File gốc** (PDF viewer dùng `pdfrx`)
- **Trang trích xuất AI** (markdown render từ `DocumentSectionDto.Content`)

→ hệ thống điều hướng tới đúng tài liệu tham khảo (nhảy tới mục "References" trong bài hoặc đoạn được nhắc tới).

## 2. Hiện trạng & nguyên nhân chưa làm được

| Vấn đề | Vị trí trong code |
|---|---|
| GROBID có parse `<ref type="bibr" target="#b0">[1]</ref>` nhưng khi flatten text (`ExtractFormattedText`) thì bỏ luôn `target`, chỉ giữ text `[1]` thuần | `GrobidService.ExtractFormattedText`, case `ref` |
| Danh sách tài liệu tham khảo (`<back><listBibl><biblStruct>`) **chưa được parse** thành dữ liệu có cấu trúc — chỉ nằm im trong XML thô | `GrobidService.ParseTeiXmlFull` (không có bước đọc `listBibl`) |
| `consolidateCitations` đang set `"0"` → GROBID không cố gắng resolve DOI/URL cho từng reference | `GrobidService.ProcessPdfFullAsync` |
| FE markdown render (`flutter_markdown_plus`) không có xử lý `onTapLink` cho citation | `ReaderPane`, `MessageBubble` |
| PDF viewer gốc (`pdfrx`) chưa hook vào link annotation / tap detection nào cả | `OriginalPdfViewer` |
| Fallback iText7 (khi GROBID fail) **không có** thông tin ref nào — chỉ là text thô theo trang | `TextExtractionService.ExtractFromPdfFullAsync` |

## 3. Kiến trúc giải pháp

### 3.1. Backend — dữ liệu reference có cấu trúc

**Entity mới** `DocumentReference`:
```
Id, DocumentId, RefKey ("b0","b1"...), Label ("1","2"...),
Title, Authors, Year, Venue, Doi, Url, RawCitationText
```
+ migration tương ứng, `DbSet<DocumentReference>`.

**GrobidService**:
- Thêm bước parse `doc.Descendants(ns+"listBibl").Elements(ns+"biblStruct")` → map thành `DocumentReferenceDto` (title, authors, year, DOI nếu có trong `idno[@type=DOI]`, raw text từ `note[@type=raw_reference]`).
- Bật `consolidateCitations = "1"` (đánh đổi thời gian xử lý lấy độ chính xác DOI) — cân nhắc làm optional flag theo dung lượng file.
- Trong `ExtractFormattedText`, case `ref`: giữ lại `target` (vd `#b0`) và emit marker đặc biệt vào text, ví dụ `[1](cite:b0)` (dạng markdown link) thay vì chỉ `[1]` trơn.

**IndexingService**: sau khi extract xong, lưu list reference vào bảng `DocumentReferences` (song song với việc lưu `structure.json`).

**API mới**: `GET /api/document/{id}/references` → trả `[{ refKey, label, title, authors, year, doi, url }]`.

**Fallback không có GROBID (iText7)**: không có ref structure → FE ẩn tính năng click-citation cho các đoạn này (graceful degrade), không cố gắng đoán.

### 3.2. Frontend — Trang "Trích xuất AI"

- Khi mở paper, gọi thêm API `references`, cache vào `Paper`/`ReaderViewModel`.
- `MarkdownBody` (trong `ReaderPane`) thêm `onTapLink: (text, href, title)`:
  - Nếu `href` bắt đầu bằng `cite:` → parse `refKey` → tra trong list reference đã fetch.
  - Hiện **popover/bottom sheet** dùng chung: số trích dẫn, tiêu đề, tác giả, năm, và:
    - Nút "Mở liên kết" (nếu có `doi`/`url`) → `url_launcher`.
    - Nút "Xem trong bài báo" → cuộn tới mục References (anchor theo `refKey`) trong cùng ReaderPane.
- Thêm section **"References"** tự sinh ở cuối nội dung extract (từ `DocumentReference` list, mỗi mục có `Key(anchor)` = `refKey`) để có chỗ nhảy tới nội bộ, kể cả khi không có link ngoài.

### 3.3. Frontend — "File gốc" (pdfrx)

- Kiểm tra API `pdfrx` cho link annotation (PDF thường đã có hyperlink nhúng sẵn cho `[1]`, đặc biệt file từ arXiv/LaTeX `hyperref`).
- Thêm tap-detection: khi user tap lên trang PDF, hit-test tọa độ với danh sách link annotation của trang đó:
  - Link ngoài (URI) → mở bằng `url_launcher`.
  - Link nội bộ (destination page) → `_pdfController.goToPage(...)`.
- Nếu PDF không có link nhúng (scan/không có `hyperref`) → **không cố suy đoán vị trí** ở giai đoạn 1 (rủi ro cao, độ chính xác thấp) — để phase sau nếu cần.

## 4. Các giai đoạn triển khai

| Giai đoạn | Nội dung | Ghi chú |
|---|---|---|
| **P0** | Entity + migration + parse `listBibl` trong `GrobidService` + API `/references` | Nền tảng, không đổi UI |
| **P1** | Trích xuất AI: giữ `target` khi extract, render citation chip clickable + reference popover + mục References cuối trang | Giá trị người dùng thấy được đầu tiên |
| **P2** | File gốc: tap-to-link dựa trên PDF link annotation có sẵn | Phụ thuộc khả năng `pdfrx` expose link — cần verify trước |
| **P3 (tuỳ chọn)** | Resolve DOI qua CrossRef cho ref không có DOI trong XML; heuristic match vị trí `[n]` trong PDF không có link nhúng | Rủi ro/độ phức tạp cao, làm sau nếu cần |

## 5. Rủi ro & điểm cần xác nhận trước khi code
1. `pdfrx` có expose API lấy link annotation theo trang không (cần đọc doc/API trước khi cam kết P2).
2. Fallback iText7 sẽ không hỗ trợ tính năng này → cần UI báo "Không có dữ liệu trích dẫn" thay vì im lặng lỗi.
3. Bật `consolidateCitations=1` làm chậm GROBID — cần đo lại thời gian xử lý trên file thật.
4. Không phải PDF nào cũng có hyperlink nhúng cho `[n]` → tính năng ở "File gốc" sẽ không phủ 100% tài liệu ngay từ đầu.

## 6. Tiêu chí hoàn thành (P0+P1, phạm vi tối thiểu khả dụng)
- Upload paper mới qua GROBID → bảng `DocumentReferences` có dữ liệu.
- Trong trang "Trích xuất AI", bấm `[1]` → hiện popover đúng reference, có thể mở link ngoài (nếu có) hoặc nhảy tới mục References.
- Paper cũ (đã index trước đó) hiển thị mượt, không crash — chỉ đơn giản không có citation click (chưa có data reference).
