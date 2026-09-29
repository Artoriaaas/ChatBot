using BusinessObject.Entities;
using DataAccessLayer;
using Microsoft.EntityFrameworkCore;
using ServiceLayer.Interfaces;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace ServiceLayer.Implements
{
    public class ChatHistoryService : IChatHistoryService
    {
        private readonly AppDbContext _context;

        public ChatHistoryService(AppDbContext context)
        {
            _context = context;
        }

        public async Task<(bool success, Guid sessionId, string? errorMessage)> SaveAsync(
            string question,
            string answer,
            List<DocumentChunk> retrievedChunks,
            int? documentId,
            Guid? subjectId,
            Guid? chapterId,
            string? userId,
            int promptTokens,
            int completionTokens,
            int totalTokens,
            string modelName,
            Guid? sessionId = null)
        {
            try
            {
                Guid targetSessionId;
                string cleanQuestion = question.Trim();
                string generatedTitle = cleanQuestion.Length > 60
                    ? cleanQuestion.Substring(0, 57) + "..."
                    : cleanQuestion;

                if (sessionId.HasValue && sessionId.Value != Guid.Empty)
                {
                    targetSessionId = sessionId.Value;
                    var existingSession = await _context.ChatSessions.FirstOrDefaultAsync(s => s.Id == targetSessionId);
                    if (existingSession != null)
                    {
                        existingSession.UpdatedAt = DateTime.UtcNow;
                        if (string.IsNullOrWhiteSpace(existingSession.Title) || existingSession.Title == "Cuộc trò chuyện mới")
                        {
                            existingSession.Title = generatedTitle;
                        }
                    }
                    else
                    {
                        var newSession = new ChatSession
                        {
                            Id = targetSessionId,
                            Title = generatedTitle,
                            DocumentId = documentId,
                            UserId = userId,
                            CreatedAt = DateTime.UtcNow,
                            UpdatedAt = DateTime.UtcNow
                        };
                        _context.ChatSessions.Add(newSession);
                    }
                }
                else
                {
                    targetSessionId = Guid.NewGuid();
                    var newSession = new ChatSession
                    {
                        Id = targetSessionId,
                        Title = generatedTitle,
                        DocumentId = documentId,
                        UserId = userId,
                        CreatedAt = DateTime.UtcNow,
                        UpdatedAt = DateTime.UtcNow
                    };
                    _context.ChatSessions.Add(newSession);
                }

                var chatHistory = new ChatHistory
                {
                    SessionId = targetSessionId,
                    Question = question,
                    Answer = answer,
                    UserId = userId,
                    DocumentId = documentId,
                    CreatedAt = DateTime.UtcNow,
                    PromptTokens = promptTokens,
                    CompletionTokens = completionTokens,
                    TotalTokens = totalTokens,
                    ModelName = modelName,
                    Sources = retrievedChunks
                        .Select(chunk => new ChatHistorySource
                        {
                            DocumentChunkId = chunk.Id
                        })
                        .ToList()
                };

                _context.ChatHistories.Add(chatHistory);
                await _context.SaveChangesAsync();

                return (true, targetSessionId, null);
            }
            catch (Exception ex)
            {
                return (false, Guid.Empty, $"Save chat history failed: {ex.Message}");
            }
        }

        public async Task<(bool success, List<ChatSession>? sessions, string? errorMessage)> GetSessionsAsync(
            int? documentId = null,
            string? userId = null,
            int take = 50)
        {
            try
            {
                var query = _context.ChatSessions
                    .Include(s => s.Messages)
                    .AsQueryable();

                if (documentId.HasValue)
                {
                    query = query.Where(s => s.DocumentId == documentId.Value);
                }

                if (!string.IsNullOrWhiteSpace(userId))
                {
                    query = query.Where(s => s.UserId == userId);
                }

                var results = await query
                    .OrderByDescending(s => s.UpdatedAt)
                    .Take(take)
                    .ToListAsync();

                return (true, results, null);
            }
            catch (Exception ex)
            {
                return (false, null, $"Get chat sessions failed: {ex.Message}");
            }
        }

        public async Task<(bool success, ChatSession? session, string? errorMessage)> GetSessionDetailsAsync(Guid sessionId)
        {
            try
            {
                var session = await _context.ChatSessions
                    .Include(s => s.Messages.OrderBy(m => m.CreatedAt))
                        .ThenInclude(m => m.Sources)
                            .ThenInclude(src => src.DocumentChunk)
                                .ThenInclude(dc => dc!.Document)
                    .FirstOrDefaultAsync(s => s.Id == sessionId);

                if (session == null)
                {
                    return (false, null, "Session not found.");
                }

                return (true, session, null);
            }
            catch (Exception ex)
            {
                return (false, null, $"Get chat session details failed: {ex.Message}");
            }
        }

        public async Task<(bool success, ChatSession? session, string? errorMessage)> CreateSessionAsync(
            int? documentId,
            string? title = null,
            string? userId = null)
        {
            try
            {
                var newSession = new ChatSession
                {
                    Id = Guid.NewGuid(),
                    Title = string.IsNullOrWhiteSpace(title) ? "Cuộc trò chuyện mới" : title.Trim(),
                    DocumentId = documentId,
                    UserId = userId,
                    CreatedAt = DateTime.UtcNow,
                    UpdatedAt = DateTime.UtcNow
                };

                _context.ChatSessions.Add(newSession);
                await _context.SaveChangesAsync();

                return (true, newSession, null);
            }
            catch (Exception ex)
            {
                return (false, null, $"Create chat session failed: {ex.Message}");
            }
        }

        public async Task<(bool success, string? errorMessage)> DeleteSessionAsync(Guid sessionId)
        {
            try
            {
                var session = await _context.ChatSessions.FirstOrDefaultAsync(s => s.Id == sessionId);
                if (session == null)
                {
                    return (false, "Session not found.");
                }

                _context.ChatSessions.Remove(session);
                await _context.SaveChangesAsync();

                return (true, null);
            }
            catch (Exception ex)
            {
                return (false, $"Delete chat session failed: {ex.Message}");
            }
        }

        public async Task<(bool success, string? errorMessage)> UpdateSessionTitleAsync(Guid sessionId, string newTitle)
        {
            try
            {
                var session = await _context.ChatSessions.FirstOrDefaultAsync(s => s.Id == sessionId);
                if (session == null)
                {
                    return (false, "Session not found.");
                }

                session.Title = newTitle.Trim();
                session.UpdatedAt = DateTime.UtcNow;
                await _context.SaveChangesAsync();

                return (true, null);
            }
            catch (Exception ex)
            {
                return (false, $"Update session title failed: {ex.Message}");
            }
        }

        public async Task<(bool success, List<ChatHistory>? history, string? errorMessage)> GetHistoryAsync(
            string? userId,
            Guid? subjectId = null,
            Guid? chapterId = null,
            int take = 20,
            int? documentId = null,
            Guid? sessionId = null)
        {
            try
            {
                var query = _context.ChatHistories
                    .Include(ch => ch.Sources)
                        .ThenInclude(s => s.DocumentChunk)
                            .ThenInclude(dc => dc!.Document)
                    .AsQueryable();

                if (!string.IsNullOrWhiteSpace(userId))
                {
                    query = query.Where(ch => ch.UserId == userId);
                }

                if (documentId.HasValue)
                {
                    query = query.Where(ch => ch.DocumentId == documentId.Value);
                }

                if (sessionId.HasValue)
                {
                    query = query.Where(ch => ch.SessionId == sessionId.Value);
                }

                var results = await query
                    .OrderByDescending(ch => ch.CreatedAt)
                    .Take(take)
                    .ToListAsync();

                return (true, results, null);
            }
            catch (Exception ex)
            {
                return (
                    false,
                    null,
                    $"Get chat history failed: {ex.Message}");
            }
        }
    }
}