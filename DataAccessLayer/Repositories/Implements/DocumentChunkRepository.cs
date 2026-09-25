using BusinessObject.Entities;
using DataAccessLayer.Repositories.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace DataAccessLayer.Repositories.Implements
{
    public class DocumentChunkRepository : IDocumentChunkRepository
    {
        private readonly AppDbContext _context;

        public DocumentChunkRepository(AppDbContext context)
        {
            _context = context;
        }

        public async Task AddRangeAsync(IEnumerable<DocumentChunk> chunks)
        {
            await _context.DocumentChunks.AddRangeAsync(chunks);
        }

        public async Task DeleteByDocumentIdAsync(int documentId)
        {
            var chunks = await _context.DocumentChunks
                .Where(c => c.DocumentId == documentId)
                .ToListAsync();

            if (chunks.Any())
            {
                var chunkIds = chunks.Select(c => c.Id).ToList();
                var sources = await _context.ChatHistorySources
                    .Where(s => chunkIds.Contains(s.DocumentChunkId))
                    .ToListAsync();

                if (sources.Any())
                {
                    _context.ChatHistorySources.RemoveRange(sources);
                }

                _context.DocumentChunks.RemoveRange(chunks);
            }
        }

        public async Task<IEnumerable<DocumentChunk>> GetByDocumentIdAsync(int documentId)
        {
            return await _context.DocumentChunks
                .Where(c => c.DocumentId == documentId)
                .OrderBy(c => c.ChunkOrder)
                .ToListAsync();
        }

        public Task SaveChangesAsync()
        {
            return _context.SaveChangesAsync();
        }
    }
}
