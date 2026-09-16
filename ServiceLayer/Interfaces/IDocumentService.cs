using Microsoft.AspNetCore.Http;
using BusinessObject.Entities;

namespace ServiceLayer.Interfaces
{
    public interface IDocumentService
    {
        Task<(bool Success, string Message, int DocumentId)> UploadDocumentAsync(IFormFile file);
        Task<IEnumerable<Document>> GetDocumentsAsync();

        Task<Document?> GetByIdAsync(int id);

        Task<(bool Success, string Message)> ReindexDocumentAsync(int id);

        Task<(bool Success, string Message)> DeleteDocumentAsync(int id);
    }
}