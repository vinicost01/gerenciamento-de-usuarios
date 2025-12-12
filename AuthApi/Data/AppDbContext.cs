using AuthApi.Models;
using Microsoft.EntityFrameworkCore;

namespace AuthApi.Data
{
    public class AppDbContext : DbContext
    {
        public AppDbContext(DbContextOptions<AppDbContext> options) : base(options) { }

        public DbSet<User> Users { get; set; }

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            modelBuilder.Entity<User>(entity =>
            {
                entity.ToTable("users");
                entity.HasIndex(u => u.username).IsUnique();
                entity.HasIndex(u => u.email).IsUnique();
                entity.Property(e => e.Id).HasColumnName("id");
                entity.Property(e => e.username).HasColumnName("username");
                entity.Property(e => e.nome).HasColumnName("nome");
                entity.Property(e => e.email).HasColumnName("email");
                entity.Property(e => e.phone).HasColumnName("phone");
                entity.Property(e => e.cod_assessor).HasColumnName("cod_assessor");
                entity.Property(e => e.role).HasColumnName("role");
                entity.Property(e => e.escritorio).HasColumnName("escritorio");
                entity.Property(e => e.password_hash).HasColumnName("password_hash");
                entity.Property(e => e.profile_image_data).HasColumnName("profile_image_data");
                entity.Property(e => e.password_reset_token).HasColumnName("password_reset_token");
                entity.Property(e => e.password_reset_expiry).HasColumnName("password_reset_expiry");
                entity.Property(e => e.must_change_password).HasColumnName("must_change_password");
            });
        }
    }
}