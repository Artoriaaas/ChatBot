using BusinessObject.Entities;
using Microsoft.AspNetCore.Http;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace ServiceLayer.Interfaces
{
    public interface IPaperService
    {
        Task<(bool Success, string Message, int PaperId)> UploadPaperAsync(
            IFormFile file,
            string? title = null,
            string? authors = null,
            int? year = null,
            string? collection = null,
            string? tags = null,
            string? abstractText = null);

        Task<IEnumerable<Paper>> GetPapersAsync(
            string? search = null,
            string? collection = null,
            string? tag = null,
            bool? isFavorite = null,
            string? sort = null);

        Task<Paper?> GetByIdAsync(int id);

        Task<(bool Success, string Message)> ToggleFavoriteAsync(int id);

        Task<(bool Success, string Message)> DeletePaperAsync(int id);

        Task<(bool Success, string Message)> SavePaperAsync(Paper paper);
    }
}
