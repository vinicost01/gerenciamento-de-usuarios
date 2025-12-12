using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace AuthApi.Models
{
    public class User
    {
        [Key]
        [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
        public int Id { get; set; }

        [Required] [StringLength(100)] public string username { get; set; } = string.Empty;
        [Required] [StringLength(255)] public string nome { get; set; } = string.Empty;
        [Required] [StringLength(255)] [EmailAddress] public string email { get; set; } = string.Empty;
        [StringLength(50)] public string? phone { get; set; }
        [StringLength(50)] public string? cod_assessor { get; set; }
        [Required] [StringLength(50)] public string role { get; set; } = string.Empty;
        [StringLength(100)] public string? escritorio { get; set; }
        [Required] [StringLength(255)] public string password_hash { get; set; } = string.Empty;
        public byte[]? profile_image_data { get; set; }
        public string? password_reset_token { get; set; }
        public DateTime? password_reset_expiry { get; set; }
        public bool must_change_password { get; set; } = false;
    }
}