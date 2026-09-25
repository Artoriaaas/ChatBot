using DataAccessLayer;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.IdentityModel.Tokens;
using System.Text;
using Microsoft.EntityFrameworkCore;
using DataAccessLayer.Repositories.Interfaces;
using DataAccessLayer.Repositories.Implements;
using ServiceLayer.Implements;
using ServiceLayer.Interfaces;
using DataAccessLayer.Repositories;
using BusinessObject.Entities;
using BCrypt.Net;
using PayOS;
using System.IO;
var builder = WebApplication.CreateBuilder(args);

var connectionString = builder.Configuration.GetConnectionString("DefaultConnection") 
    ?? builder.Configuration["DefaultConnection"] 
    ?? builder.Configuration["ConnectionStrings:DefaultConnection"]
    ?? Environment.GetEnvironmentVariable("ConnectionStrings__DefaultConnection")
    ?? Environment.GetEnvironmentVariable("DefaultConnection")
    ?? "Host=localhost;Port=5432;Database=PaperdeskDb;Username=postgres;Password=12345;Trust Server Certificate=true";

builder.Services.AddDbContext<AppDbContext>(options =>
    options.UseNpgsql(connectionString,
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
var uploadFolderPath = builder.Configuration["Upload:FolderPath"] ?? "D:\\Upload";

var supabaseUrl = builder.Configuration["Supabase:Url"];
var supabaseKey = builder.Configuration["Supabase:Key"];
if (!string.IsNullOrEmpty(supabaseUrl) && !string.IsNullOrEmpty(supabaseKey))
{
    var options = new Supabase.SupabaseOptions
    {
        AutoConnectRealtime = true
    };
    var supabaseClient = new Supabase.Client(supabaseUrl, supabaseKey, options);
    builder.Services.AddSingleton(supabaseClient);
}

var maxFileSize = builder.Configuration.GetValue<long>("Upload:MaxFileSize", 3145728); // 3MB default

var geminiApiKey = builder.Configuration["Gemini:ApiKey"];

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
var payosClientId = builder.Configuration["PayOS:ClientId"] ?? "";
var payosApiKey = builder.Configuration["PayOS:ApiKey"] ?? "";
var payosChecksumKey = builder.Configuration["PayOS:ChecksumKey"] ?? "";

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
        options.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
        options.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
        options.DefaultScheme = JwtBearerDefaults.AuthenticationScheme;
    })
    .AddJwtBearer(options =>
    {
        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuer = true,
            ValidateAudience = true,
            ValidateLifetime = true,
            ValidateIssuerSigningKey = true,
            ValidIssuer = builder.Configuration["Jwt:Issuer"],
            ValidAudience = builder.Configuration["Jwt:Audience"],
            IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(builder.Configuration["Jwt:Key"] ?? "ChatBotSuperSecretKeyThatIsVeryLongAndSecureForJWT123!@#"))
        };
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
builder.Services.AddControllers()
    .AddJsonOptions(options =>
    {
        options.JsonSerializerOptions.ReferenceHandler = System.Text.Json.Serialization.ReferenceHandler.IgnoreCycles;
        options.JsonSerializerOptions.DefaultIgnoreCondition = System.Text.Json.Serialization.JsonIgnoreCondition.WhenWritingNull;
    });

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

app.UseSwagger();
app.UseSwaggerUI(c =>
{
    c.SwaggerEndpoint("/swagger/v1/swagger.json", "Paper AI API v1");
    c.RoutePrefix = "swagger";
});

app.UseHttpsRedirection();
app.UseStaticFiles();
app.UseRouting();
app.UseCors("AllowAll");

app.MapRazorPages();
app.MapControllers();
app.MapGet("/", () => Results.Redirect("/swagger"));

app.MapHub<ChatBot.Hubs.NotificationHub>("/notificationHub");


app.Run();


 



