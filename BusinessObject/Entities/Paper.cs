using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace BusinessObject.Entities
{
    public class Paper
    {
        [Key]
        public int Id { get; set; }

        [Required(ErrorMessage = "Tiêu đề không được để trống.")]
        [StringLength(255)]
        public string Title { get; set; } = string.Empty;

        public string Authors { get; set; } = string.Empty;

        public int Year { get; set; } = DateTime.UtcNow.Year;

        public string? AbstractText { get; set; }

        public string? Collection { get; set; } = "General";

        public string? Tags { get; set; } = string.Empty;

        public bool IsFavorite { get; set; } = false;

        public string? PdfUrl { get; set; }

        public string? FilePath { get; set; }

        public long FileSize { get; set; }

        public int TotalPages { get; set; } = 1;

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        [StringLength(50)]
        public string IndexStatus { get; set; } = "Pending"; // Pending, Processing, Completed, Failed

        public string? ErrorMessage { get; set; }

        public int? DocumentId { get; set; }

        [ForeignKey("DocumentId")]
        public virtual Document? Document { get; set; }
    }
}
