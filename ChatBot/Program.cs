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
using PayOS;
using DotNetEnv;
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

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddDbContext<AppDbContext>(options =>
    options.UseNpgsql(builder.Configuration.GetConnectionString("DefaultConnection"),
        o => o.UseVector())); 

builder.Services.AddScoped<IDocumentRepository, DocumentRepository>();
builder.Services.AddScoped<IDocumentChunkRepository, DocumentChunkRepository>();
builder.Services.AddScoped<IPaperRepository, PaperRepository>();

builder.Services.AddScoped<IDocumentService, DocumentService>();
builder.Services.AddScoped<IDocumentChunkService, DocumentChunkService>();
builder.Services.AddScoped<IPaperService, PaperService>();

// Đăng ký Background Job sao lưu dữ liệu lên Supabase
builder.Services.AddHostedService<DatabaseBackupService>();

// Register custom services
var uploadFolderPath = builder.Configuration["UploadFolderPath"] ?? "D:\\Upload";

var supabaseUrl = builder.Configuration["Supabase:Url"] ?? builder.Configuration["SUPABASE_URL"];
var supabaseKey = builder.Configuration["Supabase:Key"] ?? builder.Configuration["SUPABASE_KEY"];
if (!string.IsNullOrEmpty(supabaseUrl) && !string.IsNullOrEmpty(supabaseKey))
{
    var options = new Supabase.SupabaseOptions
    {
        AutoConnectRealtime = true
    };
    var supabaseClient = new Supabase.Client(supabaseUrl, supabaseKey, options);
    builder.Services.AddSingleton(supabaseClient);
}

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
builder.Services.AddHttpClient<IGrobidService, GrobidService>();
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
var payosClientId = builder.Configuration["PayOS:ClientId"] ?? builder.Configuration["PAYOS_CLIENT_ID"] ?? "";
var payosApiKey = builder.Configuration["PayOS:ApiKey"] ?? builder.Configuration["PAYOS_API_KEY"] ?? "";
var payosChecksumKey = builder.Configuration["PayOS:ChecksumKey"] ?? builder.Configuration["PAYOS_CHECKSUM_KEY"] ?? "";

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

builder.Services.AddMemoryCache();
builder.Services.AddAntiforgery(options =>
{
    options.HeaderName = "RequestVerificationToken";
});

builder.Services.AddAuthentication(options =>
    {
        options.DefaultScheme = CookieAuthenticationDefaults.AuthenticationScheme;
        options.DefaultAuthenticateScheme = CookieAuthenticationDefaults.AuthenticationScheme;
        options.DefaultChallengeScheme = CookieAuthenticationDefaults.AuthenticationScheme;
    })
    .AddCookie(CookieAuthenticationDefaults.AuthenticationScheme, options =>
    {
        options.LoginPath = "/Auth/Login";
        options.AccessDeniedPath = "/Auth/AccessDenied";
        options.ExpireTimeSpan = TimeSpan.FromHours(8);
        options.Cookie.Name = "ChatBot.Auth";
        options.ForwardDefaultSelector = ctx =>
        {
            var path = ctx.Request.Path.Value ?? "";
            if (path.StartsWith("/Admin", StringComparison.OrdinalIgnoreCase))
            {
                return "AdminScheme";
            }
            if (path.StartsWith("/Lecturer", StringComparison.OrdinalIgnoreCase))
            {
                return "LectureScheme";
            }
            if (path.StartsWith("/Student", StringComparison.OrdinalIgnoreCase))
            {
                return "StudentScheme";
            }

            var referer = ctx.Request.Headers["Referer"].ToString();
            if (!string.IsNullOrEmpty(referer))
            {
                try
                {
                    var refererUri = new Uri(referer);
                    var refererPath = refererUri.AbsolutePath;
                    if (refererPath.StartsWith("/Admin", StringComparison.OrdinalIgnoreCase))
                    {
                        return "AdminScheme";
                    }
                    if (refererPath.StartsWith("/Lecturer", StringComparison.OrdinalIgnoreCase))
                    {
                        return "LectureScheme";
                    }
                    if (refererPath.StartsWith("/Student", StringComparison.OrdinalIgnoreCase))
                    {
                        return "StudentScheme";
                    }
                }
                catch
                {
                    // Ignore malformed referer headers
                }
            }

            return null;
        };
    })
    .AddCookie("AdminScheme", options =>
    {
        options.LoginPath = "/Auth/Login";
        options.AccessDeniedPath = "/Auth/AccessDenied";
        options.ExpireTimeSpan = TimeSpan.FromHours(8);
        options.Cookie.Name = "ChatBot.Auth.Admin";
    })
    .AddCookie("LectureScheme", options =>
    {
        options.LoginPath = "/Auth/Login";
        options.AccessDeniedPath = "/Auth/AccessDenied";
        options.ExpireTimeSpan = TimeSpan.FromHours(8);
        options.Cookie.Name = "ChatBot.Auth.Lecture";
    })
    .AddCookie("StudentScheme", options =>
    {
        options.LoginPath = "/Auth/Login";
        options.AccessDeniedPath = "/Auth/AccessDenied";
        options.ExpireTimeSpan = TimeSpan.FromHours(8);
        options.Cookie.Name = "ChatBot.Auth.Student";
    })
    .AddGoogle(options =>
    {
        options.ClientId = builder.Configuration["Google:ClientId"] ?? builder.Configuration["GOOGLE_CLIENT_ID"] ?? "placeholder_client_id";
        options.ClientSecret = builder.Configuration["Google:ClientSecret"] ?? builder.Configuration["GOOGLE_CLIENT_SECRET"] ?? "placeholder_client_secret";
    });

builder.Services.AddAuthorization();

builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowAll", policy =>
    {
        policy.AllowAnyOrigin()
              .AllowAnyHeader()
              .AllowAnyMethod();
    });
});

builder.Services.AddRazorPages();
builder.Services.AddSession();
builder.Services.AddSignalR();
builder.Services.AddControllers();

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
app.UseCors("AllowAll");

app.MapRazorPages();
app.MapControllers();

app.MapFallbackToPage("/Auth/Login");
app.MapHub<ChatBot.Hubs.NotificationHub>("/notificationHub");

//SeedDatabase(app);

app.Run();


 



