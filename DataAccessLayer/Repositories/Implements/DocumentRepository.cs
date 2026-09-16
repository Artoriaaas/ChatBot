using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using BusinessObject.Entities;
using DataAccessLayer.Repositories.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace DataAccessLayer.Repositories.Implements
{
    public class DocumentRepository : IDocumentRepository
    {
        private readonly AppDbContext _context;

        public DocumentRepository(AppDbContext context)
        {
            _context = context;
        }

        public async Task AddAsync(Document document)
        {
            await _context.Documents.AddAsync(document);
        }

        public async Task<Document?> GetByIdAsync(int id)
        {
            return await _context.Documents
                .Include(d => d.DocumentChunks)
                .FirstOrDefaultAsync(d => d.Id == id);
        }

        public async Task<Document?> GetByIdWithChunksAsync(int id)
        {
            return await _context.Documents
                .Include(d => d.DocumentChunks)
                .FirstOrDefaultAsync(d => d.Id == id);
        }

        public async Task<List<Document>> GetCompletedDocumentsAsync()
        {
            return await _context.Documents.ToListAsync();
        }

        public async Task<bool> ExistsAsync(string fileName)
        {
            return await _context.Documents.AnyAsync(d =>
                d.FileName.ToLower() == fileName.ToLower());
        }

        public Task UpdateAsync(Document document)
        {
            _context.Documents.Update(document);
            return Task.CompletedTask;
        }

        public Task DeleteAsync(Document document)
        {
            _context.Documents.Remove(document);
            return Task.CompletedTask;
        }

        public Task SaveChangesAsync()
        {
            return _context.SaveChangesAsync();
        }
    }
}
