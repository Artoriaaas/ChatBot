using BusinessObject.Dtos;
using Microsoft.Extensions.Configuration;
using ServiceLayer.Interfaces;
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Net.Http;
using System.Text;
using System.Text.RegularExpressions;
using System.Threading.Tasks;
using System.Xml.Linq;

namespace ServiceLayer.Implements
{
    public class GrobidService : IGrobidService
    {
        private readonly HttpClient _httpClient;
        private readonly string _baseUrl;

        public GrobidService(HttpClient httpClient, IConfiguration configuration)
        {
            _httpClient = httpClient;
            var configuredUrl = configuration["GROBID_URL"] 
                ?? configuration["Grobid:Url"] 
                ?? Environment.GetEnvironmentVariable("GROBID_URL") 
                ?? "http://localhost:8070";

            _baseUrl = configuredUrl.TrimEnd('/');
            _httpClient.Timeout = TimeSpan.FromSeconds(60);
        }

        public string GetGrobidBaseUrl() => _baseUrl;

        public async Task<bool> IsAliveAsync()
        {
            try
            {
                using var cts = new System.Threading.CancellationTokenSource(TimeSpan.FromSeconds(3));
                var response = await _httpClient.GetAsync($"{_baseUrl}/api/isalive", cts.Token);
                return response.IsSuccessStatusCode;
            }
            catch
            {
                return false;
            }
        }

        public async Task<string> ProcessPdfAsync(Stream pdfStream)
        {
            var result = await ProcessPdfFullAsync(pdfStream);
            return result.FullText ?? string.Empty;
        }

        public async Task<ExtractedDocumentResult> ProcessPdfFullAsync(Stream pdfStream)
        {
            var result = new ExtractedDocumentResult
            {
                ExtractionEngine = "GROBID"
            };

            try
            {
                Console.WriteLine($"[GROBID] 🚀 Đang gửi file PDF tới dịch vụ GROBID tại {_baseUrl}...");

                using var request = new MultipartFormDataContent();
                
                // Copy stream to memory to prevent stream position issues
                using var memoryStream = new MemoryStream();
                await pdfStream.CopyToAsync(memoryStream);
                memoryStream.Position = 0;

                var fileContent = new ByteArrayContent(memoryStream.ToArray());
                fileContent.Headers.ContentType = new System.Net.Http.Headers.MediaTypeHeaderValue("application/pdf");
                request.Add(fileContent, "input", "document.pdf");
                
                request.Add(new StringContent("0"), "consolidateHeader");
                request.Add(new StringContent("0"), "consolidateCitations");
                request.Add(new StringContent("1"), "includeRawCitations");
                request.Add(new StringContent("1"), "segmentSentences");

                var stopwatch = System.Diagnostics.Stopwatch.StartNew();
                var response = await _httpClient.PostAsync($"{_baseUrl}/api/processFulltextDocument", request);
                stopwatch.Stop();

                if (!response.IsSuccessStatusCode)
                {
                    var errorDetails = await response.Content.ReadAsStringAsync();
                    throw new HttpRequestException($"GROBID trả về mã lỗi {response.StatusCode}: {errorDetails}");
                }

                var xmlContent = await response.Content.ReadAsStringAsync();
                result = ParseTeiXmlFull(xmlContent);
                result.Success = true;

                Console.WriteLine($"[GROBID] ✅ Phân tích GROBID thành công trong {stopwatch.ElapsedMilliseconds}ms! Tiêu đề: \"{result.Title}\", Số phần: {result.Sections.Count}");
                return result;
            }
            catch (Exception ex)
            {
                Console.WriteLine($"[GROBID] ⚠️ Gọi GROBID thất bại ({ex.Message}). Sẽ fallback.");
                result.Success = false;
                result.ErrorMessage = ex.Message;
                return result;
            }
        }

