using ServiceLayer.Interfaces;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Text.RegularExpressions;

namespace ServiceLayer.Implements
{
    public class ChunkingService : IChunkingService
    {
        public List<string> ChunkText(string text, int chunkSize, int overlapSize)
        {
            if (string.IsNullOrWhiteSpace(text))
                return new List<string>();

            // chunkSize được tính theo số từ (words) hoặc xấp xỉ ký tự
            int maxWords = Math.Max(50, chunkSize);
            int overlapWords = Math.Min(overlapSize, maxWords / 3);

            // 1. Tách văn bản thành các khối đoạn văn (paragraphs) dựa trên 2 dấu xuống dòng trở lên
            var paragraphs = Regex.Split(text.Trim(), @"(?:\r?\n\s*){2,}")
                .Where(p => !string.IsNullOrWhiteSpace(p))
                .Select(p => p.Trim())
                .ToList();

            if (paragraphs.Count == 0)
                return new List<string>();

            var chunks = new List<string>();
            var currentChunkParas = new List<string>();
            int currentWordCount = 0;

            foreach (var para in paragraphs)
            {
                var paraWords = CountWords(para);

                // Nếu riêng đoạn văn này đã dài hơn maxWords -> Tách đoạn này theo câu
                if (paraWords > maxWords)
                {
                    // Nếu đang có đoạn văn gom dở thì hoàn tất chunk trước
                    if (currentChunkParas.Any())
                    {
                        chunks.Add(string.Join("\n\n", currentChunkParas));
                        currentChunkParas.Clear();
                        currentWordCount = 0;
                    }

                    // Chia nhỏ đoạn văn dài theo câu
                    var sentenceChunks = ChunkLongParagraph(para, maxWords, overlapWords);
                    chunks.AddRange(sentenceChunks);
                    continue;
                }

                // Nếu thêm đoạn văn này vào vượt quá maxWords
                if (currentWordCount + paraWords > maxWords && currentChunkParas.Any())
                {
                    chunks.Add(string.Join("\n\n", currentChunkParas));

                    // Tạo overlap: giữ lại đoạn văn cuối nếu kích thước phù hợp
                    var lastPara = currentChunkParas.Last();
                    currentChunkParas.Clear();

                    if (CountWords(lastPara) <= overlapWords)
                    {
                        currentChunkParas.Add(lastPara);
                        currentWordCount = CountWords(lastPara);
                    }
                    else
                    {
                        currentWordCount = 0;
                    }
                }

                currentChunkParas.Add(para);
                currentWordCount += paraWords;
            }

            if (currentChunkParas.Any())
            {
                chunks.Add(string.Join("\n\n", currentChunkParas));
            }

            return chunks;
        }

        private static List<string> ChunkLongParagraph(string paragraph, int maxWords, int overlapWords)
        {
            var sentences = Regex.Split(paragraph, @"(?<=[.?!])\s+(?=[A-Z0-9\p{Lu}])")
                .Where(s => !string.IsNullOrWhiteSpace(s))
                .Select(s => s.Trim())
                .ToList();

            if (sentences.Count <= 1)
            {
                // Nếu không tách được theo câu, tách theo từ giữ nguyên khoảng trắng
                return ChunkByWords(paragraph, maxWords, overlapWords);
            }

            var chunks = new List<string>();
            var currentSentences = new List<string>();
            int currentCount = 0;

            foreach (var sentence in sentences)
            {
                int sentenceWords = CountWords(sentence);
                if (currentCount + sentenceWords > maxWords && currentSentences.Any())
                {
                    chunks.Add(string.Join(" ", currentSentences));
                    currentSentences.Clear();
                    currentCount = 0;
                }

                currentSentences.Add(sentence);
                currentCount += sentenceWords;
            }

            if (currentSentences.Any())
            {
                chunks.Add(string.Join(" ", currentSentences));
            }

            return chunks;
        }

        private static List<string> ChunkByWords(string text, int maxWords, int overlapWords)
        {
            var words = text.Split(new[] { ' ' }, StringSplitOptions.RemoveEmptyEntries);
            var chunks = new List<string>();
            int step = Math.Max(1, maxWords - overlapWords);

            for (int i = 0; i < words.Length; i += step)
            {
                int count = Math.Min(maxWords, words.Length - i);
                chunks.Add(string.Join(" ", words.Skip(i).Take(count)));
                if (i + count >= words.Length) break;
            }

            return chunks;
        }

        private static int CountWords(string text)
        {
            if (string.IsNullOrWhiteSpace(text)) return 0;
            return text.Split(new[] { ' ', '\r', '\n', '\t' }, StringSplitOptions.RemoveEmptyEntries).Length;
        }
    }
}