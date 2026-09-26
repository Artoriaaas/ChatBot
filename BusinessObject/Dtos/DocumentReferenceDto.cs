namespace BusinessObject.Dtos
{
    public class DocumentReferenceDto
    {
        public string RefKey { get; set; } = string.Empty; // e.g., b0
        public string Label { get; set; } = string.Empty; // citation number shown to user
        public string? Title { get; set; }
        public string? Authors { get; set; }
        public int? Year { get; set; }
        public string? Venue { get; set; }
        public string? Doi { get; set; }
        public string? Url { get; set; }
        public string? RawCitationText { get; set; }
    }
}