        private ExtractedDocumentResult ParseTeiXmlFull(string xml)
        {
            var result = new ExtractedDocumentResult
            {
                ExtractionEngine = "GROBID"
            };

            try
            {
                var doc = XDocument.Parse(xml);
                var ns = doc.Root?.GetDefaultNamespace() ?? XNamespace.None;
                
                // 1. Trích xuất Tiêu đề (Title)
                var titleNode = doc.Descendants(ns + "titleStmt")
                    .Elements(ns + "title")
                    .FirstOrDefault(t => (string?)t.Attribute("type") == "main")
                    ?? doc.Descendants(ns + "titleStmt").Elements(ns + "title").FirstOrDefault();

                if (titleNode != null && !string.IsNullOrWhiteSpace(titleNode.Value))
                {
                    result.Title = CleanWhitespace(titleNode.Value);
                }

                // 2. Trích xuất Tác giả (Authors)
                var authorNames = new List<string>();
                var authorNodes = doc.Descendants(ns + "sourceDesc").Descendants(ns + "author");
                foreach (var author in authorNodes)
                {
                    var persName = author.Element(ns + "persName");
                    if (persName != null)
                    {
                        var forenames = persName.Elements(ns + "forename").Select(f => f.Value.Trim());
                        var surname = persName.Element(ns + "surname")?.Value.Trim();
                        var fullName = string.Join(" ", forenames.Concat(string.IsNullOrEmpty(surname) ? Array.Empty<string>() : new[] { surname })).Trim();
                        if (!string.IsNullOrWhiteSpace(fullName) && !authorNames.Contains(fullName))
                        {
                            authorNames.Add(fullName);
                        }
                    }
                }
                if (authorNames.Any())
                {
                    result.Authors = string.Join(", ", authorNames);
                }

                // 3. Trích xuất Năm xuất bản (Year)
                var dateNode = doc.Descendants(ns + "publicationStmt").Descendants(ns + "date").FirstOrDefault();
                if (dateNode != null)
                {
                    var whenAttr = (string?)dateNode.Attribute("when");
                    if (!string.IsNullOrEmpty(whenAttr) && Regex.Match(whenAttr, @"\b(19\d{2}|20\d{2})\b") is { Success: true } match)
                    {
                        if (int.TryParse(match.Value, out int year)) result.Year = year;
                    }
                    else if (Regex.Match(dateNode.Value, @"\b(19\d{2}|20\d{2})\b") is { Success: true } textMatch)
                    {
                        if (int.TryParse(textMatch.Value, out int year)) result.Year = year;
                    }
                }

                // 4. Trích xuất Tóm tắt (Abstract)
                var abstractNode = doc.Descendants(ns + "profileDesc").Descendants(ns + "abstract").FirstOrDefault()
                    ?? doc.Descendants(ns + "abstract").FirstOrDefault();

                var abstractBuilder = new StringBuilder();
                if (abstractNode != null)
                {
                    foreach (var p in abstractNode.Descendants(ns + "p"))
                    {
                        var text = ExtractFormattedText(p);
                        if (!string.IsNullOrWhiteSpace(text))
                        {
                            abstractBuilder.AppendLine(text);
                            abstractBuilder.AppendLine();
                        }
                    }
                }
                result.AbstractText = abstractBuilder.ToString().Trim();

                // 5. Trích xuất các Mục (Sections)
                var sections = new List<DocumentSectionDto>();
                int sectionOrder = 0;

                // Nếu có abstract, thêm thành mục đầu tiên
                if (!string.IsNullOrWhiteSpace(result.AbstractText))
                {
                    sections.Add(new DocumentSectionDto
                    {
                        SectionOrder = sectionOrder++,
                        Title = "Abstract",
                        Content = result.AbstractText
                    });
                }

                // Trích xuất body divs
                var bodyNode = doc.Descendants(ns + "body").FirstOrDefault();
                if (bodyNode != null)
                {
                    var divs = bodyNode.Elements(ns + "div").ToList();
                    // Nếu body không chia thành div cấp 1, tìm tất cả div con
                    if (!divs.Any())
                    {
                        divs = bodyNode.Descendants(ns + "div").ToList();
                    }

                    foreach (var div in divs)
                    {
                        var head = div.Element(ns + "head")?.Value;
                        var sectionTitle = !string.IsNullOrWhiteSpace(head) ? CleanWhitespace(head) : $"Mục {sectionOrder + 1}";

                        var pBuilder = new StringBuilder();
                        foreach (var p in div.Elements(ns + "p"))
                        {
                            var pText = ExtractFormattedText(p);
                            if (!string.IsNullOrWhiteSpace(pText))
                            {
                                pBuilder.AppendLine(pText);
                                pBuilder.AppendLine();
                            }
                        }

                        // Kiểm tra nếu có div con lồng vào
                        foreach (var subDiv in div.Elements(ns + "div"))
                        {
                            var subHead = subDiv.Element(ns + "head")?.Value;
                            if (!string.IsNullOrWhiteSpace(subHead))
                            {
                                pBuilder.AppendLine($"### {CleanWhitespace(subHead)}");
                                pBuilder.AppendLine();
                            }
                            foreach (var subP in subDiv.Elements(ns + "p"))
                            {
                                var subPText = ExtractFormattedText(subP);
                                if (!string.IsNullOrWhiteSpace(subPText))
                                {
                                    pBuilder.AppendLine(subPText);
                                    pBuilder.AppendLine();
                                }
                            }
                        }

                        var content = pBuilder.ToString().Trim();
                        if (!string.IsNullOrWhiteSpace(content))
                        {
                            sections.Add(new DocumentSectionDto
                            {
                                SectionOrder = sectionOrder++,
                                Title = sectionTitle,
                                Content = content
                            });
                        }
                    }
                }

                result.Sections = sections;

                // 6. Xây dựng FullText định dạng chuẩn (Markdown / ngắt đoạn rõ ràng)
                var fullTextBuilder = new StringBuilder();
                if (!string.IsNullOrWhiteSpace(result.Title))
                {
                    fullTextBuilder.AppendLine($"# {result.Title}\n");
                }
                if (!string.IsNullOrWhiteSpace(result.Authors))
                {
                    fullTextBuilder.AppendLine($"**Tác giả**: {result.Authors}\n");
                }

                foreach (var section in sections)
                {
                    fullTextBuilder.AppendLine($"## {section.Title}\n");
                    fullTextBuilder.AppendLine(section.Content);
                    fullTextBuilder.AppendLine();
                }

                result.FullText = fullTextBuilder.ToString().Trim();
                result.TotalPages = Math.Max(1, sections.Count);

                return result;
            }
            catch (Exception ex)
            {
                throw new Exception($"Lỗi khi bóc tách TEI XML từ GROBID: {ex.Message}");
            }
        }

