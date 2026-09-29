namespace BusinessObject.Dtos
{
    public class RagChunkDto
    {
        public int SourceIndex { get; set; } // 1-based index corresponding to [1], [2] in LLM answer
        public int Id { get; set; }
        public int DocumentId { get; set; }
        public int ChunkOrder { get; set; }
        public string Content { get; set; } = string.Empty;
        public string? FileName { get; set; }
    }
}
