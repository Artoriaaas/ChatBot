using BusinessObject.Entities;
using DataAccessLayer.Repositories.Interfaces;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.DependencyInjection;
using ServiceLayer.Interfaces;
using System;
using System.Collections.Generic;
using System.IO;
using System.Threading.Tasks;

namespace ServiceLayer.Implements
{
    public class PaperService : IPaperService
    {
        private readonly IPaperRepository _paperRepository;
        private readonly IDocumentRepository _documentRepository;
        private readonly IDocumentChunkRepository _documentChunkRepository;
        private readonly IFileUploadService _fileUploadService;
        private readonly IServiceScopeFactory _scopeFactory;

        public PaperService(
            IPaperRepository paperRepository,
            IDocumentRepository documentRepository,
            IDocumentChunkRepository documentChunkRepository,
            IFileUploadService fileUploadService,
            IServiceScopeFactory scopeFactory)
        {
            _paperRepository = paperRepository;
            _documentRepository = documentRepository;
            _documentChunkRepository = documentChunkRepository;
            _fileUploadService = fileUploadService;
            _scopeFactory = scopeFactory;
        }

        public async Task<(bool Success, string Message, int PaperId)> UploadPaperAsync(
            IFormFile file,
            string? title = null,
            string? authors = null,
            int? year = null,
            string? collection = null,
            string? tags = null,
            string? abstractText = null)
        {
            if (file == null || file.Length == 0)
                return (false, "Vui lòng chọn tệp tài liệu.", 0);

            var paperTitle = string.IsNullOrWhiteSpace(title) ? Path.GetFileNameWithoutExtension(file.FileName) : title.Trim();

            var (uploadSuccess, filePath, uploadError) = await _fileUploadService.UploadFileAsync(file.OpenReadStream(), file.FileName);
            if (!uploadSuccess || string.IsNullOrEmpty(filePath))
                return (false, $"Lỗi lưu file: {uploadError}", 0);

            var fileSize = _fileUploadService.GetFileSize(filePath);

            var document = new Document
            {
                FileName = file.FileName,
                FilePath = filePath,
                FileSize = fileSize,
                IndexStatus = "Pending",
                UploadDate = DateTime.UtcNow
            };

            await _documentRepository.AddAsync(document);
            await _documentRepository.SaveChangesAsync();

            var paper = new Paper
            {
                Title = paperTitle,
                Authors = authors ?? "Chưa rõ tác giả",
                Year = year ?? DateTime.UtcNow.Year,
                Collection = string.IsNullOrWhiteSpace(collection) ? "Tài liệu Backend" : collection,
                Tags = tags ?? "Research",
                AbstractText = abstractText ?? $"Bài báo nghiên cứu {paperTitle}.",
                FilePath = filePath,
                FileSize = fileSize,
                IndexStatus = "Pending",
                DocumentId = document.Id,
                CreatedAt = DateTime.UtcNow
            };

            await _paperRepository.AddAsync(paper);
            await _paperRepository.SaveChangesAsync();

            // Run Indexing process in background
            _ = Task.Run(async () =>
            {
                using var scope = _scopeFactory.CreateScope();
                var indexingService = scope.ServiceProvider.GetRequiredService<IIndexingService>();
                var docRepo = scope.ServiceProvider.GetRequiredService<IDocumentRepository>();
                var paperRepo = scope.ServiceProvider.GetRequiredService<IPaperRepository>();

                var docToProcess = await docRepo.GetByIdAsync(document.Id);
                var paperToUpdate = await paperRepo.GetByIdAsync(paper.Id);

                if (docToProcess != null)
                {
                    await indexingService.IndexDocumentAsync(docToProcess);
                    if (paperToUpdate != null)
                    {
                        paperToUpdate.IndexStatus = docToProcess.IndexStatus;
                        paperToUpdate.ErrorMessage = docToProcess.ErrorMessage;
                        await paperRepo.UpdateAsync(paperToUpdate);
                        await paperRepo.SaveChangesAsync();
                    }
                }
            });

            return (true, "Tải bài báo thành công, hệ thống đang tiến hành băm chữ và tạo vector AI...", paper.Id);
        }

        public async Task<IEnumerable<Paper>> GetPapersAsync(
            string? search = null,
            string? collection = null,
            string? tag = null,
            bool? isFavorite = null,
            string? sort = null)
        {
            return await _paperRepository.GetAllAsync(search, collection, tag, isFavorite, sort);
        }

        public async Task<Paper?> GetByIdAsync(int id)
        {
            return await _paperRepository.GetByIdAsync(id);
        }

        public async Task<(bool Success, string Message)> ToggleFavoriteAsync(int id)
        {
            var paper = await _paperRepository.GetByIdAsync(id);
            if (paper == null)
                return (false, "Bài báo không tồn tại.");

            paper.IsFavorite = !paper.IsFavorite;
            await _paperRepository.UpdateAsync(paper);
            await _paperRepository.SaveChangesAsync();

            return (true, paper.IsFavorite ? "Đã thêm vào danh sách yêu thích." : "Đã bỏ yêu thích.");
        }

        public async Task<(bool Success, string Message)> DeletePaperAsync(int id)
        {
            var paper = await _paperRepository.GetByIdAsync(id);
            if (paper == null)
                return (false, "Bài báo không tồn tại.");

            if (paper.DocumentId.HasValue)
            {
                var doc = await _documentRepository.GetByIdWithChunksAsync(paper.DocumentId.Value);
                if (doc != null)
                {
                    await _documentChunkRepository.DeleteByDocumentIdAsync(doc.Id);
                    await _documentChunkRepository.SaveChangesAsync();
                    _fileUploadService.DeleteFile(doc.FilePath);
                    await _documentRepository.DeleteAsync(doc);
                    await _documentRepository.SaveChangesAsync();
                }
            }

            await _paperRepository.DeleteAsync(paper);
            await _paperRepository.SaveChangesAsync();

            return (true, "Đã xóa bài báo thành công.");
        }

        public async Task<(bool Success, string Message)> SavePaperAsync(Paper paper)
        {
            var existed = await _paperRepository.GetByIdAsync(paper.Id);
            if (existed == null)
            {
                await _paperRepository.AddAsync(paper);
            }
            else
            {
                existed.Title = paper.Title;
                existed.Authors = paper.Authors;
                existed.Year = paper.Year;
                existed.Collection = paper.Collection;
                existed.Tags = paper.Tags;
                existed.AbstractText = paper.AbstractText;
                existed.IsFavorite = paper.IsFavorite;
                await _paperRepository.UpdateAsync(existed);
            }

            await _paperRepository.SaveChangesAsync();
            return (true, "Đã lưu thông tin bài báo.");
        }
    }
}