        private static string CleanWhitespace(string input)
        {
            if (string.IsNullOrWhiteSpace(input)) return string.Empty;
            // Thay thế nhiều khoảng trắng liên tiếp bằng 1 khoảng trắng, giữ format từ
            return Regex.Replace(input.Trim(), @"[ \t]+", " ");
        }

        private static string ExtractFormattedText(XElement element)
        {
            if (element == null) return string.Empty;
            
            var sb = new StringBuilder();
            foreach (var node in element.Nodes())
            {
                if (node is XText textNode)
                {
                    sb.Append(textNode.Value);
                }
                else if (node is XElement el)
                {
                    var localName = el.Name.LocalName;
                    if (localName == "hi")
                    {
                        var rend = (string?)el.Attribute("rend");
                        var innerText = ExtractFormattedText(el);
                        if (string.IsNullOrWhiteSpace(innerText)) continue;

                        if (rend == "bold") sb.Append($"**{innerText.Trim()}**");
                        else if (rend == "italic") sb.Append($"*{innerText.Trim()}*");
                        else sb.Append(innerText);
                    }
                    else if (localName == "formula")
                    {
                        var innerText = ExtractFormattedText(el).Trim();
                        if (!string.IsNullOrWhiteSpace(innerText))
                        {
                            // Wrap formula in $ for inline math
                            sb.Append($" ${innerText}$ ");
                        }
                    }
                    else if (localName == "ref")
                    {
                        var type = (string?)el.Attribute("type");
                        var innerText = ExtractFormattedText(el);
                        // For citations and references, just keep the text
                        sb.Append(innerText);
                    }
                    else
                    {
                        // Fallback for other elements like <label>, <note>
                        sb.Append(ExtractFormattedText(el));
                    }
                }
            }
            return CleanWhitespace(sb.ToString());
        }
    }
}
