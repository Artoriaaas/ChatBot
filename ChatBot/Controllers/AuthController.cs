using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Authentication.Cookies;
using Microsoft.AspNetCore.Authentication.Google;
using Microsoft.AspNetCore.Mvc;
using Google.Apis.Auth;
using Microsoft.IdentityModel.Tokens;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using System.Threading.Tasks;
using DataAccessLayer;
using BusinessObject.Entities;
using BusinessObject.Enums;
using Microsoft.EntityFrameworkCore;

namespace ChatBot.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class AuthController : ControllerBase
    {
        private readonly AppDbContext _context;
        private readonly IConfiguration _configuration;

        public AuthController(AppDbContext context, IConfiguration configuration)
        {
            _context = context;
            _configuration = configuration;
        }

        [HttpPost("register")]
        public async Task<IActionResult> Register([FromBody] RegisterRequest request)
        {
            if (await _context.Users.AnyAsync(u => u.Email == request.Email))
            {
                return BadRequest("Email đã được sử dụng.");
            }

            var user = new User
            {
                Email = request.Email,
                FullName = request.FullName,
                PasswordHash = BCrypt.Net.BCrypt.HashPassword(request.Password),
                Role = Role.Student // Default role
            };

            _context.Users.Add(user);
            await _context.SaveChangesAsync();

            return Ok(new { message = "Đăng ký thành công" });
        }

        [HttpPost("login")]
        public async Task<IActionResult> Login([FromBody] LoginRequest request)
        {
            var user = await _context.Users.FirstOrDefaultAsync(u => u.Email == request.Email);
            
            if (user == null || user.PasswordHash == null || !BCrypt.Net.BCrypt.Verify(request.Password, user.PasswordHash))
            {
                return Unauthorized("Email hoặc mật khẩu không đúng.");
            }

            var token = GenerateJwtToken(user);
            return Ok(new { token });
        }

        [HttpGet("google-login")]
        public IActionResult GoogleLogin()
        {
            var properties = new AuthenticationProperties { RedirectUri = Url.Action("GoogleResponse") };
            return Challenge(properties, GoogleDefaults.AuthenticationScheme);
        }

        [HttpGet("google-response")]
        public async Task<IActionResult> GoogleResponse()
        {
            var result = await HttpContext.AuthenticateAsync(CookieAuthenticationDefaults.AuthenticationScheme);
            
            if (result.Principal == null)
                return BadRequest("Lỗi đăng nhập Google.");

            var emailClaim = result.Principal.FindFirst(ClaimTypes.Email) ?? result.Principal.FindFirst("email");
            var nameClaim = result.Principal.FindFirst(ClaimTypes.Name) ?? result.Principal.FindFirst("name");

            if (emailClaim == null)
            {
                return BadRequest("Không thể lấy email từ Google.");
            }

            var email = emailClaim.Value;
            var user = await _context.Users.FirstOrDefaultAsync(u => u.Email == email);

            if (user == null)
            {
                user = new User
                {
                    Email = email,
                    FullName = nameClaim?.Value,
                    Role = Role.Student
                };
                _context.Users.Add(user);
                await _context.SaveChangesAsync();
            }

            var token = GenerateJwtToken(user);

            // Return a view or JSON with token (for frontend to consume)
            return Ok(new { message = "Đăng nhập Google thành công", token });
        }

        [HttpPost("google-client")]
        public async Task<IActionResult> GoogleClientLogin([FromBody] GoogleClientLoginRequest request)
        {
            if (string.IsNullOrWhiteSpace(request.IdToken))
            {
                return BadRequest("Thiếu IdToken từ Google.");
            }

            GoogleJsonWebSignature.Payload payload;
            try
            {
                payload = await GoogleJsonWebSignature.ValidateAsync(request.IdToken);
            }
            catch (InvalidJwtException)
            {
                return BadRequest("Token Google không hợp lệ hoặc đã hết hạn.");
            }

            var email = payload.Email;
            
            var user = await _context.Users.FirstOrDefaultAsync(u => u.Email == email);

            if (user == null)
            {
                return Unauthorized(new { message = "Tài khoản chưa được liên kết hoặc chưa tồn tại. Vui lòng đăng ký tài khoản mới." });
            }

            var token = GenerateJwtToken(user);

            return Ok(new { message = "Đăng nhập Google thành công", token });
        }

        private string GenerateJwtToken(User user)
        {
            var securityKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(_configuration["Jwt:Key"] ?? "ChatBotSuperSecretKeyThatIsVeryLongAndSecureForJWT123!@#"));
            var credentials = new SigningCredentials(securityKey, SecurityAlgorithms.HmacSha256);

            var claims = new[]
            {
                new Claim(JwtRegisteredClaimNames.Sub, user.Id.ToString()),
                new Claim(JwtRegisteredClaimNames.Email, user.Email),
                new Claim("role", user.Role.ToString()),
                new Claim(JwtRegisteredClaimNames.Jti, Guid.NewGuid().ToString())
            };

            var token = new JwtSecurityToken(
                issuer: _configuration["Jwt:Issuer"],
                audience: _configuration["Jwt:Audience"],
                claims: claims,
                expires: DateTime.Now.AddMinutes(Convert.ToDouble(_configuration["Jwt:ExpireMinutes"] ?? "480")),
                signingCredentials: credentials);

            return new JwtSecurityTokenHandler().WriteToken(token);
        }
    }

    public class RegisterRequest
    {
        public string Email { get; set; } = string.Empty;
        public string Password { get; set; } = string.Empty;
        public string FullName { get; set; } = string.Empty;
    }

    public class LoginRequest
    {
        public string Email { get; set; } = string.Empty;
        public string Password { get; set; } = string.Empty;
    }

    public class GoogleClientLoginRequest
    {
        public string Email { get; set; } = string.Empty;
        public string FullName { get; set; } = string.Empty;
        public string? GoogleId { get; set; }
        public string? IdToken { get; set; }
    }
}
