using AuthApi.Data;
using AuthApi.Models;
using AuthApi.Models.Dtos;
using AuthApi.Services; 
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Security.Claims;
using System;
using System.Text.RegularExpressions;

namespace AuthApi.Controllers
{
    /// <summary>
    /// Gerencia o CRUD de Usuários.
    /// </summary>
    [Route("api/[controller]")]
    [ApiController]
    [Authorize]
    public class UsersController : ControllerBase
    {
        private readonly AppDbContext _context;
        private readonly IEmailService _emailService;

        public UsersController(AppDbContext context, IEmailService emailService) 
        { 
            _context = context; 
            _emailService = emailService;
        }

        private bool IsPasswordStrong(string password)
        {
            if (string.IsNullOrEmpty(password)) return false;
            var regex = new Regex(@"^(?=.*[0-9])(?=.*[^a-zA-Z0-9]).{8,}$");
            return regex.IsMatch(password);
        }

        /// <summary>
        /// Lista todos os Usuários registados (Apenas Admin).
        /// </summary>
        [HttpGet]
        [Authorize(Roles = "admin")]
        [ProducesResponseType(typeof(List<UserDataDto>), StatusCodes.Status200OK)]
        [ProducesResponseType(StatusCodes.Status401Unauthorized)]
        [ProducesResponseType(StatusCodes.Status403Forbidden)]
        public async Task<ActionResult<IEnumerable<UserDataDto>>> GetUsers()
        {
            var users = await _context.Users.AsNoTracking().ToListAsync();
            return Ok(users.Select(UserDataDto.FromUser).ToList());
        }

        /// <summary>
        /// Cria um novo Usuário e envia credenciais por email (Apenas Admin).
        /// </summary>
        /// <remarks>
        /// A senha gerada será provisória e o Usuário será obrigado a trocá-la no primeiro login.
        /// </remarks>
        [HttpPost]
        [Authorize(Roles = "admin")]
        [ProducesResponseType(typeof(UserDataDto), StatusCodes.Status201Created)]
        [ProducesResponseType(typeof(ErrorResponseDto), StatusCodes.Status400BadRequest)]
        public async Task<IActionResult> CreateUser([FromBody] RegisterRequestDto registerRequest)
        {
            if (registerRequest == null) return BadRequest(new ErrorResponseDto { Message = "Requisição inválida" });

            if (!IsPasswordStrong(registerRequest.password))
            {
                return BadRequest(new ErrorResponseDto { Message = "A senha provisória deve ter no mínimo 8 caracteres, conter pelo menos 1 número e 1 caractere especial." });
            }

            var identifierLower = registerRequest.username.ToLower();
            var emailLower = registerRequest.email.ToLower();

            var existingUser = await _context.Users.FirstOrDefaultAsync(u => 
                    u.username.ToLower() == identifierLower || u.email.ToLower() == emailLower);

            if (existingUser != null) return BadRequest(new ErrorResponseDto { Message = "Usuário ou Email já existe" });

            string passwordHash;
            try {
                passwordHash = BCrypt.Net.BCrypt.HashPassword(registerRequest.password);
            } catch(Exception) {
                return StatusCode(500, new ErrorResponseDto { Message = "Erro ao processar a senha." });
            }

            var newUser = new User
            {
                username = registerRequest.username,
                nome = registerRequest.nome,
                email = registerRequest.email,
                phone = registerRequest.phone,
                cod_assessor = registerRequest.cod_assessor,
                role = registerRequest.role,
                escritorio = registerRequest.escritorio,
                password_hash = passwordHash,
                profile_image_data = !string.IsNullOrEmpty(registerRequest.profile_image_base64)
                    ? Convert.FromBase64String(registerRequest.profile_image_base64) : null,
                
                must_change_password = true
            };

            try {
                _context.Users.Add(newUser);
                await _context.SaveChangesAsync();

                var emailBody = $@"
                <html>
                <body style='font-family: Arial, sans-serif; color: #333;'>
                    <div style='max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #ddd; border-radius: 8px;'>
                        <h2 style='color: #0056b3;'>Bem-vindo ao Sistema!</h2>
                        <p>Olá, <strong>{newUser.nome}</strong>,</p>
                        <p>A sua conta foi criada com sucesso.</p>
                        <p>Aqui estão as suas credenciais de acesso:</p>
                        <div style='background-color: #f9f9f9; padding: 15px; border-left: 4px solid #0056b3; margin: 20px 0;'>
                            <p><strong>Usuário:</strong> {newUser.username}</p>
                            <p><strong>Senha Provisória:</strong> {registerRequest.password}</p>
                        </div>
                        <p style='color: #d9534f;'><strong>Importante:</strong> Por motivos de segurança, será solicitado que altere esta senha no seu primeiro login.</p>
                    </div>
                </body>
                </html>";

                await _emailService.SendEmailAsync(newUser.email, "Credenciais de Acesso", emailBody);

            } catch (DbUpdateException) {
                return StatusCode(500, new ErrorResponseDto { Message = "Erro ao salvar usuário." });
            } catch (Exception ex) {
                Console.WriteLine($"Erro ao enviar email de boas-vindas: {ex.Message}");
            }

            var userDto = UserDataDto.FromUser(newUser);
            return CreatedAtAction(nameof(GetUsers), new { id = newUser.Id }, userDto);
        }

