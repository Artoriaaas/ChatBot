using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Http;
using ServiceLayer.Interfaces;
using Microsoft.Extensions.Caching.Memory;
using System.Threading.Tasks;
using System;
using System.IO;
using System.Linq;
using System.Collections.Generic;
using System.Text.Json;
using System.Text.RegularExpressions;
using BusinessObject.Dtos;

namespace ChatBot.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class DocumentController : ControllerBase
    {
        private readonly IDocumentService _documentService;
        private readonly IDocumentChunkService _documentChunkService;
        private readonly IGrobidService _grobidService;
        private readonly ITextExtractionService _textExtractionService;
        private readonly IMemoryCache _cache;

        public DocumentController(
            IDocumentService documentService,
            IDocumentChunkService documentChunkService,
            IGrobidService grobidService,
            ITextExtractionService textExtractionService,
            IMemoryCache cache)
        {
            _documentService = documentService;
            _documentChunkService = documentChunkService;
            _grobidService = grobidService;
            _textExtractionService = textExtractionService;
            _cache = cache;
        }

        [HttpGet("grobid-status")]
        public async Task<IActionResult> GetGrobidStatus()
        {
            var isAlive = await _grobidService.IsAliveAsync();
            var baseUrl = _grobidService.GetGrobidBaseUrl();
            return Ok(new
            {
                isAlive,
                grobidUrl = baseUrl,
                message = isAlive
                    ? "Dịch vụ GROBID đang chạy và sẵn sàng xử lý tài liệu."
                    : $"Dịch vụ GROBID chưa kết nối được tại {baseUrl} (Hệ thống sẽ dùng iText7 Smart Fallback)."
            });
        }

        [HttpGet("test-extract")]
        public async Task<IActionResult> TestExtract([FromQuery] string? filePath)
        {
            var path = filePath ?? @"D:\Upload\33282706-daf5-4713-bc51-1400ee00734f_GROBID_TEST.pdf";
            var result = await _textExtractionService.ExtractDocumentFullAsync(path);
            return Ok(new
            {
                success = result.Success,
                engine = result.ExtractionEngine,
                title = result.Title,
                authors = result.Authors,
                abstractText = result.AbstractText,
                sectionsCount = result.Sections.Count,
                sections = result.Sections.Select(s => new
                {
                    order = s.SectionOrder,
                    title = s.Title,
                    preview = s.Content.Length > 150 ? s.Content[..150] + "..." : s.Content
                }),
                errorMessage = result.ErrorMessage
            });
        }

        [HttpGet("{id}/progress")]
        public async Task<IActionResult> GetProgress(int id)
        {
            var document = await _documentService.GetByIdAsync(id);
            if (document == null)
                return NotFound(new { message = "Không tìm thấy tài liệu." });

            var progress = _cache.TryGetValue($"doc_progress_{id}", out int cachedProgress)
                ? cachedProgress
                : document.IndexStatus == "Completed" ? 100 : 0;

            return Ok(new
            {
                documentId = document.Id,
                status = document.IndexStatus,
                progress,
                errorMessage = document.ErrorMessage
            });
        }

        [HttpGet("{id}/chunks")]
        public async Task<IActionResult> GetChunks(int id)
        {
            var document = await _documentService.GetByIdAsync(id);
            if (document == null)
                return NotFound(new { message = "Không tìm thấy tài liệu." });

            // 1. Kiểm tra xem có cấu trúc sections chuẩn từ file sidecar (.structure.json) không
            if (!string.IsNullOrEmpty(document.FilePath))
            {
                var structurePath = document.FilePath + ".structure.json";
                if (System.IO.File.Exists(structurePath))
                {
                    try
                    {
                        var json = await System.IO.File.ReadAllTextAsync(structurePath);
                        var sections = JsonSerializer.Deserialize<List<DocumentSectionDto>>(json, new JsonSerializerOptions
                        {
                            PropertyNameCaseInsensitive = true
                        });

                        if (sections != null && sections.Count > 0)
                        {
                            return Ok(sections.Select(s => new
                            {
                                chunkOrder = s.SectionOrder,
                                sectionTitle = s.Title,
                                content = s.Content
                            }));
                        }
                    }
                    catch (Exception ex)
                    {
                        Console.WriteLine($"[DocumentController] Lỗi đọc structure.json cho Doc {id}: {ex.Message}");
                    }
                }
            }

            // 2. Fallback: Lấy từ bảng DocumentChunks trong cơ sở dữ liệu
            var chunks = await _documentChunkService.GetDocumentChunksByDocumentIdAsync(id);
            return Ok(chunks.Select(chunk =>
            {
                string sectionTitle = $"Mục {chunk.ChunkOrder + 1}";
                
                // Cố gắng dò tiêu đề từ dòng đầu tiên nếu có heading markdown (## hoặc ###)
                var firstLine = chunk.Content?.Split('\n').FirstOrDefault()?.Trim() ?? "";
                if (firstLine.StartsWith("#"))
                {
                    sectionTitle = firstLine.TrimStart('#').Trim();
                }

                return new
                {
                    chunkOrder = chunk.ChunkOrder,
                    sectionTitle = sectionTitle,
                    content = chunk.Content
                };
            }));
        }

        [HttpPost("upload")]
        public async Task<IActionResult> UploadDocument(IFormFile file)
        {
            if (file == null || file.Length == 0)
                return BadRequest(new { message = "File is required." });

            try
            {
                var (success, message, documentId) = await _documentService.UploadDocumentAsync(file);
                
                if (!success)
                {
                    return BadRequest(new { message });
                }

                return Ok(new { documentId, message });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = ex.Message });
            }
        }

        [HttpGet]
        public async Task<IActionResult> GetDocuments()
        {
            try
            {
                var docs = await _documentService.GetDocumentsAsync();
                return Ok(docs);
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = ex.Message });
            }
        }

        [HttpPost("{id}/reindex")]
        public async Task<IActionResult> ReindexDocument(int id)
        {
            try
            {
                var (success, message) = await _documentService.ReindexDocumentAsync(id);
                if (!success)
                {
                    return NotFound(new { message });
                }
                
                return Ok(new { message });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = ex.Message });
            }
        }

        [HttpDelete("{id}")]
        public async Task<IActionResult> DeleteDocument(int id)
        {
            try
            {
                var (success, message) = await _documentService.DeleteDocumentAsync(id);
                if (!success)
                {
                    return NotFound(new { message });
                }
                return Ok(new { message });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = ex.Message });
            }
        }
    }
}
