using BusinessObject.Dtos;
using ServiceLayer.Interfaces;
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using System.Text.RegularExpressions;
using System.Threading.Tasks;

namespace ServiceLayer.Implements
{
    public class TextExtractionService : ITextExtractionService
    {
        private readonly IGrobidService _grobidService;

        public TextExtractionService(IGrobidService grobidService)
        {
            _grobidService = grobidService;
        }

        public async Task<(bool success, string? text, string? errorMessage)> ExtractTextAsync(string filePath)
        {
            var result = await ExtractDocumentFullAsync(filePath);
            return (result.Success, result.FullText, result.ErrorMessage);
        }

        public async Task<ExtractedDocumentResult> ExtractDocumentFullAsync(string filePath)
        {
            try
            {
                if (!File.Exists(filePath))
                {
                    return new ExtractedDocumentResult
                    {
                        Success = false,
                        ErrorMessage = "Không tìm thấy tệp tài liệu trên đĩa."
                    };
                }

                var extension = Path.GetExtension(filePath).ToLower();
                return extension switch
                {
                    ".pdf" => await ExtractFromPdfFullAsync(filePath),
                    ".docx" => ExtractFromDocxFull(filePath),
                    ".pptx" => ExtractFromPptxFull(filePath),
                    ".doc" => new ExtractedDocumentResult
                    {
                        Success = false,
                        ErrorMessage = "Định dạng DOC legacy chưa được hỗ trợ. Vui lòng chuyển sang định dạng PDF hoặc DOCX."
                    },
                    _ => new ExtractedDocumentResult
                    {
                        Success = false,
                        ErrorMessage = $"Định dạng tệp không được hỗ trợ: {extension}"
                    }
                };
            }
            catch (Exception ex)
            {
                return new ExtractedDocumentResult
                {
                    Success = false,
                    ErrorMessage = $"Lỗi trích xuất tài liệu: {ex.Message}"
                };
            }
        }

        private async Task<ExtractedDocumentResult> ExtractFromPdfFullAsync(string filePath)
        {
            // 1. Thử gọi dịch vụ GROBID trước
            try
            {
                using var stream = File.OpenRead(filePath);
                var grobidResult = await _grobidService.ProcessPdfFullAsync(stream);

                if (grobidResult.Success && !string.IsNullOrWhiteSpace(grobidResult.FullText) && grobidResult.Sections.Count > 0)
                {
                    Console.WriteLine($"[TextExtraction] 🎯 Đã sử dụng thành công GROBID để bóc tách bài báo '{Path.GetFileName(filePath)}' ({grobidResult.Sections.Count} sections).");
                    return grobidResult;
                }
                else
                {
                    Console.WriteLine($"[TextExtraction] ⚠️ GROBID không trích xuất được nội dung hợp lệ ({grobidResult.ErrorMessage}). Tự động kích hoạt iText7 Smart Fallback...");
                }
            }
            catch (Exception ex)
            {
                Console.WriteLine($"[TextExtraction] ⚠️ Gọi GROBID thất bại: {ex.Message}. Kích hoạt chế độ dự phòng iText7...");
            }

            // 2. Chế độ dự phòng thông minh iText7 (bảo toàn cấu trúc trang & phân đoạn văn bản)
            try
            {
                var sections = new List<DocumentSectionDto>();
                var fullTextBuilder = new StringBuilder();
                int totalPages = 0;

                using (var pdfReader = new iText.Kernel.Pdf.PdfReader(filePath))
                using (var pdfDoc = new iText.Kernel.Pdf.PdfDocument(pdfReader))
                {
                    totalPages = pdfDoc.GetNumberOfPages();

                    for (int pageNum = 1; pageNum <= totalPages; pageNum++)
                    {
                        var page = pdfDoc.GetPage(pageNum);
                        var rawText = iText.Kernel.Pdf.Canvas.Parser.PdfTextExtractor.GetTextFromPage(page);

                        if (string.IsNullOrWhiteSpace(rawText))
                            continue;

                        // Chuẩn hóa văn bản trang: gom dòng, giữ nguyên ngắt đoạn
                        var formattedPageContent = FormatPageText(rawText, out string? detectedHeading);
                        var sectionTitle = !string.IsNullOrWhiteSpace(detectedHeading) 
                            ? detectedHeading 
                            : $"Trang {pageNum}";

                        sections.Add(new DocumentSectionDto
                        {
                            SectionOrder = pageNum - 1,
                            Title = sectionTitle,
                            Content = formattedPageContent
                        });

                        fullTextBuilder.AppendLine($"## {sectionTitle}\n");
                        fullTextBuilder.AppendLine(formattedPageContent);
                        fullTextBuilder.AppendLine();
                    }
                }

                if (sections.Count == 0)
                {
                    return new ExtractedDocumentResult
                    {
                        Success = false,
                        ErrorMessage = "Tệp PDF không chứa văn bản có thể trích xuất (có thể là file scan hoặc ảnh)."
                    };
                }

                var titleCandidate = sections.FirstOrDefault()?.Title != null && !sections[0].Title.StartsWith("Trang ")
                    ? sections[0].Title
                    : Path.GetFileNameWithoutExtension(filePath);

                return new ExtractedDocumentResult
                {
                    Success = true,
                    Title = titleCandidate,
                    FullText = fullTextBuilder.ToString().Trim(),
                    Sections = sections,
                    TotalPages = totalPages,
                    ExtractionEngine = "iText7 (Fallback)"
                };
            }
            catch (Exception ex)
            {
                return new ExtractedDocumentResult
                {
                    Success = false,
                    ErrorMessage = $"Trích xuất PDF thất bại qua cả GROBID & iText7: {ex.Message}"
                };
            }
        }

