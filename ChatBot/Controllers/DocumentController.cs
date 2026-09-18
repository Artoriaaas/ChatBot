using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Http;
using ServiceLayer.Interfaces;
using System.Threading.Tasks;
using System;

namespace ChatBot.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class DocumentController : ControllerBase
    {
        private readonly IDocumentService _documentService;

        public DocumentController(IDocumentService documentService)
        {
            _documentService = documentService;
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
