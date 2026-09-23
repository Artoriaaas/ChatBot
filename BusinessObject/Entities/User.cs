using System;
using System.ComponentModel.DataAnnotations;
using BusinessObject.Enums;

namespace BusinessObject.Entities
{
    public class User
    {
        [Key]
        public Guid Id { get; set; }

        [Required]
        [MaxLength(255)]
        public string Email { get; set; } = string.Empty;

        public string? PasswordHash { get; set; }

        [MaxLength(255)]
        public string? FullName { get; set; }

        public Role Role { get; set; } = Role.Student;

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    }
}
