using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using Supabase;
using System.Diagnostics;

namespace ServiceLayer.Implements
{
    public class DatabaseBackupService : BackgroundService
    {
        private readonly IConfiguration _configuration;
        private readonly ILogger<DatabaseBackupService> _logger;
        private readonly TimeSpan _backupInterval = TimeSpan.FromMinutes(10);   

        public DatabaseBackupService(IConfiguration configuration, ILogger<DatabaseBackupService> logger)
        {
            _configuration = configuration;
            _logger = logger;
        }

        protected override async Task ExecuteAsync(CancellationToken stoppingToken)
        {
            _logger.LogInformation("[BackupService] Khởi động Background Job sao lưu CSDL.");

            // Chạy 1 lần sau khi khởi động 5 giây để kiểm tra và đẩy bản sao lưu đầu tiên lên Supabase
            _ = Task.Run(async () =>
            {
                try
                {
                    await Task.Delay(5000, stoppingToken);
                    if (!stoppingToken.IsCancellationRequested)
                    {
                        _logger.LogInformation("[BackupService] Bắt đầu lần sao lưu khởi động đầu tiên...");
                        await PerformBackupAsync(stoppingToken);
                    }
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "[BackupService] Lỗi xảy ra trong quá trình sao lưu khởi động.");
                }
            }, stoppingToken);

            using var timer = new PeriodicTimer(_backupInterval);

            while (!stoppingToken.IsCancellationRequested && await timer.WaitForNextTickAsync(stoppingToken))
            {
                try
                {
                    await PerformBackupAsync(stoppingToken);
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "[BackupService] Lỗi xảy ra trong quá trình sao lưu tự động.");
                }
            }
        }

        public async Task PerformBackupAsync(CancellationToken cancellationToken)
        {
            _logger.LogInformation("[BackupService] Đang bắt đầu sao lưu CSDL local...");

            string connectionString = _configuration.GetConnectionString("DefaultConnection") ?? "";
            string pgDumpPath = _configuration["PgDumpPath"] 
                ?? _configuration["PG_DUMP_PATH"] 
                ?? Environment.GetEnvironmentVariable("PG_DUMP_PATH") 
                ?? @"C:\Program Files\PostgreSQL\18\bin\pg_dump.exe";

            if (!File.Exists(pgDumpPath))
            {
                string[] possiblePaths = new[]
                {
                    @"C:\Program Files\PostgreSQL\18\bin\pg_dump.exe",
                    @"C:\Program Files\PostgreSQL\17\bin\pg_dump.exe",
                    @"C:\Program Files\PostgreSQL\16\bin\pg_dump.exe",
                    @"C:\Program Files\PostgreSQL\15\bin\pg_dump.exe"
                };
                foreach (var p in possiblePaths)
                {
                    if (File.Exists(p))
                    {
                        pgDumpPath = p;
                        break;
                    }
                }
            }

            string supabaseUrl = _configuration["Supabase:Url"] 
                ?? _configuration["SUPABASE_URL"] 
                ?? Environment.GetEnvironmentVariable("SUPABASE_URL") 
                ?? "";
            string supabaseKey = _configuration["Supabase:Key"] 
                ?? _configuration["SUPABASE_SERVICE_KEY"] 
                ?? Environment.GetEnvironmentVariable("SUPABASE_SERVICE_KEY") 
                ?? "";
            string bucketName = _configuration["Supabase:BackupBucket"] 
                ?? _configuration["SUPABASE_BACKUP_BUCKET"] 
                ?? Environment.GetEnvironmentVariable("SUPABASE_BACKUP_BUCKET") 
                ?? "database-backups";

            if (string.IsNullOrEmpty(supabaseUrl) || string.IsNullOrEmpty(supabaseKey))
            {
                _logger.LogWarning("[BackupService] Bỏ qua sao lưu do thiếu SUPABASE_URL hoặc SUPABASE_SERVICE_KEY.");
                return;
            }

            // 1. Tạo file dump cục bộ tạm thời
            string fileName = $"backup_{DateTime.UtcNow:yyyyMMdd_HHmmss}.sql";
            string tempFilePath = Path.Combine(Path.GetTempPath(), fileName);

            // Parse connection parameters từ DefaultConnection
            var builder = new Npgsql.NpgsqlConnectionStringBuilder(connectionString);

            var startInfo = new ProcessStartInfo
            {
                FileName = pgDumpPath,
                Arguments = $"-h {builder.Host} -p {builder.Port} -U {builder.Username} -d {builder.Database} -F c -f \"{tempFilePath}\"",
                RedirectStandardOutput = true,
                RedirectStandardError = true,
                UseShellExecute = false,
                CreateNoWindow = true
            };
            startInfo.EnvironmentVariables["PGPASSWORD"] = builder.Password;

            using (var process = Process.Start(startInfo))
            {
                if (process != null)
                {
                    await process.WaitForExitAsync(cancellationToken);
                    if (process.ExitCode != 0)
                    {
                        string error = await process.StandardError.ReadToEndAsync(cancellationToken);
                        throw new Exception($"pg_dump thất bại: {error}");
                    }
                }
            }

            _logger.LogInformation($"[BackupService] Đã tạo file dump tạm thời thành công: {tempFilePath}");

            // 2. Upload file lên Supabase Storage
            var options = new SupabaseOptions { AutoConnectRealtime = false };
            var client = new Supabase.Client(supabaseUrl, supabaseKey, options);
            await client.InitializeAsync();

            try
            {
                var buckets = await client.Storage.ListBuckets();
                if (buckets == null || !buckets.Any(b => b.Name == bucketName))
                {
                    _logger.LogInformation($"[BackupService] Bucket '{bucketName}' chưa tồn tại. Đang tự động tạo bucket...");
                    await client.Storage.CreateBucket(bucketName, new Supabase.Storage.BucketUpsertOptions { Public = false });
                }
            }
            catch (Exception ex)
            {
                _logger.LogWarning($"[BackupService] Không thể tự động kiểm tra/tạo bucket: {ex.Message}. Thử tiến hành upload trực tiếp...");
            }

            byte[] fileBytes = await File.ReadAllBytesAsync(tempFilePath, cancellationToken);
            await client.Storage.From(bucketName).Upload(fileBytes, fileName, new Supabase.Storage.FileOptions { Upsert = true });

            _logger.LogInformation($"[BackupService] [OK] Đã tải bản sao lưu thành công lên Supabase Bucket '{bucketName}/{fileName}'.");

            // 3. Dọn dẹp file tạm local
            if (File.Exists(tempFilePath))
            {
                File.Delete(tempFilePath);
            }
        }
    }
}