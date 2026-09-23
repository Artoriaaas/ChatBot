using BusinessObject.Entities;
using DataAccessLayer;
using DataAccessLayer.Repositories.Interfaces;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Caching.Memory;
using Pgvector;
using ServiceLayer.Interfaces;
using System;
using System.Collections.Generic;
using System.IO;
using System.Text.Json;
using System.Threading.Tasks;

namespace ServiceLayer.Implements
{
    public class IndexingService : IIndexingService
    {
        private readonly AppDbContext _context;
        private readonly IDocumentRepository _documentRepository;
        private readonly IDocumentChunkRepository _documentChunkRepository;
        private readonly ITextExtractionService _textExtractionService;
        private readonly IChunkingService _chunkingService;
        private readonly IEmbeddingService _embeddingService;
        private readonly IMemoryCache _cache;

        public IndexingService(
            AppDbContext context,
            IDocumentRepository documentRepository,
            IDocumentChunkRepository documentChunkRepository,
            ITextExtractionService textExtractionService,
            IChunkingService chunkingService,
            IEmbeddingService embeddingService,
            IFileUploadService fileUploadService,
            IMemoryCache cache)
        {
            _context = context;
            _documentRepository = documentRepository;
            _documentChunkRepository = documentChunkRepository;
            _textExtractionService = textExtractionService;
            _chunkingService = chunkingService;
            _embeddingService = embeddingService;
            _cache = cache;
        }

        public async Task<(bool success, string? errorMessage)>
            IndexDocumentAsync(Document document)
        {
            var progressKey = $"doc_progress_{document.Id}";
            _cache.Set(progressKey, 0);

            try
            {
                // Lưu Processing riêng, không đặt trong transaction chính.
                document.IndexStatus = "Processing";
                document.ErrorMessage = null;

                await _documentRepository.UpdateAsync(document);
                await _documentRepository.SaveChangesAsync();

                // 1. Đọc nội dung file và trích xuất cấu trúc văn bản chi tiết
                var extractionResult = await _textExtractionService.ExtractDocumentFullAsync(document.FilePath);

                if (!extractionResult.Success || string.IsNullOrWhiteSpace(extractionResult.FullText))
                {
                    await MarkAsFailedAsync(
                        document,
                        $"Text extraction failed: {extractionResult.ErrorMessage}");

                    return (false, extractionResult.ErrorMessage);
                }

                // 1.1 Lưu cấu trúc các phân đoạn (Sections) vào file sidecar để FE đọc nhanh
                try
                {
                    var structureJsonPath = document.FilePath + ".structure.json";
                    var json = JsonSerializer.Serialize(extractionResult.Sections);
                    await File.WriteAllTextAsync(structureJsonPath, json);
                }
                catch (Exception jsonEx)
                {
                    Console.WriteLine($"[Indexing] ⚠️ Không thể lưu file structure.json: {jsonEx.Message}");
                }

                // 1.2 Tự động đồng bộ metadata trích xuất được vào Paper tương ứng nếu có
                try
                {
                    var linkedPaper = await _context.Papers.FirstOrDefaultAsync(p => p.DocumentId == document.Id);
                    if (linkedPaper != null)
                    {
                        if (!string.IsNullOrWhiteSpace(extractionResult.Title) && 
                            (string.IsNullOrWhiteSpace(linkedPaper.Title) || linkedPaper.Title == Path.GetFileNameWithoutExtension(document.FileName)))
                        {
                            linkedPaper.Title = extractionResult.Title;
                        }
                        if (!string.IsNullOrWhiteSpace(extractionResult.Authors) && 
                            (string.IsNullOrWhiteSpace(linkedPaper.Authors) || linkedPaper.Authors == "Chưa rõ tác giả"))
                        {
                            linkedPaper.Authors = extractionResult.Authors;
                        }
                        if (!string.IsNullOrWhiteSpace(extractionResult.AbstractText) && 
                            (string.IsNullOrWhiteSpace(linkedPaper.AbstractText) || linkedPaper.AbstractText.StartsWith("Bài báo nghiên cứu")))
                        {
                            linkedPaper.AbstractText = extractionResult.AbstractText;
                        }
                        if (extractionResult.Year.HasValue)
                        {
                            linkedPaper.Year = extractionResult.Year.Value;
                        }
                        if (extractionResult.TotalPages > 0)
                        {
                            linkedPaper.TotalPages = extractionResult.TotalPages;
                        }

                        await _context.SaveChangesAsync();
                    }
                }
                catch (Exception paperEx)
                {
                    Console.WriteLine($"[Indexing] ⚠️ Cập nhật metadata cho Paper thất bại: {paperEx.Message}");
                }

                // 2. Tự động băm nhỏ văn bản (bảo toàn cấu trúc đoạn và dấu xuống dòng)
                var chunks = _chunkingService.ChunkText(
                    extractionResult.FullText,
                    512,
                    50);

                if (chunks.Count == 0)
                {
                    const string error = "No chunks generated from document";

                    await MarkAsFailedAsync(document, error);

                    return (false, error);
                }

                var documentChunks = new List<DocumentChunk>();

                // 3. Tạo embedding cho từng chunk
                for (var index = 0; index < chunks.Count; index++)
                {
                    var chunk = chunks[index];

                    var (embedSuccess, embedding, embedError) =
                        await _embeddingService.GetEmbeddingAsync(chunk);

                    if (!embedSuccess || embedding == null)
                    {
                        await MarkAsFailedAsync(
                            document,
                            $"Embedding failed: {embedError}");

                        return (false, embedError);
                    }

                    // Database đang dùng vector(3072)
                    if (embedding.Count != 3072)
                    {
                        var dimensionError =
                            $"Embedding dimension is {embedding.Count}, expected 3072.";

                        await MarkAsFailedAsync(
                            document,
                            dimensionError);

                        return (false, dimensionError);
                    }

                    documentChunks.Add(new DocumentChunk
                    {
                        DocumentId = document.Id,
                        Content = chunk,
                        Embedding = new Vector(embedding.ToArray()),
                        ChunkOrder = index
                    });

                    var progress =
                        (int)(((index + 1) * 100.0) / chunks.Count);

                    _cache.Set(progressKey, progress);
                }

                // 4. Chỉ dùng transaction cho thao tác ghi chunks
                await using var transaction =
                    await _context.Database.BeginTransactionAsync();

                try
                {
                    await _documentChunkRepository
                        .AddRangeAsync(documentChunks);

                    document.IndexStatus = "Completed";
                    document.ErrorMessage = null;

                    await _documentRepository.UpdateAsync(document);
                    await _documentRepository.SaveChangesAsync();

                    await transaction.CommitAsync();
                }
                catch
                {
                    await transaction.RollbackAsync();
                    throw;
                }

                _cache.Set(progressKey, 100);

                return (true, null);
            }
            catch (Exception ex)
            {
                await MarkAsFailedAsync(
                    document,
                    $"Indexing error: {ex.Message}");

                return (false, ex.Message);
            }
        }

        private async Task MarkAsFailedAsync(
            Document document,
            string errorMessage)
        {
            document.IndexStatus = "Failed";
            document.ErrorMessage = errorMessage;

            await _documentRepository.UpdateAsync(document);
            await _documentRepository.SaveChangesAsync();

            _cache.Remove($"doc_progress_{document.Id}");
        }
    }
}