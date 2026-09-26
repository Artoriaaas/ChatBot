using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace BusinessObject.Entities
{
    public class DocumentReference
    {
        [Key]
        public int Id { get; set; }

        // Foreign key to Document
        public int DocumentId { get; set; }
        public Document? Document { get; set; }

        // Reference key from TEI (e.g., b0, b1)
        [Required]
        public string RefKey { get; set; } = string.Empty;

        // Human readable label used in citations (1, 2, …)
        [Required]
        public string Label { get; set; } = string.Empty;

        public string? Title { get; set; }
        public string? Authors { get; set; }
        public int? Year { get; set; }
        public string? Venue { get; set; }
        public string? Doi { get; set; }
        public string? Url { get; set; }
        public string? RawCitationText { get; set; }
    }
}
