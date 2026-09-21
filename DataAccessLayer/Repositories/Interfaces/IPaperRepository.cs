using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using BusinessObject.Entities;

namespace DataAccessLayer.Repositories.Interfaces
{
    public interface IPaperRepository
    {
        Task AddAsync(Paper paper);
        Task<Paper?> GetByIdAsync(int id);
        Task<List<Paper>> GetAllAsync(string? search = null, string? collection = null, string? tag = null, bool? isFavorite = null, string? sort = null);
        Task<bool> ExistsAsync(string title);
        Task UpdateAsync(Paper paper);
        Task DeleteAsync(Paper paper);
        Task SaveChangesAsync();
    }
}
