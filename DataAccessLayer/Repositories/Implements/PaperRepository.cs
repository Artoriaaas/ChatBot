using BusinessObject.Entities;
using DataAccessLayer.Repositories.Interfaces;
using Microsoft.EntityFrameworkCore;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace DataAccessLayer.Repositories.Implements
{
    public class PaperRepository : IPaperRepository
    {
        private readonly AppDbContext _context;

        public PaperRepository(AppDbContext context)
        {
            _context = context;
        }

        public async Task AddAsync(Paper paper)
        {
            await _context.Papers.AddAsync(paper);
        }

        public async Task<Paper?> GetByIdAsync(int id)
        {
            return await _context.Papers
                .Include(p => p.Document)
                .FirstOrDefaultAsync(p => p.Id == id);
        }

        public async Task<List<Paper>> GetAllAsync(string? search = null, string? collection = null, string? tag = null, bool? isFavorite = null, string? sort = null)
        {
            var query = _context.Papers.Include(p => p.Document).AsQueryable();

            if (!string.IsNullOrWhiteSpace(search))
            {
                var q = search.ToLower();
                query = query.Where(p =>
                    p.Title.ToLower().Contains(q) ||
                    (p.AbstractText != null && p.AbstractText.ToLower().Contains(q)) ||
                    p.Authors.ToLower().Contains(q) ||
                    (p.Tags != null && p.Tags.ToLower().Contains(q)));
            }

            if (!string.IsNullOrWhiteSpace(collection))
            {
                query = query.Where(p => p.Collection == collection);
            }

            if (!string.IsNullOrWhiteSpace(tag))
            {
                query = query.Where(p => p.Tags != null && p.Tags.Contains(tag));
            }

            if (isFavorite.HasValue)
            {
                query = query.Where(p => p.IsFavorite == isFavorite.Value);
            }

            switch (sort?.ToLower())
            {
                case "yearasc":
                    query = query.OrderBy(p => p.Year);
                    break;
                case "titleasc":
                    query = query.OrderBy(p => p.Title);
                    break;
                case "titledesc":
                    query = query.OrderByDescending(p => p.Title);
                    break;
                case "yeardesc":
                default:
                    query = query.OrderByDescending(p => p.Year).ThenByDescending(p => p.CreatedAt);
                    break;
            }

            return await query.ToListAsync();
        }

        public async Task<bool> ExistsAsync(string title)
        {
            return await _context.Papers.AnyAsync(p => p.Title.ToLower() == title.ToLower());
        }

        public Task UpdateAsync(Paper paper)
        {
            _context.Papers.Update(paper);
            return Task.CompletedTask;
        }

        public Task DeleteAsync(Paper paper)
        {
            _context.Papers.Remove(paper);
            return Task.CompletedTask;
        }

        public async Task SaveChangesAsync()
        {
            await _context.SaveChangesAsync();
        }
    }
}