        private ExtractedDocumentResult ExtractFromDocxFull(string filePath)
        {
            try
            {
                var sections = new List<DocumentSectionDto>();
                var currentSectionContent = new StringBuilder();
                string currentSectionTitle = "Phần mở đầu";
                int sectionOrder = 0;
                string? docTitle = null;

                using (var doc = DocumentFormat.OpenXml.Packaging.WordprocessingDocument.Open(filePath, false))
                {
                    var body = doc.MainDocumentPart?.Document?.Body;
                    if (body != null)
                    {
                        foreach (var para in body.Descendants<DocumentFormat.OpenXml.Wordprocessing.Paragraph>())
                        {
                            var text = string.Join("", para.Descendants<DocumentFormat.OpenXml.Wordprocessing.Text>().Select(t => t.Text)).Trim();
                            if (string.IsNullOrWhiteSpace(text))
                                continue;

                            // Kiểm tra xem đoạn văn có phải Heading không
                            var styleId = para.ParagraphProperties?.ParagraphStyleId?.Val?.Value ?? "";
                            bool isHeading = styleId.StartsWith("Heading", StringComparison.OrdinalIgnoreCase) 
                                             || styleId.Equals("Title", StringComparison.OrdinalIgnoreCase)
                                             || (text.Length < 70 && Regex.IsMatch(text, @"^(Chương|Bài|Mục|\d+(\.\d+)*)\s+", RegexOptions.IgnoreCase));

                            if (isHeading)
                            {
                                if (docTitle == null && (styleId.Equals("Title", StringComparison.OrdinalIgnoreCase) || sectionOrder == 0))
                                {
                                    docTitle = text;
                                }

                                if (currentSectionContent.Length > 0)
                                {
                                    sections.Add(new DocumentSectionDto
                                    {
                                        SectionOrder = sectionOrder++,
                                        Title = currentSectionTitle,
                                        Content = currentSectionContent.ToString().Trim()
                                    });
                                    currentSectionContent.Clear();
                                }
                                currentSectionTitle = text;
                            }
                            else
                            {
                                currentSectionContent.AppendLine(text);
                                currentSectionContent.AppendLine(); // Giữ ngắt đoạn văn \n\n
                            }
                        }

                        if (currentSectionContent.Length > 0)
                        {
                            sections.Add(new DocumentSectionDto
                            {
                                SectionOrder = sectionOrder++,
                                Title = currentSectionTitle,
                                Content = currentSectionContent.ToString().Trim()
                            });
                        }
                    }
                }

                if (sections.Count == 0)
                {
                    return new ExtractedDocumentResult
                    {
                        Success = false,
                        ErrorMessage = "Tệp Word (DOCX) không chứa nội dung văn bản."
                    };
                }

                var fullTextBuilder = new StringBuilder();
                foreach (var s in sections)
                {
                    fullTextBuilder.AppendLine($"## {s.Title}\n");
                    fullTextBuilder.AppendLine(s.Content);
                    fullTextBuilder.AppendLine();
                }

                return new ExtractedDocumentResult
                {
                    Success = true,
                    Title = docTitle ?? Path.GetFileNameWithoutExtension(filePath),
                    FullText = fullTextBuilder.ToString().Trim(),
                    Sections = sections,
                    TotalPages = Math.Max(1, sections.Count),
                    ExtractionEngine = "OpenXml (DOCX)"
                };
            }
            catch (Exception ex)
            {
                return new ExtractedDocumentResult
                {
                    Success = false,
                    ErrorMessage = $"Lỗi đọc tệp DOCX: {ex.Message}"
                };
            }
        }

