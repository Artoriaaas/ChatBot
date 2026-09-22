using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Http;
using ServiceLayer.Interfaces;
using Microsoft.Extensions.Caching.Memory;
using System.Threading.Tasks;
using System;

namespace ChatBot.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class DocumentController : ControllerBase
    {
        private readonly IDocumentService _documentService;
        private readonly IDocumentChunkService _documentChunkService;
        private readonly IMemoryCache _cache;

        public DocumentController(
            IDocumentService documentService,
            IDocumentChunkService documentChunkService,
            IMemoryCache cache)
        {
            _documentService = documentService;
            _documentChunkService = documentChunkService;
            _cache = cache;
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

            var chunks = await _documentChunkService.GetDocumentChunksByDocumentIdAsync(id);
            return Ok(chunks.Select(chunk => new
            {
                chunkOrder = chunk.ChunkOrder,
                content = chunk.Content
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
