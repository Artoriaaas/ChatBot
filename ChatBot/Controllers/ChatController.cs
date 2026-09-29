using Microsoft.AspNetCore.Mvc;
using ServiceLayer.Interfaces;
using BusinessObject.Entities;
using System;
using System.Linq;
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
            public Guid? SessionId { get; set; }
        }

        public class CreateSessionDto
        {
            public int? DocumentId { get; set; }
            public string? Title { get; set; }
            public string? UserId { get; set; }
        }

        public class UpdateSessionTitleDto
        {
            public string Title { get; set; } = string.Empty;
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
                    request.UserId,
                    request.SessionId);

                if (!success || result == null)
                {
                    return BadRequest(new { message = errorMessage ?? "Failed to generate answer." });
                }

                return Ok(new
                {
                    sessionId = result.SessionId,
                    answer = result.Answer,
                    sources = result.Sources,
                    promptTokens = result.PromptTokens,
                    completionTokens = result.CompletionTokens,
                    totalTokens = result.TotalTokens,
                    modelName = result.ModelName,
                    retrievedChunks = (result.CitedChunks?.Any() == true
                        ? result.CitedChunks.Select(c => new
                        {
                            sourceIndex = c.SourceIndex,
                            id = c.Id,
                            documentId = c.DocumentId,
                            chunkOrder = c.ChunkOrder,
                            content = c.Content,
                            fileName = c.FileName
                        })
                        : result.RetrievedChunks?.Select((c, idx) => new
                        {
                            sourceIndex = idx + 1,
                            id = c.Id,
                            documentId = c.DocumentId,
                            chunkOrder = c.ChunkOrder,
                            content = c.Content,
                            fileName = c.Document?.FileName
                        }))
                });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = ex.Message });
            }
        }

        [HttpGet("sessions")]
        public async Task<IActionResult> GetSessions(
            [FromQuery] int? documentId = null,
            [FromQuery] string? userId = null,
            [FromQuery] int take = 50)
        {
            try
            {
                var (success, sessions, errorMessage) = await _chatHistoryService.GetSessionsAsync(documentId, userId, take);
                if (!success)
                {
                    return BadRequest(new { message = errorMessage ?? "Failed to fetch sessions." });
                }

                return Ok(sessions?.Select(s => new
                {
                    id = s.Id,
                    title = s.Title,
                    documentId = s.DocumentId,
                    userId = s.UserId,
                    createdAt = s.CreatedAt,
                    updatedAt = s.UpdatedAt,
                    messageCount = s.Messages.Count,
                    lastQuestion = s.Messages.OrderByDescending(m => m.CreatedAt).FirstOrDefault()?.Question
                }));
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = ex.Message });
            }
        }

        [HttpGet("sessions/{id}")]
        public async Task<IActionResult> GetSessionDetails([FromRoute] Guid id)
        {
            try
            {
                var (success, session, errorMessage) = await _chatHistoryService.GetSessionDetailsAsync(id);
                if (!success || session == null)
                {
                    return NotFound(new { message = errorMessage ?? "Session not found." });
                }

                return Ok(new
                {
                    id = session.Id,
                    title = session.Title,
                    documentId = session.DocumentId,
                    userId = session.UserId,
                    createdAt = session.CreatedAt,
                    updatedAt = session.UpdatedAt,
                    messages = session.Messages.OrderBy(m => m.CreatedAt).Select(m => new
                    {
                        id = m.Id,
                        question = m.Question,
                        answer = m.Answer,
                        createdAt = m.CreatedAt,
                        retrievedChunks = m.Sources.Select((src, idx) => new
                        {
                            sourceIndex = idx + 1,
                            id = src.DocumentChunkId,
                            documentId = src.DocumentChunk?.DocumentId,
                            chunkOrder = src.DocumentChunk?.ChunkOrder,
                            content = src.DocumentChunk?.Content,
                            fileName = src.DocumentChunk?.Document?.FileName
                        })
                    })
                });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = ex.Message });
            }
        }

        [HttpPost("sessions")]
        public async Task<IActionResult> CreateSession([FromBody] CreateSessionDto dto)
        {
            try
            {
                var (success, session, errorMessage) = await _chatHistoryService.CreateSessionAsync(
                    dto.DocumentId,
                    dto.Title,
                    dto.UserId);

                if (!success || session == null)
                {
                    return BadRequest(new { message = errorMessage ?? "Failed to create session." });
                }

                return Ok(new
                {
                    id = session.Id,
                    title = session.Title,
                    documentId = session.DocumentId,
                    userId = session.UserId,
                    createdAt = session.CreatedAt,
                    updatedAt = session.UpdatedAt
                });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = ex.Message });
            }
        }

        [HttpDelete("sessions/{id}")]
        public async Task<IActionResult> DeleteSession([FromRoute] Guid id)
        {
            try
            {
                var (success, errorMessage) = await _chatHistoryService.DeleteSessionAsync(id);
                if (!success)
                {
                    return BadRequest(new { message = errorMessage ?? "Failed to delete session." });
                }

                return Ok(new { message = "Session deleted successfully." });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = ex.Message });
            }
        }

        [HttpPut("sessions/{id}/title")]
        public async Task<IActionResult> UpdateSessionTitle([FromRoute] Guid id, [FromBody] UpdateSessionTitleDto dto)
        {
            if (string.IsNullOrWhiteSpace(dto.Title))
            {
                return BadRequest(new { message = "Title cannot be empty." });
            }

            try
            {
                var (success, errorMessage) = await _chatHistoryService.UpdateSessionTitleAsync(id, dto.Title);
                if (!success)
                {
                    return BadRequest(new { message = errorMessage ?? "Failed to update session title." });
                }

                return Ok(new { message = "Session title updated successfully." });
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
            [FromQuery] int take = 20,
            [FromQuery] int? documentId = null,
            [FromQuery] Guid? sessionId = null)
        {
            try
            {
                var (success, history, errorMessage) = await _chatHistoryService.GetHistoryAsync(
                    userId, subjectId, chapterId, take, documentId, sessionId);
                if (!success)
                {
                    return BadRequest(new { message = errorMessage ?? "Failed to fetch history." });
                }

                return Ok(history?.Select(item => new
                {
                    item.Id,
                    item.SessionId,
                    item.DocumentId,
                    item.Question,
                    item.Answer,
                    item.CreatedAt
                }));
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = ex.Message });
            }
        }
    }
}
