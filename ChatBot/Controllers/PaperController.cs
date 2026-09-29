using BusinessObject.Dtos;
using BusinessObject.Entities;
using DataAccessLayer;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using ServiceLayer.Interfaces;
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text.Json;
using System.Text.RegularExpressions;
using System.Threading.Tasks;

namespace ChatBot.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class PaperController : ControllerBase
    {
        private readonly IPaperService _paperService;
        private readonly AppDbContext _context;

        public PaperController(IPaperService paperService, AppDbContext context)
        {
            _paperService = paperService;
            _context = context;
        }

        [HttpGet("{id}/references")]
        public async Task<IActionResult> GetPaperReferences(int id)
        {
            try
            {
                var paper = await _paperService.GetByIdAsync(id);
                if (paper == null)
                    return NotFound(new { message = "Không tìm thấy bài báo." });

                if (!paper.DocumentId.HasValue)
                {
                    return Ok(new List<DocumentReferenceDto>());
                }

                int docId = paper.DocumentId.Value;

                // 1. Lấy từ bảng DocumentReferences trong CSDL
                var dbRefs = await _context.DocumentReferences
                    .Where(r => r.DocumentId == docId)
                    .OrderBy(r => r.Id)
                    .Select(r => new DocumentReferenceDto
                    {
                        RefKey = r.RefKey,
                        Label = r.Label,
                        Title = r.Title,
                        Authors = r.Authors,
                        Year = r.Year,
                        Venue = r.Venue,
                        Doi = r.Doi,
                        Url = r.Url,
                        RawCitationText = r.RawCitationText
                    })
                    .ToListAsync();

                if (dbRefs.Count > 0)
                {
                    return Ok(dbRefs);
                }

                // 2. Fallback: đọc từ file sidecar .references.json nếu có
                var filePath = paper.FilePath;
                if (string.IsNullOrWhiteSpace(filePath) || !System.IO.File.Exists(filePath))
                {
                    if (paper.Document != null && !string.IsNullOrWhiteSpace(paper.Document.FilePath))
                    {
                        filePath = paper.Document.FilePath;
                    }
                }

                if (!string.IsNullOrEmpty(filePath))
                {
                    var refsPath = filePath + ".references.json";
                    if (System.IO.File.Exists(refsPath))
                    {
                        try
                        {
                            var json = await System.IO.File.ReadAllTextAsync(refsPath);
                            var refs = JsonSerializer.Deserialize<List<DocumentReferenceDto>>(json, new JsonSerializerOptions
                            {
                                PropertyNameCaseInsensitive = true
                            });
                            if (refs != null && refs.Count > 0)
                            {
                                return Ok(refs);
                            }
                        }
                        catch (Exception ex)
                        {
                            Console.WriteLine($"[PaperController] Lỗi đọc references.json cho Paper {id}: {ex.Message}");
                        }
                    }
                }

                // 3. Fallback: Parse từ section References trong .structure.json hoặc DocumentChunks
                try
                {
                    string? refContent = null;
                    if (!string.IsNullOrEmpty(filePath))
                    {
                        var structPath = filePath + ".structure.json";
                        if (System.IO.File.Exists(structPath))
                        {
                            var sJson = await System.IO.File.ReadAllTextAsync(structPath);
                            var sections = JsonSerializer.Deserialize<List<DocumentSectionDto>>(sJson, new JsonSerializerOptions { PropertyNameCaseInsensitive = true });
                            var refSection = sections?.FirstOrDefault(s => s.Title.Contains("Reference", StringComparison.OrdinalIgnoreCase) || s.Title.Contains("Tài liệu tham khảo", StringComparison.OrdinalIgnoreCase));
                            refContent = refSection?.Content;
                        }
                    }
                    if (string.IsNullOrEmpty(refContent) && paper.DocumentId.HasValue)
                    {
                        var chunk = await _context.DocumentChunks
                            .Where(c => c.DocumentId == paper.DocumentId.Value && (c.Content.Contains("Reference") || c.Content.Contains("Tài liệu tham khảo")))
                            .FirstOrDefaultAsync();
                        refContent = chunk?.Content;
                    }

                    if (!string.IsNullOrWhiteSpace(refContent))
                    {
                        var parsedRefs = ParseReferencesFromContent(refContent);
                        if (parsedRefs.Count > 0 && paper.DocumentId.HasValue)
                        {
                            try
                            {
                                var entities = parsedRefs.Select(r => new BusinessObject.Entities.DocumentReference
                                {
                                    DocumentId = paper.DocumentId.Value,
                                    RefKey = r.RefKey,
                                    Label = r.Label,
                                    Title = r.Title,
                                    Authors = r.Authors,
                                    Year = r.Year,
                                    Venue = r.Venue,
                                    Doi = r.Doi,
                                    Url = r.Url,
                                    RawCitationText = r.RawCitationText
                                }).ToList();
                                await _context.DocumentReferences.AddRangeAsync(entities);
                                await _context.SaveChangesAsync();
                            }
                            catch { }
                            return Ok(parsedRefs);
                        }
                    }
                }
                catch (Exception ex)
                {
                    Console.WriteLine($"[PaperController] Lỗi fallback parse references cho Paper {id}: {ex.Message}");
                }

                return Ok(new List<DocumentReferenceDto>());
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = ex.Message });
            }
        }

        [HttpGet]
        public async Task<IActionResult> GetPapers(
            [FromQuery] string? search = null,
            [FromQuery] string? collection = null,
            [FromQuery] string? tag = null,
            [FromQuery] bool? isFavorite = null,
            [FromQuery] string? sort = null)
        {
            try
            {
                var papers = await _paperService.GetPapersAsync(search, collection, tag, isFavorite, sort);
                return Ok(papers);
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = ex.Message });
            }
        }

        [HttpGet("{id}")]
        public async Task<IActionResult> GetPaper(int id)
        {
            try
            {
                var paper = await _paperService.GetByIdAsync(id);
                if (paper == null)
                    return NotFound(new { message = "Không tìm thấy bài báo." });

                return Ok(paper);
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = ex.Message });
            }
        }

        [HttpPost("upload")]
        public async Task<IActionResult> UploadPaper(
            IFormFile file,
            [FromForm] string? title = null,
            [FromForm] string? authors = null,
            [FromForm] int? year = null,
            [FromForm] string? collection = null,
            [FromForm] string? tags = null,
            [FromForm] string? abstractText = null)
        {
            if (file == null || file.Length == 0)
                return BadRequest(new { message = "Vui lòng chọn file tải lên." });

            try
            {
                var (success, message, paperId) = await _paperService.UploadPaperAsync(
                    file, title, authors, year, collection, tags, abstractText);

                if (!success)
                    return BadRequest(new { message });

                var paper = await _paperService.GetByIdAsync(paperId);
                return Ok(new { paperId, documentId = paper?.DocumentId, message });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = ex.Message });
            }
        }

        [HttpGet("{id}/metadata")]
        public async Task<IActionResult> GetPaperMetadata(int id)
        {
            try
            {
                var paper = await _paperService.GetByIdAsync(id);
                if (paper == null)
                    return NotFound(new { message = "Không tìm thấy bài báo." });

                return Ok(new
                {
                    paper.Id,
                    paper.Title,
                    paper.Authors,
                    paper.Year,
                    paper.Journal,
                    paper.Publisher,
                    paper.Doi,
                    paper.Volume,
                    paper.Issue,
                    paper.Pages,
                    paper.AbstractText,
                    paper.Keywords,
                    paper.Tags,
                    paper.Collection,
                    paper.TotalPages,
                    paper.IndexStatus,
                    paper.CreatedAt,
                    paper.FileSize
                });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = ex.Message });
            }
        }

        [HttpGet("{id}/file")]
        public async Task<IActionResult> GetPaperFile(int id, [FromQuery] bool download = false)
        {
            try
            {
                var paper = await _paperService.GetByIdAsync(id);
                if (paper == null)
                    return NotFound(new { message = "Không tìm thấy bài báo." });

                var filePath = paper.FilePath;
                if (string.IsNullOrWhiteSpace(filePath) || !System.IO.File.Exists(filePath))
                {
                    if (paper.Document != null && !string.IsNullOrWhiteSpace(paper.Document.FilePath) && System.IO.File.Exists(paper.Document.FilePath))
                    {
                        filePath = paper.Document.FilePath;
                    }
                }

                if (string.IsNullOrWhiteSpace(filePath) || !System.IO.File.Exists(filePath))
                {
                    return NotFound(new { message = "File tài liệu gốc không tồn tại trên hệ thống lưu trữ." });
                }

                var ext = Path.GetExtension(filePath).ToLowerInvariant();
                var contentType = ext switch
                {
                    ".pdf" => "application/pdf",
                    ".docx" => "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
                    ".doc" => "application/msword",
                    ".pptx" => "application/vnd.openxmlformats-officedocument.presentationml.presentation",
                    ".ppt" => "application/vnd.ms-powerpoint",
                    _ => "application/octet-stream"
                };

                var rawTitle = string.IsNullOrWhiteSpace(paper.Title)
                    ? Path.GetFileNameWithoutExtension(filePath)
                    : paper.Title.Trim();
                var safeTitle = string.Concat(rawTitle.Split(Path.GetInvalidFileNameChars()));
                var fileName = $"{safeTitle}{ext}";

                if (download)
                {
                    return PhysicalFile(filePath, contentType, fileName, enableRangeProcessing: true);
                }

                Response.Headers.Append("Content-Disposition", $"inline; filename=\"{fileName}\"");
                return PhysicalFile(filePath, contentType, enableRangeProcessing: true);
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = $"Lỗi khi tải file: {ex.Message}" });
            }
        }

        [HttpPut("{id}")]
        public async Task<IActionResult> UpdatePaper(int id, [FromBody] Paper paper)
        {
            try
            {
                paper.Id = id;
                var (success, message) = await _paperService.SavePaperAsync(paper);
                if (!success)
                    return BadRequest(new { message });

                return Ok(new { message, paper });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = ex.Message });
            }
        }

        [HttpPost]
        public async Task<IActionResult> SavePaper([FromBody] Paper paper)
        {
            try
            {
                var (success, message) = await _paperService.SavePaperAsync(paper);
                if (!success)
                    return BadRequest(new { message });

                return Ok(new { message, paper });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = ex.Message });
            }
        }

        [HttpPatch("{id}/favorite")]
        public async Task<IActionResult> ToggleFavorite(int id)
        {
            try
            {
                var (success, message) = await _paperService.ToggleFavoriteAsync(id);
                if (!success)
                    return NotFound(new { message });

                return Ok(new { message });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = ex.Message });
            }
        }

        [HttpDelete("{id}")]
        public async Task<IActionResult> DeletePaper(int id)
        {
            try
            {
                var (success, message) = await _paperService.DeletePaperAsync(id);
                if (!success)
                    return NotFound(new { message });

                return Ok(new { message });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = ex.Message });
            }
        }

        private static List<DocumentReferenceDto> ParseReferencesFromContent(string content)
        {
            var list = new List<DocumentReferenceDto>();
            if (string.IsNullOrWhiteSpace(content)) return list;

            var lines = content.Split(new[] { "\r\n", "\r", "\n" }, StringSplitOptions.RemoveEmptyEntries);
            var regex = new Regex(@"^(?:<a\s+id=""ref-([^""]+)"">\s*</a>)?(?:\*\*)?\[([0-9A-Za-z]+)\](?:\*\*)?\s*(.*)$", RegexOptions.IgnoreCase);

            int idx = 1;
            foreach (var line in lines)
            {
                var trimmed = line.Trim();
                if (string.IsNullOrEmpty(trimmed)) continue;

                var match = regex.Match(trimmed);
                if (match.Success)
                {
                    var refKey = match.Groups[1].Success && !string.IsNullOrEmpty(match.Groups[1].Value)
                        ? match.Groups[1].Value
                        : $"b{idx - 1}";
                    var label = match.Groups[2].Value;
                    var body = match.Groups[3].Value.Trim();

                    body = Regex.Replace(body, @"<a\s+id=""[^""]*"">\s*</a>", "", RegexOptions.IgnoreCase).Trim();

                    int? year = null;
                    var yMatch = Regex.Match(body, @"\((\d{4})\)");
                    if (yMatch.Success && int.TryParse(yMatch.Groups[1].Value, out int yr))
                    {
                        year = yr;
                    }

                    string? url = null;
                    string? doi = null;

                    var doiMatch = Regex.Match(body, @"\b(10\.\d{4,9}/[-._;()/:A-Za-z0-9]+)\b");
                    if (doiMatch.Success)
                    {
                        doi = doiMatch.Groups[1].Value.TrimEnd('.', ',');
                        url = $"https://doi.org/{doi}";
                    }

                    var arxMatch = Regex.Match(body, @"\barXiv[:\s/]+([0-9]{4}\.[0-9]{4,5}(?:v[0-9]+)?|[a-z\-]+(?:\.[a-z]{2})?/[0-9]{7})\b", RegexOptions.IgnoreCase);
                    if (arxMatch.Success)
                    {
                        var arxId = arxMatch.Groups[1].Value;
                        url = $"https://arxiv.org/abs/{arxId}";
                    }

                    list.Add(new DocumentReferenceDto
                    {
                        RefKey = refKey,
                        Label = label,
                        Title = body,
                        Year = year,
                        Doi = doi,
                        Url = url,
                        RawCitationText = body
                    });
                    idx++;
                }
            }

            return list;
        }
    }
}
