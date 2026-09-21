using Microsoft.AspNetCore.Mvc;
using ServiceLayer.Interfaces;
using BusinessObject.Entities;
using System;
using System.Threading.Tasks;

namespace ChatBot.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class ChatController : ControllerBase
    {
        private readonly IRagService _ragService;
        private readonly IChatHistoryService _chatHistoryService;

        public ChatController(IRagService ragService, IChatHistoryService chatHistoryService)
        {
            _ragService = ragService;
            _chatHistoryService = chatHistoryService;
        }

        public class AskRequestDto
        {
            public string Question { get; set; } = string.Empty;
            public Guid? SubjectId { get; set; }
            public Guid? ChapterId { get; set; }
            public int? DocumentId { get; set; }
            public string? UserId { get; set; }
        }

        [HttpPost("ask")]
        public async Task<IActionResult> Ask([FromBody] AskRequestDto request)
        {
            if (string.IsNullOrWhiteSpace(request.Question))
            {
                return BadRequest(new { message = "Question is required." });
            }

            try
            {
                var (success, result, errorMessage) = await _ragService.AskAsync(
                    request.Question,
                    request.SubjectId,
                    request.ChapterId,
                    request.DocumentId,
                    request.UserId);

                if (!success)
                {
                    return BadRequest(new { message = errorMessage ?? "Failed to generate answer." });
                }

                return Ok(result);
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = ex.Message });
            }
        }

        [HttpGet("history")]
        public async Task<IActionResult> GetHistory(
            [FromQuery] string? userId = null,
            [FromQuery] Guid? subjectId = null,
            [FromQuery] Guid? chapterId = null,
            [FromQuery] int take = 20)
        {
            try
            {
                var (success, history, errorMessage) = await _chatHistoryService.GetHistoryAsync(userId, subjectId, chapterId, take);
                if (!success)
                {
                    return BadRequest(new { message = errorMessage ?? "Failed to fetch history." });
                }

                return Ok(history);
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = ex.Message });
            }
        }
    }
}