        /// <summary>
        /// Atualiza o perfil do Usuário autenticado.
        /// </summary>
        [HttpPut("me")]
        [ProducesResponseType(typeof(UserDataDto), StatusCodes.Status200OK)]
        [ProducesResponseType(typeof(ErrorResponseDto), StatusCodes.Status400BadRequest)]
        public async Task<IActionResult> UpdateMyProfile([FromBody] UpdateProfileDto updateDto)
        {
            var userIdString = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (!int.TryParse(userIdString, out var userId)) return Unauthorized(new ErrorResponseDto { Message = "Token inválido" });

            var user = await _context.Users.FindAsync(userId);
            if (user == null) return NotFound(new ErrorResponseDto { Message = "Usuário não encontrado" });

            user.nome = updateDto.nome; 
            user.phone = updateDto.phone;
            user.escritorio = updateDto.escritorio;

            if (!string.IsNullOrEmpty(updateDto.password))
            {
                if (string.IsNullOrEmpty(updateDto.current_password))
                    return BadRequest(new ErrorResponseDto { Message = "Para alterar a senha, deve fornecer a senha atual." });

                if (!BCrypt.Net.BCrypt.Verify(updateDto.current_password, user.password_hash))
                    return BadRequest(new ErrorResponseDto { Message = "A senha atual está incorreta." });

                if (!IsPasswordStrong(updateDto.password)) 
                    return BadRequest(new ErrorResponseDto { Message = "A nova senha deve ter no mínimo 8 caracteres, 1 número e 1 caractere especial." });
                
                user.password_hash = BCrypt.Net.BCrypt.HashPassword(updateDto.password);
            }

            if (updateDto.profile_image_base64 != null)
            {
                user.profile_image_data = string.IsNullOrEmpty(updateDto.profile_image_base64)
                    ? null : Convert.FromBase64String(updateDto.profile_image_base64);
            }

            try { await _context.SaveChangesAsync(); }
            catch (Exception) { return StatusCode(500, new ErrorResponseDto { Message = "Erro ao atualizar perfil." }); }

            return Ok(UserDataDto.FromUser(user));
        }

        /// <summary>
        /// Atualiza qualquer Usuário (Apenas Admin).
        /// </summary>
        [HttpPut("{id}")]
        [Authorize(Roles = "admin")]
        [ProducesResponseType(typeof(UserDataDto), StatusCodes.Status200OK)]
        public async Task<IActionResult> AdminUpdateUser(int id, [FromBody] AdminUpdateUserDto updateDto)
        {
            var user = await _context.Users.FindAsync(id);
            if (user == null) return NotFound(new ErrorResponseDto { Message = "Usuário não encontrado" });

            var identifierLower = updateDto.username.ToLower();
            var emailLower = updateDto.email.ToLower();

            var conflict = await _context.Users.FirstOrDefaultAsync(u => u.Id != id && 
                (u.username.ToLower() == identifierLower || u.email.ToLower() == emailLower));
            
            if (conflict != null) return BadRequest(new ErrorResponseDto { Message = "Username ou Email já em uso." });

            user.username = updateDto.username;
            user.nome = updateDto.nome;
            user.email = updateDto.email;
            user.phone = updateDto.phone;
            user.cod_assessor = updateDto.cod_assessor;
            user.role = updateDto.role;
            user.escritorio = updateDto.escritorio;

            if (updateDto.profile_image_base64 != null)
            {
                user.profile_image_data = string.IsNullOrEmpty(updateDto.profile_image_base64)
                    ? null : Convert.FromBase64String(updateDto.profile_image_base64);
            }

            try { await _context.SaveChangesAsync(); }
            catch (Exception) { return StatusCode(500, new ErrorResponseDto { Message = "Erro ao atualizar." }); }

            return Ok(UserDataDto.FromUser(user));
        }
        
        /// <summary>
        /// Remove um Usuário (Apenas Admin).
        /// </summary>
        [HttpDelete("{id}")]
        [Authorize(Roles = "admin")]
        [ProducesResponseType(StatusCodes.Status204NoContent)]
        public async Task<IActionResult> DeleteUser(int id)
        {
            var user = await _context.Users.FindAsync(id);
            if (user == null) return NotFound(new ErrorResponseDto { Message = "Usuário não encontrado" });
            var currentUserIdString = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (int.TryParse(currentUserIdString, out var currentUserId) && currentUserId == id)
                return BadRequest(new ErrorResponseDto { Message = "Não pode eliminar a sua própria conta." });

            try { _context.Users.Remove(user); await _context.SaveChangesAsync(); }
            catch (Exception) { return StatusCode(500, new ErrorResponseDto { Message = "Erro ao eliminar Usuário." }); }
            return NoContent();
        }
    }
}