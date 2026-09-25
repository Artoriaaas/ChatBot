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
using Microsoft.Extensions.Caching.Memory;
using System.Net.Mail;
using System.Net;

namespace ChatBot.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class AuthController : ControllerBase
    {
        private readonly AppDbContext _context;
        private readonly IConfiguration _configuration;
        private readonly IMemoryCache _cache;

        public AuthController(AppDbContext context, IConfiguration configuration, IMemoryCache cache)
        {
            _context = context;
            _configuration = configuration;
            _cache = cache;
        }

        [HttpPost("register")]
        public async Task<IActionResult> Register([FromBody] RegisterRequest request)
        {
            var email = request.Email.Trim().ToLower();
            if (await _context.Users.AnyAsync(u => u.Email.ToLower() == email))
            {
                return BadRequest("Email đã được sử dụng.");
            }

            var otp = new Random().Next(100000, 999999).ToString();
            _cache.Set($"RegisterOTP_{email}", otp, TimeSpan.FromMinutes(5));
            _cache.Set($"RegisterData_{email}", request, TimeSpan.FromMinutes(5));

            Console.WriteLine($"[AUTH OTP] Register OTP for {email}: {otp}");

            await SendEmailAsync(email, "Mã xác nhận đăng ký", $"Mã OTP của bạn là: {otp}");

            return Ok(new { message = "Mã OTP đã được gửi đến email của bạn." });
        }

        [HttpPost("verify-register")]
        public async Task<IActionResult> VerifyRegister([FromBody] VerifyOtpRequest request)
        {
            var email = request.Email.Trim().ToLower();
            var otp = request.Otp.Trim();

            if (_cache.TryGetValue($"RegisterOTP_{email}", out string? savedOtp) && savedOtp == otp)
            {
                if (_cache.TryGetValue($"RegisterData_{email}", out RegisterRequest? regData) && regData != null)
                {
                    var user = new User
                    {
                        Email = regData.Email.Trim().ToLower(),
                        FullName = regData.FullName,
                        PasswordHash = BCrypt.Net.BCrypt.HashPassword(regData.Password),
                        Role = Role.Student
                    };
                    _context.Users.Add(user);
                    await _context.SaveChangesAsync();

                    _cache.Remove($"RegisterOTP_{email}");
                    _cache.Remove($"RegisterData_{email}");

                    var token = GenerateJwtToken(user);
                    return Ok(new { message = "Đăng ký thành công", token });
                }
            }
            return BadRequest("Mã OTP không hợp lệ hoặc đã hết hạn.");
        }

        [HttpPost("login")]
        public async Task<IActionResult> Login([FromBody] LoginRequest request)
        {
            var email = request.Email.Trim().ToLower();
            var user = await _context.Users.FirstOrDefaultAsync(u => u.Email.ToLower() == email);
            
            if (user == null || user.PasswordHash == null || !BCrypt.Net.BCrypt.Verify(request.Password, user.PasswordHash))
            {
                return Unauthorized("Email hoặc mật khẩu không đúng.");
            }

            var otp = new Random().Next(100000, 999999).ToString();
            _cache.Set($"LoginOTP_{email}", otp, TimeSpan.FromMinutes(5));

            Console.WriteLine($"[AUTH OTP] Login OTP for {email}: {otp}");

            await SendEmailAsync(email, "Mã xác nhận đăng nhập", $"Mã OTP của bạn là: {otp}");

            return Ok(new { message = "Mã OTP đã được gửi đến email. Vui lòng xác nhận để đăng nhập." });
        }

        [HttpPost("verify-login")]
        public async Task<IActionResult> VerifyLogin([FromBody] VerifyOtpRequest request)
        {
            var email = request.Email.Trim().ToLower();
            var otp = request.Otp.Trim();

            if (_cache.TryGetValue($"LoginOTP_{email}", out string? savedOtp) && savedOtp == otp)
            {
                var user = await _context.Users.FirstOrDefaultAsync(u => u.Email.ToLower() == email);
                if (user != null)
                {
                    var token = GenerateJwtToken(user);
                    _cache.Remove($"LoginOTP_{email}");
                    return Ok(new { token });
                }
            }
            return BadRequest("Mã OTP không hợp lệ hoặc đã hết hạn.");
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

        private async Task SendEmailAsync(string toEmail, string subject, string body)
        {
            var host = _configuration["Email:Host"];
            var port = int.Parse(_configuration["Email:Port"] ?? "587");
            var user = _configuration["Email:User"];
            var pass = _configuration["Email:Pass"];

            if (string.IsNullOrEmpty(host) || string.IsNullOrEmpty(user) || string.IsNullOrEmpty(pass))
            {
                Console.WriteLine("[SendEmailAsync] Email configuration missing, skipping send.");
                return;
            }

            try
            {
                using var client = new SmtpClient(host, port)
                {
                    Credentials = new NetworkCredential(user, pass),
                    EnableSsl = true,
                    Timeout = 10000
                };

                var mailMessage = new MailMessage
                {
                    From = new MailAddress(user),
                    Subject = subject,
                    Body = body,
                    IsBodyHtml = true
                };
                mailMessage.To.Add(toEmail);

                await client.SendMailAsync(mailMessage);
                Console.WriteLine($"[SendEmailAsync] Successfully sent email to {toEmail}");
            }
            catch (Exception ex)
            {
                Console.WriteLine($"[SendEmailAsync] Error sending email to {toEmail}: {ex.Message}");
            }
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

    public class VerifyOtpRequest
    {
        public string Email { get; set; } = string.Empty;
        public string Otp { get; set; } = string.Empty;
    }
}
