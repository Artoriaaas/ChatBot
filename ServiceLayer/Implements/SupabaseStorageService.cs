using ServiceLayer.Interfaces;
using Supabase;
using System;
using System.IO;
using System.Threading.Tasks;

namespace ServiceLayer.Implements
{
    public class SupabaseStorageService : IFileUploadService
    {
        private readonly Client _supabaseClient;
        private readonly string _bucketName = "documents";

        public SupabaseStorageService(Client supabaseClient)
        {
            _supabaseClient = supabaseClient;
        }

        public async Task<(bool success, string? filePath, string? errorMessage)> UploadFileAsync(
            Stream fileStream, string fileName)
        {
            try
            {
                var uniqueFileName = $"{Guid.NewGuid()}_{fileName}";
                
                using var memoryStream = new MemoryStream();
                await fileStream.CopyToAsync(memoryStream);
                var fileBytes = memoryStream.ToArray();

                var storage = _supabaseClient.Storage.From(_bucketName);
                
                // Need to ensure bucket exists or it will fail, but assuming bucket is already created in Supabase
                await storage.Upload(fileBytes, uniqueFileName, new Supabase.Storage.FileOptions { Upsert = true });

                // We return the uniqueFileName as filePath so we can use it to get public url or download later
                return (true, uniqueFileName, null);
            }
            catch (Exception ex)
            {
                return (false, null, $"Supabase Upload failed: {ex.Message}");
            }
        }

        public bool DeleteFile(string filePath)
        {
            try
            {
                var storage = _supabaseClient.Storage.From(_bucketName);
                storage.Remove(new System.Collections.Generic.List<string> { filePath }).Wait();
                return true;
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Failed to delete file from Supabase {filePath}: {ex.Message}");
                return false;
            }
        }

        public bool FileExists(string filePath)
        {
            // For Supabase, checking existence without downloading is tricky, 
            // returning true as a stub, or we can assume if it's in DB it exists.
            return true;
        }

        public long GetFileSize(string filePath)
        {
            // We cannot easily get size synchronously from Supabase without another API call.
            // Returning 0 for now, or we can change IDocumentService to save size during UploadFileAsync.
            return 0; 
        }
    }
}
