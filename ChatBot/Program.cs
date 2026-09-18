using DataAccessLayer;
using Microsoft.AspNetCore.Authentication.Cookies;
using Microsoft.EntityFrameworkCore;
using DataAccessLayer.Repositories.Interfaces;
using DataAccessLayer.Repositories.Implements;
using ServiceLayer.Implements;
using ServiceLayer.Interfaces;
using DataAccessLayer.Repositories;
using BusinessObject.Entities;
using BCrypt.Net;
using DotNetEnv;
using PayOS;
using System.IO;

var currentDir = Directory.GetCurrentDirectory();
string? loadedEnvPath = null;

while (!string.IsNullOrWhiteSpace(currentDir))
{
    var envPath = Path.Combine(currentDir, ".env");

    if (File.Exists(envPath))
    {
        Env.Load(
            envPath,
            new LoadOptions(
                setEnvVars: true,
                clobberExistingVars: true,
                onlyExactPath: true));

        loadedEnvPath = envPath;
        break;
    }

    currentDir = Directory.GetParent(currentDir)?.FullName;
}

if (loadedEnvPath == null)
{
    throw new FileNotFoundException(
        "Không tìm thấy file .env trong project hoặc thư mục cha.");
}

Console.WriteLine($"[OK] Đã nạp .env tại: {loadedEnvPath}");


var builder = WebApplication.CreateBuilder(args);

builder.Services.AddDbContext<AppDbContext>(options =>
    options.UseNpgsql(builder.Configuration.GetConnectionString("DefaultConnection"),
        o => o.UseVector())); 

builder.Services.AddScoped<IDocumentRepository, DocumentRepository>();
builder.Services.AddScoped<IDocumentChunkRepository, DocumentChunkRepository>();

builder.Services.AddScoped<IDocumentService, DocumentService>();
builder.Services.AddScoped<IDocumentChunkService, DocumentChunkService>();

// Đăng ký Background Job sao lưu dữ liệu lên Supabase
builder.Services.AddHostedService<DatabaseBackupService>();

// Register custom services
var uploadFolderPath = builder.Configuration["UploadFolderPath"] ?? "D:\\Upload";


var maxFileSize = long.TryParse(builder.Configuration["MaxFileSize"], out var size) ? size : 3145728; // 3MB default

var geminiApiKey =
    builder.Configuration["Gemini:ApiKey"] ?? builder.Configuration["GEMINI_API_KEY"];

if (string.IsNullOrWhiteSpace(geminiApiKey))
{
    throw new InvalidOperationException("Gemini API Key chưa cấu hình.");
}

Console.WriteLine($"Gemini key: {geminiApiKey.Substring(0, 6)}...");

geminiApiKey = geminiApiKey.Trim();

var prefixLength = Math.Min(6, geminiApiKey.Length);
var suffixLength = Math.Min(4, geminiApiKey.Length);

Console.WriteLine(
    $"Gemini key loaded: " +
    $"{geminiApiKey[..prefixLength]}..." +
    $"{geminiApiKey[^suffixLength..]}, " +
    $"length={geminiApiKey.Length}");


builder.Services.AddSingleton<IFileUploadService>(new FileUploadService(uploadFolderPath, maxFileSize));
builder.Services.AddScoped<ITextExtractionService, TextExtractionService>();
builder.Services.AddScoped<IChunkingService, ChunkingService>();
builder.Services.AddScoped<IEmbeddingService>(sp => new EmbeddingService(
    geminiApiKey ?? throw new InvalidOperationException("GEMINI_API_KEY or OPENAI_API_KEY not configured")
));
builder.Services.AddScoped<IChatService>(sp => new ChatService(geminiApiKey ?? throw new InvalidOperationException("GEMINI_API_KEY or OPENAI_API_KEY not configured")));
builder.Services.AddScoped<IIndexingService, IndexingService>();
builder.Services.AddScoped<IRetrievalService, RetrievalService>();
builder.Services.AddScoped<IChatHistoryService, ChatHistoryService>();
builder.Services.AddScoped<IRagService, RagService>();

// PayOS Configuration
var payosClientId = Environment.GetEnvironmentVariable("PAYOS_CLIENT_ID") ?? "";
var payosApiKey = Environment.GetEnvironmentVariable("PAYOS_API_KEY") ?? "";
var payosChecksumKey = Environment.GetEnvironmentVariable("PAYOS_CHECKSUM_KEY") ?? "";

if (!string.IsNullOrWhiteSpace(payosClientId) && payosClientId != "your_client_id_here")
{
    var payOSClient = new PayOSClient(payosClientId, payosApiKey, payosChecksumKey);
    builder.Services.AddSingleton(payOSClient);
    Console.WriteLine($"[OK] PayOS đã cấu hình: ClientID={payosClientId[..Math.Min(6, payosClientId.Length)]}...");
}
else
{
    Console.WriteLine("[WARN] PayOS chưa cấu hình. Vui lòng thêm PAYOS_CLIENT_ID, PAYOS_API_KEY, PAYOS_CHECKSUM_KEY vào .env");
    // Register a null-safe placeholder so DI doesn't fail
    builder.Services.AddSingleton(new PayOSClient("placeholder", "placeholder", "placeholder"));
}

builder.Services.AddScoped<ISubscriptionService, SubscriptionService>();
builder.Services.AddMemoryCache();
builder.Services.AddAntiforgery(options =>
{
    options.HeaderName = "RequestVerificationToken";
});
builder.Services.AddRazorPages();

builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(c =>
{
    c.SwaggerDoc("v1", new Microsoft.OpenApi.Models.OpenApiInfo
    {
        Title = "Paper AI Core RAG API",
        Version = "v1",
        Description = "API cho lõi RAG xử lý bài báo khoa học"
    });
});

var app = builder.Build();

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI(c =>
    {
        c.SwaggerEndpoint("/swagger/v1/swagger.json", "Paper AI API v1");
        c.RoutePrefix = "swagger";
    });
}

app.UseHttpsRedirection();
app.UseStaticFiles();
app.UseRouting();

app.MapRazorPages();

app.Run();

