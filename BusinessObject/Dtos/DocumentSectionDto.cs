using System.Collections.Generic;

namespace BusinessObject.Dtos
{
    public class DocumentSectionDto
    {
        public int SectionOrder { get; set; }
        public string Title { get; set; } = string.Empty;
        public string Content { get; set; } = string.Empty;
    }

    public class ExtractedDocumentResult
    {
        public bool Success { get; set; }
        public string? FullText { get; set; }
        public string? Title { get; set; }
        public string? Authors { get; set; }
        public string? AbstractText { get; set; }
        public int? Year { get; set; }
        public int TotalPages { get; set; } = 1;
        public List<DocumentSectionDto> Sections { get; set; } = new();
        public string? ErrorMessage { get; set; }
        public string ExtractionEngine { get; set; } = "Unknown";
    }
}
