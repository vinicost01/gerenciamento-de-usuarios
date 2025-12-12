using System;
using System.ComponentModel.DataAnnotations;

namespace AuthApi.Models.Dtos
{
    /// <summary>
    /// Dados necessários para login.
    /// </summary>
    public class LoginRequestDto
    {
        /// <summary>Username ou Email.</summary>
        [Required] public string Identifier { get; set; } = string.Empty;
        /// <summary>Senha do Usuário.</summary>
        [Required] public string Password { get; set; } = string.Empty;
    }

    public class LoginResponseDto
    {
        public string AccessToken { get; set; } = string.Empty;
        public UserDataDto User { get; set; } = null!;
        public bool MustChangePassword { get; set; }
    }

    public class UserDataDto
    {
        public int id { get; set; }
        public string username { get; set; } = string.Empty;
        public string nome { get; set; } = string.Empty;
        public string email { get; set; } = string.Empty;
        public string? phone { get; set; }
        public string? cod_assessor { get; set; }
        public string role { get; set; } = string.Empty;
        public string? escritorio { get; set; }
        public string? profile_image_base64 { get; set; }

        public static UserDataDto FromUser(User user)
        {
            return new UserDataDto
            {
                id = user.Id,
                username = user.username,
                nome = user.nome,
                email = user.email,
                phone = user.phone,
                cod_assessor = user.cod_assessor,
                role = user.role,
                escritorio = user.escritorio,
                profile_image_base64 = user.profile_image_data != null
                    ? Convert.ToBase64String(user.profile_image_data) : null
            };
        }
    }

    public class ErrorResponseDto { public string Message { get; set; } = string.Empty; }

    /// <summary>
    /// Modelo para criação de novos Usuários.
    /// </summary>
    public class RegisterRequestDto
    {
        [Required] public string username { get; set; } = string.Empty;
        [Required] public string nome { get; set; } = string.Empty;
        [Required] [EmailAddress] public string email { get; set; } = string.Empty;
        /// <summary>Senha provisória que será enviada por email.</summary>
        [Required] [MinLength(8)] public string password { get; set; } = string.Empty;
        public string? phone { get; set; }
        public string? cod_assessor { get; set; }
        /// <summary>Função: 'admin' ou 'user'.</summary>
        [Required] public string role { get; set; } = string.Empty;
        public string? escritorio { get; set; }
        public string? profile_image_base64 { get; set; }
    }

    public class UpdateProfileDto
    {
        [Required] public string nome { get; set; } = string.Empty;
        public string? phone { get; set; }
        public string? escritorio { get; set; }
        public string? profile_image_base64 { get; set; }
        public string? password { get; set; }
        public string? current_password { get; set; }
    }

    public class AdminUpdateUserDto
    {
        [Required] [StringLength(100)] public string username { get; set; } = string.Empty;
        [Required] [StringLength(255)] public string nome { get; set; } = string.Empty;
        [Required] [EmailAddress] [StringLength(255)] public string email { get; set; } = string.Empty;
        [StringLength(50)] public string? phone { get; set; }
        [StringLength(50)] public string? cod_assessor { get; set; }
        [Required] [StringLength(50)] public string role { get; set; } = string.Empty;
        [StringLength(100)] public string? escritorio { get; set; }
        public string? profile_image_base64 { get; set; }
    }

    public class ForgotPasswordDto
    {
        [Required] [EmailAddress] public string Email { get; set; } = string.Empty;
    }

    public class ResetPasswordDto
    {
        /// <summary>Código de 6 dígitos enviado por email.</summary>
        [Required] public string Token { get; set; } = string.Empty;
        [Required] [MinLength(8)] public string NewPassword { get; set; } = string.Empty;
    }

    public class ChangeInitialPasswordDto
    {
        [Required] [MinLength(8)] public string NewPassword { get; set; } = string.Empty;
    }
}