        private ExtractedDocumentResult ExtractFromPptxFull(string filePath)
        {
            try
            {
                var sections = new List<DocumentSectionDto>();
                var fullTextBuilder = new StringBuilder();
                int slideIndex = 0;

                using (var pptx = DocumentFormat.OpenXml.Packaging.PresentationDocument.Open(filePath, false))
                {
                    var pPart = pptx.PresentationPart;
                    if (pPart?.SlideParts != null)
                    {
                        foreach (var slidePart in pPart.SlideParts)
                        {
                            slideIndex++;
                            var slide = slidePart.Slide;
                            var shapes = slide?.CommonSlideData?.ShapeTree?.Descendants<DocumentFormat.OpenXml.Presentation.Shape>();
                            
                            string? slideTitle = null;
                            var slideBody = new StringBuilder();

                            if (shapes != null)
                            {
                                foreach (var shape in shapes)
                                {
                                    if (shape.TextBody != null)
                                    {
                                        var paras = shape.TextBody.Descendants<DocumentFormat.OpenXml.Drawing.Paragraph>();
                                        foreach (var para in paras)
                                        {
                                            var txt = string.Join("", para.Descendants<DocumentFormat.OpenXml.Drawing.Text>().Select(t => t.Text)).Trim();
                                            if (string.IsNullOrWhiteSpace(txt)) continue;

                                            if (slideTitle == null && txt.Length < 100)
                                            {
                                                slideTitle = txt;
                                            }
                                            else
                                            {
                                                slideBody.AppendLine($"- {txt}");
                                            }
                                        }
                                    }
                                }
                            }

                            var title = slideTitle ?? $"Slide {slideIndex}";
                            var content = slideBody.Length > 0 ? slideBody.ToString().Trim() : "(Nội dung hình ảnh hoặc sơ đồ)";

                            sections.Add(new DocumentSectionDto
                            {
                                SectionOrder = slideIndex - 1,
                                Title = title,
                                Content = content
                            });

                            fullTextBuilder.AppendLine($"## {title}\n");
                            fullTextBuilder.AppendLine(content);
                            fullTextBuilder.AppendLine();
                        }
                    }
                }

                if (sections.Count == 0)
                {
                    return new ExtractedDocumentResult
                    {
                        Success = false,
                        ErrorMessage = "Tệp PowerPoint (PPTX) không chứa nội dung slide."
                    };
                }

                return new ExtractedDocumentResult
                {
                    Success = true,
                    Title = sections.FirstOrDefault()?.Title ?? Path.GetFileNameWithoutExtension(filePath),
                    FullText = fullTextBuilder.ToString().Trim(),
                    Sections = sections,
                    TotalPages = slideIndex,
                    ExtractionEngine = "OpenXml (PPTX)"
                };
            }
            catch (Exception ex)
            {
                return new ExtractedDocumentResult
                {
                    Success = false,
                    ErrorMessage = $"Lỗi đọc tệp PPTX: {ex.Message}"
                };
            }
        }

        private static string FormatPageText(string rawText, out string? detectedHeading)
        {
            detectedHeading = null;
            if (string.IsNullOrWhiteSpace(rawText)) return string.Empty;

            var lines = rawText.Split(new[] { "\r\n", "\r", "\n" }, StringSplitOptions.None)
                .Select(l => l.Trim())
                .ToList();

            var paragraphs = new List<string>();
            var currentPara = new StringBuilder();

            foreach (var line in lines)
            {
                if (string.IsNullOrWhiteSpace(line))
                {
                    if (currentPara.Length > 0)
                    {
                        paragraphs.Add(currentPara.ToString().Trim());
                        currentPara.Clear();
                    }
                    continue;
                }

                // Phát hiện dòng tiêu đề ngắn ở đầu trang
                if (detectedHeading == null && line.Length >= 4 && line.Length <= 80 && !Regex.IsMatch(line, @"^\d+$"))
                {
                    detectedHeading = line;
                }

                if (currentPara.Length > 0)
                {
                    // Nếu dòng trước kết thúc bằng dấu nối từ '-', nối liền
                    if (currentPara.ToString().EndsWith("-"))
                    {
                        currentPara.Length -= 1;
                        currentPara.Append(line);
                    }
                    else
                    {
                        currentPara.Append(" ");
                        currentPara.Append(line);
                    }
                }
                else
                {
                    currentPara.Append(line);
                }
            }

            if (currentPara.Length > 0)
            {
                paragraphs.Add(currentPara.ToString().Trim());
            }

            return string.Join("\n\n", paragraphs);
        }
    }
}
