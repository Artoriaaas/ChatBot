using BusinessObject.Entities;
using System;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace ServiceLayer.Interfaces
{
    public interface IChatHistoryService
    {
        Task<(bool success, Guid sessionId, string? errorMessage)> SaveAsync(
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
            Guid? sessionId = null);

        Task<(bool success, List<ChatHistory>? history, string? errorMessage)> GetHistoryAsync(
            string? userId,
            Guid? subjectId = null,
            Guid? chapterId = null,
            int take = 20,
            int? documentId = null,
            Guid? sessionId = null);

        Task<(bool success, List<ChatSession>? sessions, string? errorMessage)> GetSessionsAsync(
            int? documentId = null,
            string? userId = null,
            int take = 50);

        Task<(bool success, ChatSession? session, string? errorMessage)> GetSessionDetailsAsync(Guid sessionId);

        Task<(bool success, ChatSession? session, string? errorMessage)> CreateSessionAsync(
            int? documentId,
            string? title = null,
            string? userId = null);

        Task<(bool success, string? errorMessage)> DeleteSessionAsync(Guid sessionId);

        Task<(bool success, string? errorMessage)> UpdateSessionTitleAsync(Guid sessionId, string newTitle);
    }
}