using BusinessObject.Entities;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using ServiceLayer.Interfaces;
using System;
using System.Threading.Tasks;

namespace ChatBot.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class PaperController : ControllerBase
    {
        private readonly IPaperService _paperService;

        public PaperController(IPaperService paperService)
        {
            _paperService = paperService;
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
    }
}
