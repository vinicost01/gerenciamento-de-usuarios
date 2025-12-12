using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using AuthApi.Data;
using AuthApi.Models.Dtos;
using AuthApi.Services;
using Microsoft.AspNetCore.Authorization;
using AuthApi.Models;
using System;
using System.Security.Cryptography;
using System.Text.RegularExpressions;
using System.Security.Claims;

namespace AuthApi.Controllers
{
    /// <summary>
    /// Controla a autenticação e recuperação de contas.
    /// </summary>
    [Route("api/[controller]")]
    [ApiController]
    public class AuthController : ControllerBase
    {
        private readonly AppDbContext _context;
        private readonly TokenService _tokenService;
        private readonly IEmailService _emailService;

        public AuthController(AppDbContext context, TokenService tokenService, IEmailService emailService)
        {
            _context = context; 
            _tokenService = tokenService;
            _emailService = emailService;
        }

        private bool IsPasswordStrong(string password)
        {
            if (string.IsNullOrEmpty(password)) return false;
            var regex = new Regex(@"^(?=.*[0-9])(?=.*[^a-zA-Z0-9]).{8,}$");
            return regex.IsMatch(password);
        }

        /// <summary>
        /// Realiza o login de um Usuário.
        /// </summary>
        /// <remarks>
        /// Retorna um token JWT se as credenciais forem válidas. 
        /// Verifica também se o Usuário precisa alterar a senha provisória.
        /// </remarks>
        /// <param name="loginRequest">Credenciais (Username/Email e Senha)</param>
        /// <returns>Token de acesso e dados do Usuário.</returns>
        [HttpPost("login")]
        [ProducesResponseType(typeof(LoginResponseDto), StatusCodes.Status200OK)]
        [ProducesResponseType(typeof(ErrorResponseDto), StatusCodes.Status400BadRequest)]
        [ProducesResponseType(typeof(ErrorResponseDto), StatusCodes.Status401Unauthorized)]
        public async Task<IActionResult> Login([FromBody] LoginRequestDto loginRequest)
        {
            if (loginRequest == null) return BadRequest(new ErrorResponseDto { Message = "Invalid request" });

            var identifierLower = loginRequest.Identifier.ToLower();
            var user = await _context.Users.FirstOrDefaultAsync(u => 
                    u.username.ToLower() == identifierLower || u.email.ToLower() == identifierLower);

            if (user == null) return Unauthorized(new ErrorResponseDto { Message = "Invalid credentials" });

            bool isPasswordValid = false;
            try {
                isPasswordValid = BCrypt.Net.BCrypt.Verify(loginRequest.Password, user.password_hash.Trim());
            } catch { return Unauthorized(new ErrorResponseDto { Message = "Invalid credentials" }); }

            if (!isPasswordValid) return Unauthorized(new ErrorResponseDto { Message = "Invalid credentials" });
            
            var accessToken = _tokenService.GenerateJwtToken(user);
            
            return Ok(new LoginResponseDto { 
                AccessToken = accessToken, 
                User = UserDataDto.FromUser(user),
                MustChangePassword = user.must_change_password 
            });
        }

        /// <summary>
        /// Altera a senha provisória no primeiro acesso.
        /// </summary>
        /// <remarks>
        /// Requer autenticação. Após o sucesso, o Usuário deve fazer login novamente.
        /// </remarks>
        [HttpPost("change-initial-password")]
        [Authorize]
        [ProducesResponseType(StatusCodes.Status200OK)]
        [ProducesResponseType(typeof(ErrorResponseDto), StatusCodes.Status400BadRequest)]
        [ProducesResponseType(StatusCodes.Status401Unauthorized)]
        public async Task<IActionResult> ChangeInitialPassword([FromBody] ChangeInitialPasswordDto model)
        {
            if (!IsPasswordStrong(model.NewPassword))
            {
                return BadRequest(new ErrorResponseDto { Message = "A nova senha deve ter no mínimo 8 caracteres, 1 número e 1 caractere especial." });
            }

            var userIdString = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (!int.TryParse(userIdString, out var userId)) return Unauthorized();

            var user = await _context.Users.FindAsync(userId);
            if (user == null) return NotFound();

            user.password_hash = BCrypt.Net.BCrypt.HashPassword(model.NewPassword);
            user.must_change_password = false;

            await _context.SaveChangesAsync();

            return Ok(new { Message = "Senha alterada com sucesso. Por favor, faça login novamente." });
        }

        /// <summary>
        /// Solicita um código de recuperação de senha.
        /// </summary>
        /// <remarks>
        /// Envia um email com um código de 6 dígitos se o email existir na base de dados.
        /// </remarks>
        [HttpPost("forgot-password")]
        [ProducesResponseType(StatusCodes.Status200OK)]
        public async Task<IActionResult> ForgotPassword([FromBody] ForgotPasswordDto model)
        {
            var user = await _context.Users.FirstOrDefaultAsync(u => u.email.ToLower() == model.Email.ToLower());
            if (user == null) return Ok(new { Message = "Se o email existir, o código foi enviado." });

            var token = Random.Shared.Next(100000, 999999).ToString();
            user.password_reset_token = token;
            user.password_reset_expiry = DateTime.UtcNow.AddMinutes(30); 
            await _context.SaveChangesAsync();

            var emailBody = $@"
            <html>
            <body style='font-family: Arial, sans-serif; color: #333;'>
                <div style='max-width: 500px; margin: 0 auto; padding: 20px; border: 1px solid #ddd; border-radius: 8px; text-align: center;'>
                    <h2 style='color: #0056b3;'>Recuperação de Senha</h2>
                    <p>Utilize o código abaixo na aplicação para definir uma nova senha:</p>
                    <div style='background-color: #f4f4f4; padding: 15px; margin: 20px 0; border-radius: 5px;'>
                        <h1 style='margin: 0; letter-spacing: 5px; color: #333;'>{token}</h1>
                    </div>
                    <p style='font-size: 12px; color: #888;'>Este código expira em 30 minutos.</p>
                </div>
            </body>
            </html>";

            try { await _emailService.SendEmailAsync(user.email, "Seu Código de Recuperação", emailBody); }
            catch(Exception ex) { return StatusCode(500, new ErrorResponseDto { Message = "Erro ao enviar email: " + ex.Message }); }

            return Ok(new { Message = "Código enviado com sucesso." });
        }

        /// <summary>
        /// Redefine a senha utilizando o código recebido por email.
        /// </summary>
        [HttpPost("reset-password")]
        [ProducesResponseType(StatusCodes.Status200OK)]
        [ProducesResponseType(typeof(ErrorResponseDto), StatusCodes.Status400BadRequest)]
        public async Task<IActionResult> ResetPassword([FromBody] ResetPasswordDto model)
        {
            if (!IsPasswordStrong(model.NewPassword))
            {
                return BadRequest(new ErrorResponseDto { Message = "A nova senha deve ter no mínimo 8 caracteres, 1 número e 1 caractere especial." });
            }

            var user = await _context.Users.FirstOrDefaultAsync(u => u.password_reset_token == model.Token);

            if (user == null || user.password_reset_expiry < DateTime.UtcNow)
            {
                return BadRequest(new ErrorResponseDto { Message = "Código inválido ou expirado." });
            }

            user.password_hash = BCrypt.Net.BCrypt.HashPassword(model.NewPassword);
            user.password_reset_token = null;
            user.password_reset_expiry = null;
            user.must_change_password = false;

            await _context.SaveChangesAsync();

            return Ok(new { Message = "Senha redefinida com sucesso!" });
        }
    }
}