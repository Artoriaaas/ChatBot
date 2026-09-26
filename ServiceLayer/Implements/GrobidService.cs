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
                var teiHeader = doc.Descendants(ns + "teiHeader").FirstOrDefault();
                var headerContainer = (XContainer?)teiHeader ?? (XContainer?)doc.Root ?? doc;
                
                // 1. Trích xuất Tiêu đề (Title)
                var titleNode = headerContainer.Descendants(ns + "titleStmt")
                    .Elements(ns + "title")
                    .FirstOrDefault(t => (string?)t.Attribute("type") == "main")
                    ?? headerContainer.Descendants(ns + "titleStmt").Elements(ns + "title").FirstOrDefault();

                if (titleNode != null && !string.IsNullOrWhiteSpace(titleNode.Value))
                {
                    result.Title = CleanWhitespace(titleNode.Value);
                }

                // 2. Trích xuất Tác giả (Authors)
                var authorNames = new List<string>();
                var authorNodes = headerContainer.Descendants(ns + "sourceDesc").Descendants(ns + "author");
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
                var dateNode = headerContainer.Descendants(ns + "publicationStmt").Descendants(ns + "date").FirstOrDefault();
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
                var abstractNode = headerContainer.Descendants(ns + "profileDesc").Descendants(ns + "abstract").FirstOrDefault()
                    ?? headerContainer.Descendants(ns + "abstract").FirstOrDefault();

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

                // 4.1 Trích xuất Tạp chí / Hội nghị & Thông tin xuất bản (Journal / Monograph)
                // CHỈ tìm trong teiHeader -> sourceDesc để không lấy nhầm tạp chí của References ở mục Back
                var monogrNode = headerContainer.Descendants(ns + "sourceDesc").Descendants(ns + "monogr").FirstOrDefault();

                if (monogrNode != null)
                {
                    var journalTitle = monogrNode.Elements(ns + "title")
                        .FirstOrDefault(t => (string?)t.Attribute("level") == "j" || (string?)t.Attribute("level") == "m")?.Value
                        ?? monogrNode.Elements(ns + "title").FirstOrDefault()?.Value;

                    if (!string.IsNullOrWhiteSpace(journalTitle))
                    {
                        result.Journal = CleanWhitespace(journalTitle);
                    }

                    var publisherNode = monogrNode.Descendants(ns + "publisher").FirstOrDefault()
                        ?? headerContainer.Descendants(ns + "publicationStmt").Descendants(ns + "publisher").FirstOrDefault();
                    if (!string.IsNullOrWhiteSpace(publisherNode?.Value))
                    {
                        result.Publisher = CleanWhitespace(publisherNode.Value);
                    }

                    var volumeScope = monogrNode.Descendants(ns + "biblScope")
                        .FirstOrDefault(b => (string?)b.Attribute("unit") == "volume");
                    if (!string.IsNullOrWhiteSpace(volumeScope?.Value))
                    {
                        result.Volume = volumeScope.Value.Trim();
                    }

                    var issueScope = monogrNode.Descendants(ns + "biblScope")
                        .FirstOrDefault(b => (string?)b.Attribute("unit") == "issue");
                    if (!string.IsNullOrWhiteSpace(issueScope?.Value))
                    {
                        result.Issue = issueScope.Value.Trim();
                    }

                    var pageScope = monogrNode.Descendants(ns + "biblScope")
                        .FirstOrDefault(b => (string?)b.Attribute("unit") == "page");
                    if (pageScope != null)
                    {
                        var from = (string?)pageScope.Attribute("from");
                        var to = (string?)pageScope.Attribute("to");
                        if (!string.IsNullOrWhiteSpace(from) && !string.IsNullOrWhiteSpace(to))
                        {
                            result.Pages = $"{from.Trim()}–{to.Trim()}";
                        }
                        else if (!string.IsNullOrWhiteSpace(pageScope.Value))
                        {
                            result.Pages = pageScope.Value.Trim();
                        }
                    }

                    // Fallback tìm năm trong imprint date nếu chưa tìm thấy
                    if (!result.Year.HasValue)
                    {
                        var imprintDate = monogrNode.Descendants(ns + "date").FirstOrDefault();
                        if (imprintDate != null)
                        {
                            var whenAttr = (string?)imprintDate.Attribute("when");
                            if (!string.IsNullOrEmpty(whenAttr) && Regex.Match(whenAttr, @"\b(19\d{2}|20\d{2})\b") is { Success: true } m)
                            {
                                if (int.TryParse(m.Value, out int yr)) result.Year = yr;
                            }
                            else if (Regex.Match(imprintDate.Value, @"\b(19\d{2}|20\d{2})\b") is { Success: true } tm)
                            {
                                if (int.TryParse(tm.Value, out int yr)) result.Year = yr;
                            }
                        }
                    }
                }

                // 4.2 Trích xuất DOI (CHỈ tìm trong teiHeader để tránh lấy nhầm DOI của phần References/Bibliography)
                var doiNode = teiHeader?.Descendants(ns + "idno")
                    .FirstOrDefault(n => string.Equals((string?)n.Attribute("type"), "DOI", StringComparison.OrdinalIgnoreCase));
                if (!string.IsNullOrWhiteSpace(doiNode?.Value))
                {
                    result.Doi = CleanWhitespace(doiNode.Value);
                }
                else
                {
                    // Fallback cho bài báo preprint arXiv (ví dụ: cdm.dvi / astro-ph/9508025)
                    // DOI Foundation & DataCite phân bổ tiền tố chính thức 10.48550/arXiv.{id} chuyển hướng trực tiếp tới trang arXiv
                    var arxivNode = teiHeader?.Descendants(ns + "idno")
                        .FirstOrDefault(n => string.Equals((string?)n.Attribute("type"), "arXiv", StringComparison.OrdinalIgnoreCase));

                    string? arxivVal = arxivNode?.Value;
                    if (string.IsNullOrWhiteSpace(arxivVal) && teiHeader != null)
                    {
                        var match = Regex.Match(teiHeader.ToString(), @"\barXiv:\s*([a-z\-]+/\d{7}|\d{4}\.\d{4,5}(v\d+)?)\b", RegexOptions.IgnoreCase);
                        if (match.Success)
                        {
                            arxivVal = match.Groups[1].Value;
                        }
                    }

                    if (!string.IsNullOrWhiteSpace(arxivVal))
                    {
                        arxivVal = CleanWhitespace(arxivVal);
                        // Trích xuất chính xác mã định danh arXiv chuẩn: \d{4}\.\d{4,5} (chuẩn mới từ 2007) hoặc [a-z\-]+/\d{7} (chuẩn cũ)
                        // Bỏ qua các tag phân loại như [math.AC] và version v1, v2 vì DOI DataCite của arXiv chỉ đăng ký mã gốc
                        var idMatch = Regex.Match(arxivVal, @"([a-z\-]+/\d{7}|\d{4}\.\d{4,5})", RegexOptions.IgnoreCase);
                        if (idMatch.Success)
                        {
                            var canonicalArxiv = idMatch.Groups[1].Value;
                            result.Doi = $"10.48550/arXiv.{canonicalArxiv}";
                        }
                    }
                }

                // 4.3 Trích xuất Từ khóa (Keywords)
                var keywordNodes = headerContainer.Descendants(ns + "keywords").Descendants(ns + "term");
                var keywordList = new List<string>();
                foreach (var kw in keywordNodes)
                {
                    var text = CleanWhitespace(kw.Value);
                    if (!string.IsNullOrWhiteSpace(text) && !keywordList.Contains(text, StringComparer.OrdinalIgnoreCase))
                    {
                        keywordList.Add(text);
                    }
                }
                if (keywordList.Any())
                {
                    result.Keywords = string.Join(", ", keywordList);
                }

                // 5. Trích xuất các Mục (Sections)
                // 5. Trích xuất các Mục (Sections) với Gom nhóm phân cấp (Hierarchical Grouping - Cách 1)
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
                    var rawDivs = new List<RawDivInfo>();
                    var topDivs = bodyNode.Elements(ns + "div").ToList();
                    if (!topDivs.Any())
                    {
                        topDivs = bodyNode.Descendants(ns + "div").ToList();
                    }

                    foreach (var div in topDivs)
                    {
                        var headNode = div.Element(ns + "head");
                        var nAttr = (string?)headNode?.Attribute("n");
                        var headText = headNode != null ? CleanWhitespace(headNode.Value) : string.Empty;
                        var fullTitle = BuildFullSectionTitle(nAttr, headText);
                        var (isMajor, majorPrefix) = DetermineSectionHierarchy(nAttr, fullTitle);
                        var content = ExtractDivContent(div, ns);

                        rawDivs.Add(new RawDivInfo
                        {
                            RawHead = headText,
                            NAttr = nAttr,
                            FullTitle = fullTitle,
                            IsMajorSection = isMajor,
                            MajorPrefix = majorPrefix,
                            Content = content
                        });

                        // Xử lý các div con lồng vào (nếu có)
                        foreach (var subDiv in div.Elements(ns + "div"))
                        {
                            var subHead = subDiv.Element(ns + "head");
                            var subN = (string?)subHead?.Attribute("n");
                            var subText = subHead != null ? CleanWhitespace(subHead.Value) : string.Empty;
                            var subFullTitle = BuildFullSectionTitle(subN, subText);
                            var (subIsMajor, subMajorPrefix) = DetermineSectionHierarchy(subN, subFullTitle);
                            if (string.IsNullOrEmpty(subMajorPrefix))
                            {
                                subMajorPrefix = majorPrefix;
                            }
                            var subContent = ExtractDivContent(subDiv, ns);

                            rawDivs.Add(new RawDivInfo
                            {
                                RawHead = subText,
                                NAttr = subN,
                                FullTitle = subFullTitle,
                                IsMajorSection = false,
                                MajorPrefix = subMajorPrefix,
                                Content = subContent
                            });
                        }
                    }

                    // 5.1 Xử lý các đối tượng figure và table nằm trực tiếp dưới body
                    var figuresMap = new Dictionary<string, (string id, string markdown, bool used)>();

                    foreach (var fig in bodyNode.Elements(ns + "figure"))
                    {
                        var id = (string?)fig.Attribute(XNamespace.Xml + "id") ?? (string?)fig.Attribute("id") ?? string.Empty;
                        var isTable = (string?)fig.Attribute("type") == "table" || fig.Element(ns + "table") != null;
                        var descNode = fig.Element(ns + "figDesc");
                        var rawDesc = descNode != null ? CleanWhitespace(descNode.Value) : string.Empty;

                        // Kiểm tra nếu figure này thực chất chứa một tiểu mục bị GROBID gộp nhầm (ví dụ: 3.2 Feature Selection)
                        var secMatch = Regex.Match(rawDesc, @"(?<pre>.*?)(?<secnum>\b\d+\.\d+)\.?\s+(?<sectitle>(?:[A-Z][a-z]+\s*){1,4})(?<post>[A-Z][a-z].*)", RegexOptions.Singleline);
                        if (secMatch.Success && !isTable)
                        {
                            var pre = secMatch.Groups["pre"].Value.Trim();
                            var secNum = secMatch.Groups["secnum"].Value.Trim();
                            var secTitle = secMatch.Groups["sectitle"].Value.Trim();
                            var post = secMatch.Groups["post"].Value.Trim();

                            // Bổ sung phần dẫn nhập và sơ đồ (pre) vào tiểu mục trước đó (ví dụ 3.1)
                            var parentPrefix = secNum.Split('.')[0];
                            var prevDiv = rawDivs.LastOrDefault(d => !d.IsMajorSection && d.MajorPrefix == parentPrefix);
                            if (prevDiv != null && !string.IsNullOrWhiteSpace(pre))
                            {
                                prevDiv.Content = (prevDiv.Content + "\n\n" + pre).Trim();
                            }

                            // Định dạng nội dung tiểu mục được khôi phục (post)
                            var formattedPost = FormatEmbeddedSubsectionText(post);
                            var fullSubTitle = $"{secNum} {secTitle}".Trim();
                            var (isMaj, majPref) = DetermineSectionHierarchy(secNum, fullSubTitle);

                            int insertIdx = prevDiv != null ? rawDivs.IndexOf(prevDiv) + 1 : rawDivs.Count;
                            rawDivs.Insert(insertIdx, new RawDivInfo
                            {
                                RawHead = secTitle,
                                NAttr = secNum,
                                FullTitle = fullSubTitle,
                                IsMajorSection = isMaj,
                                MajorPrefix = majPref,
                                Content = formattedPost
                            });
                        }
                        else
                        {
                            var md = FormatTeiFigure(fig, ns);
                            if (!string.IsNullOrWhiteSpace(md))
                            {
                                if (!string.IsNullOrEmpty(id)) figuresMap[id] = (id, md, false);
                                var head = fig.Element(ns + "head")?.Value;
                                if (!string.IsNullOrEmpty(head)) figuresMap[CleanWhitespace(head)] = (id, md, false);
                            }
                        }
                    }

                    // 5.2 Gắn bảng (table) và hình (figure) vào đúng section tương ứng (tránh trùng lặp)
                    var usedFigureIds = new HashSet<string>();
                    foreach (var div in rawDivs)
                    {
                        foreach (var kvp in figuresMap.ToList())
                        {
                            if (usedFigureIds.Contains(kvp.Value.id)) continue;
                            bool isReferenced = (!string.IsNullOrEmpty(kvp.Key) && div.Content.Contains(kvp.Key)) ||
                                                (kvp.Key.StartsWith("Table", StringComparison.OrdinalIgnoreCase) && (div.Content.Contains("Table 1") || div.Content.Contains("table 1"))) ||
                                                (kvp.Key.StartsWith("Figure", StringComparison.OrdinalIgnoreCase) && (div.Content.Contains("Figure 1") || div.Content.Contains("figure 1")));

                            if (isReferenced && !div.Content.Contains(kvp.Value.markdown))
                            {
                                div.Content = (div.Content + "\n\n" + kvp.Value.markdown).Trim();
                                usedFigureIds.Add(kvp.Value.id);
                            }
                        }
                    }

                    // Gắn các figure/table còn lại chưa được reference vào section tương thích gần nhất
                    foreach (var kvp in figuresMap.Values.Where(v => !usedFigureIds.Contains(v.id)).DistinctBy(v => v.id))
                    {
                        var targetDiv = rawDivs.LastOrDefault(d => d.MajorPrefix == "4") ?? rawDivs.LastOrDefault();
                        if (targetDiv != null && !targetDiv.Content.Contains(kvp.markdown))
                        {
                            targetDiv.Content = (targetDiv.Content + "\n\n" + kvp.markdown).Trim();
                            usedFigureIds.Add(kvp.id);
                        }
                    }

                    DocumentSectionDto? currentMajorSection = null;
                    string currentMajorPrefix = string.Empty;

                    foreach (var divInfo in rawDivs)
                    {
                        if (string.IsNullOrWhiteSpace(divInfo.FullTitle) && string.IsNullOrWhiteSpace(divInfo.Content))
                        {
                            continue;
                        }

                        var title = !string.IsNullOrWhiteSpace(divInfo.FullTitle)
                            ? divInfo.FullTitle
                            : $"Mục {sectionOrder + 1}";

                        if (divInfo.IsMajorSection)
                        {
                            currentMajorSection = new DocumentSectionDto
                            {
                                SectionOrder = sectionOrder++,
                                Title = title,
                                Content = divInfo.Content
                            };
                            currentMajorPrefix = !string.IsNullOrEmpty(divInfo.MajorPrefix)
                                ? divInfo.MajorPrefix
                                : ExtractLeadingNumber(title);

                            sections.Add(currentMajorSection);
                        }
                        else
                        {
                            // Đây là tiểu mục con (e.g. 3.1, 3.2)
                            bool canGroup = currentMajorSection != null &&
                                (!string.IsNullOrEmpty(divInfo.MajorPrefix) && !string.IsNullOrEmpty(currentMajorPrefix)
                                    ? divInfo.MajorPrefix == currentMajorPrefix
                                    : true);

                            if (canGroup && currentMajorSection != null)
                            {
                                var sb = new StringBuilder();
                                if (!string.IsNullOrWhiteSpace(currentMajorSection.Content))
                                {
                                    sb.AppendLine(currentMajorSection.Content);
                                    sb.AppendLine();
                                }
                                sb.AppendLine($"### {title}");
                                sb.AppendLine();
                                if (!string.IsNullOrWhiteSpace(divInfo.Content))
                                {
                                    sb.AppendLine(divInfo.Content);
                                }
                                currentMajorSection.Content = sb.ToString().Trim();
                            }
                            else
                            {
                                // Không có mục cha trước đó hoặc khác số hiệu -> tạo section độc lập
                                currentMajorSection = new DocumentSectionDto
                                {
                                    SectionOrder = sectionOrder++,
                                    Title = title,
                                    Content = divInfo.Content
                                };
                                currentMajorPrefix = divInfo.MajorPrefix;
                                sections.Add(currentMajorSection);
                            }
                        }
                    }

                    // Loại bỏ section rỗng và gán lại số thứ tự SectionOrder
                    sections = sections.Where(s => !string.IsNullOrWhiteSpace(s.Content) || !string.IsNullOrWhiteSpace(s.Title)).ToList();
                    for (int i = 0; i < sections.Count; i++)
                    {
                        sections[i].SectionOrder = i;
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

        private class RawDivInfo
        {
            public string RawHead { get; set; } = string.Empty;
            public string? NAttr { get; set; }
            public string FullTitle { get; set; } = string.Empty;
            public bool IsMajorSection { get; set; }
            public string MajorPrefix { get; set; } = string.Empty;
            public string Content { get; set; } = string.Empty;
        }

        private static string ExtractDivContent(XElement div, XNamespace ns)
        {
            var sb = new StringBuilder();
            foreach (var child in div.Elements())
            {
                var localName = child.Name.LocalName;
                if (localName == "head" || localName == "div")
                {
                    continue;
                }

                if (localName == "p" || localName == "ab")
                {
                    var pText = ExtractFormattedText(child);
                    if (!string.IsNullOrWhiteSpace(pText))
                    {
                        sb.AppendLine(pText);
                        sb.AppendLine();
                    }
                }
                else if (localName == "list")
                {
                    var listText = FormatTeiList(child, ns);
                    if (!string.IsNullOrWhiteSpace(listText))
                    {
                        sb.AppendLine(listText);
                        sb.AppendLine();
                    }
                }
                else if (localName == "formula")
                {
                    var formulaText = FormatTeiFormula(child, ns);
                    if (!string.IsNullOrWhiteSpace(formulaText))
                    {
                        sb.AppendLine(formulaText);
                        sb.AppendLine();
                    }
                }
                else if (localName == "figure")
                {
                    var figureText = FormatTeiFigure(child, ns);
                    if (!string.IsNullOrWhiteSpace(figureText))
                    {
                        sb.AppendLine(figureText);
                        sb.AppendLine();
                    }
                }
                else if (localName == "table")
                {
                    var tableText = FormatTeiTable(child, ns);
                    if (!string.IsNullOrWhiteSpace(tableText))
                    {
                        sb.AppendLine(tableText);
                        sb.AppendLine();
                    }
                }
            }
            return sb.ToString().Trim();
        }

        private static string FormatTeiList(XElement listNode, XNamespace ns)
        {
            var sb = new StringBuilder();
            var type = (string?)listNode.Attribute("type");
            bool isOrdered = string.Equals(type, "ordered", StringComparison.OrdinalIgnoreCase);
            int index = 1;

            foreach (var item in listNode.Elements(ns + "item"))
            {
                var itemText = ExtractFormattedText(item);
                if (string.IsNullOrWhiteSpace(itemText)) continue;

                var nAttr = (string?)item.Attribute("n");
                if (!string.IsNullOrWhiteSpace(nAttr))
                {
                    sb.AppendLine($"{nAttr.TrimEnd('.')}. {itemText}");
                }
                else if (isOrdered)
                {
                    sb.AppendLine($"{index++}. {itemText}");
                }
                else
                {
                    sb.AppendLine($"- {itemText}");
                }
            }
            return sb.ToString().TrimEnd();
        }

        private static string FormatTeiFormula(XElement formulaNode, XNamespace ns)
        {
            var labelNode = formulaNode.Element(ns + "label");
            string label = labelNode != null ? CleanWhitespace(labelNode.Value) : string.Empty;

            var rawMath = new StringBuilder();
            foreach (var node in formulaNode.Nodes())
            {
                if (node == labelNode) continue;
                if (node is XText text) rawMath.Append(text.Value);
                else if (node is XElement el) rawMath.Append(ExtractFormattedText(el));
            }

            var mathContent = CleanWhitespace(rawMath.ToString());
            if (string.IsNullOrWhiteSpace(mathContent))
            {
                mathContent = CleanWhitespace(formulaNode.Value);
            }

            if (string.IsNullOrWhiteSpace(mathContent)) return string.Empty;

            if (!string.IsNullOrEmpty(label))
            {
                return $"$$\n{mathContent}\n$$ *{label}*";
            }
            return $"$$\n{mathContent}\n$$";
        }

        private static string FormatTeiFigure(XElement figureNode, XNamespace ns)
        {
            var sb = new StringBuilder();
            var head = figureNode.Element(ns + "head")?.Value;
            var figDesc = figureNode.Element(ns + "figDesc")?.Value;
            var table = figureNode.Element(ns + "table");

            if (table != null)
            {
                var tableMarkdown = FormatTeiTable(table, ns);
                if (!string.IsNullOrWhiteSpace(tableMarkdown))
                {
                    sb.AppendLine(tableMarkdown);
                    sb.AppendLine();
                }
            }

            var caption = new StringBuilder();
            if (!string.IsNullOrWhiteSpace(head))
            {
                caption.Append($"**{CleanWhitespace(head)}**");
            }
            if (!string.IsNullOrWhiteSpace(figDesc))
            {
                if (caption.Length > 0) caption.Append(": ");
                caption.Append(CleanWhitespace(figDesc));
            }

            if (caption.Length > 0)
            {
                sb.AppendLine($"> 📊 {caption}");
            }

            return sb.ToString().TrimEnd();
        }

        private static string FormatEmbeddedSubsectionText(string text)
        {
            if (string.IsNullOrWhiteSpace(text)) return string.Empty;
            
            // Tách các mục danh sách có số thứ tự dạng 1. Item, 2. Item
            text = Regex.Replace(text, @"(\b\d+\.\s*[A-Z][^\n\.]*?\.)\s*", "\n\n$1\n");
            
            // Format công thức toán học
            text = Regex.Replace(text, @"XF=\[P,B,D,S,T\]X_F\s*=\s*\[P,\s*B,\s*D,\s*S,\s*T\]", "\n\n$$\nX_F = [P, B, D, S, T]\n$$\n\n");
            text = Regex.Replace(text, @"\b([A-Z]_[A-Z0-9]+)\s*=\s*(\[[^\]]+\])", "\n\n$$\n$1 = $2\n$$\n\n");

            return text.Trim();
        }

        private static string FormatTeiTable(XElement tableNode, XNamespace ns)
        {
            var rows = tableNode.Elements(ns + "row").ToList();
            if (!rows.Any()) return string.Empty;

            var sb = new StringBuilder();
            sb.AppendLine("| Metric | Result |");
            sb.AppendLine("| --- | --- |");

            foreach (var row in rows)
            {
                var cells = row.Elements(ns + "cell").Select(c => ExtractFormattedText(c).Replace("|", "\\|")).ToList();
                if (!cells.Any()) continue;

                if (cells.Count == 1)
                {
                    var text = cells[0];
                    if (text.Equals("Metric Result", StringComparison.OrdinalIgnoreCase))
                    {
                        continue;
                    }
                    var match = Regex.Match(text, @"^(.*?)\s+([0-9\.\%]+)$");
                    if (match.Success)
                    {
                        sb.AppendLine($"| {match.Groups[1].Value.Trim()} | {match.Groups[2].Value.Trim()} |");
                    }
                    else
                    {
                        sb.AppendLine($"| {text} | |");
                    }
                }
                else
                {
                    sb.AppendLine($"| {cells[0]} | {string.Join(" ", cells.Skip(1))} |");
                }
            }
            return sb.ToString().TrimEnd();
        }

        private static string BuildFullSectionTitle(string? nAttr, string headText)
        {
            headText = CleanWhitespace(headText);
            if (string.IsNullOrWhiteSpace(nAttr))
            {
                return headText;
            }

            nAttr = nAttr.Trim();
            var cleanN = nAttr.TrimEnd('.');

            if (string.IsNullOrWhiteSpace(headText))
            {
                return cleanN.Contains('.') ? cleanN : $"{cleanN}.";
            }

            if (headText.StartsWith(nAttr, StringComparison.OrdinalIgnoreCase) ||
                headText.StartsWith(cleanN + " ", StringComparison.OrdinalIgnoreCase) ||
                headText.StartsWith(cleanN + ".", StringComparison.OrdinalIgnoreCase))
            {
                return headText;
            }

            if (cleanN.Contains('.'))
            {
                return $"{cleanN} {headText}".Trim();
            }
            else
            {
                return $"{cleanN}. {headText}".Trim();
            }
        }

        private static (bool isMajor, string majorPrefix) DetermineSectionHierarchy(string? nAttr, string fullTitle)
        {
            if (!string.IsNullOrWhiteSpace(nAttr))
            {
                var cleanN = nAttr.Trim().TrimEnd('.');
                if (cleanN.Contains('.'))
                {
                    var parts = cleanN.Split('.');
                    return (false, parts[0]);
                }
                else
                {
                    return (true, cleanN);
                }
            }

            var matchSub = Regex.Match(fullTitle, @"^(\d+)\.(\d+(\.\d+)*)\.?\s*", RegexOptions.IgnoreCase);
            if (matchSub.Success)
            {
                return (false, matchSub.Groups[1].Value);
            }

            var matchMajor = Regex.Match(fullTitle, @"^(\d+|[IVXLCDM]+)\.?\s+", RegexOptions.IgnoreCase);
            if (matchMajor.Success)
            {
                return (true, matchMajor.Groups[1].Value);
            }

            var lower = fullTitle.Trim().ToLowerInvariant();
            var majorKeywords = new[] { "abstract", "introduction", "related work", "background", "methodology", "method", "proposed", "system model", "architecture", "experiment", "result", "evaluation", "discussion", "conclusion", "references" };
            if (majorKeywords.Any(k => lower.Contains(k)))
            {
                return (true, string.Empty);
            }

            return (true, string.Empty);
        }

        private static string ExtractLeadingNumber(string text)
        {
            if (string.IsNullOrWhiteSpace(text)) return string.Empty;
            var match = Regex.Match(text.Trim(), @"^(\d+|[IVXLCDM]+)[\.\s]", RegexOptions.IgnoreCase);
            return match.Success ? match.Groups[1].Value : string.Empty;
        }

        private static string CleanWhitespace(string input)
        {
            if (string.IsNullOrWhiteSpace(input)) return string.Empty;
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
                        var labelEl = el.Element(el.GetDefaultNamespace() + "label");
                        var labelText = labelEl != null ? CleanWhitespace(labelEl.Value) : string.Empty;

                        var mathSb = new StringBuilder();
                        foreach (var innerNode in el.Nodes())
                        {
                            if (innerNode == labelEl) continue;
                            if (innerNode is XText t) mathSb.Append(t.Value);
                            else if (innerNode is XElement subEl) mathSb.Append(ExtractFormattedText(subEl));
                        }
                        var math = CleanWhitespace(mathSb.ToString());
                        if (string.IsNullOrWhiteSpace(math)) math = CleanWhitespace(el.Value);

                        if (!string.IsNullOrWhiteSpace(math))
                        {
                            sb.Append($" ${math}$ ");
                            if (!string.IsNullOrWhiteSpace(labelText))
                            {
                                sb.Append($"*{labelText}* ");
                            }
                        }
                    }
                    else if (localName == "ref")
                    {
                        var innerText = ExtractFormattedText(el);
                        sb.Append(innerText);
                    }
                    else
                    {
                        sb.Append(ExtractFormattedText(el));
                    }
                }
            }
            return CleanWhitespace(sb.ToString());
        }
    }
}
