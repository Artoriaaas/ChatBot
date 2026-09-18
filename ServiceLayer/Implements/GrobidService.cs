using ServiceLayer.Interfaces;
using System.IO;
using System.Net.Http;
using System.Threading.Tasks;
using System.Xml.Linq;
using System.Linq;
using System.Text;
using System;

namespace ServiceLayer.Implements
{
    public class GrobidService : IGrobidService
    {
        private readonly HttpClient _httpClient;

        public GrobidService(HttpClient httpClient)
        {
            _httpClient = httpClient;
        }

        public async Task<string> ProcessPdfAsync(Stream pdfStream)
        {
            try
            {
                using var request = new MultipartFormDataContent();
                
                // PDF File
                var fileContent = new StreamContent(pdfStream);
                fileContent.Headers.ContentType = new System.Net.Http.Headers.MediaTypeHeaderValue("application/pdf");
                request.Add(fileContent, "input", "document.pdf");
                
                // Add consolidateHeader = 0 to speed up if not needing DOI lookup
                request.Add(new StringContent("0"), "consolidateHeader");
                request.Add(new StringContent("0"), "consolidateCitations");
                request.Add(new StringContent("0"), "includeRawCitations");

                var response = await _httpClient.PostAsync("http://localhost:8070/api/processFulltextDocument", request);
                response.EnsureSuccessStatusCode();

                var xmlContent = await response.Content.ReadAsStringAsync();
                
                return ParseTeiXml(xmlContent);
            }
            catch (Exception ex)
            {
                throw new Exception($"Lỗi khi gọi GROBID: {ex.Message}");
            }
        }

        private string ParseTeiXml(string xml)
        {
            try
            {
                var doc = XDocument.Parse(xml);
                var ns = doc.Root?.GetDefaultNamespace() ?? XNamespace.None;
                
                var sb = new StringBuilder();

                // Extract abstract
                var abstractNode = doc.Descendants(ns + "abstract").FirstOrDefault();
                if (abstractNode != null)
                {
                    sb.AppendLine("Abstract:");
                    foreach (var p in abstractNode.Descendants(ns + "p"))
                    {
                        sb.AppendLine(p.Value);
                    }
                    sb.AppendLine();
                }

                // Extract body paragraphs
                var bodyNode = doc.Descendants(ns + "body").FirstOrDefault();
                if (bodyNode != null)
                {
                    foreach (var div in bodyNode.Descendants(ns + "div"))
                    {
                        var head = div.Elements(ns + "head").FirstOrDefault();
                        if (head != null)
                        {
                            sb.AppendLine($"\n{head.Value}");
                        }

                        foreach (var p in div.Elements(ns + "p"))
                        {
                            sb.AppendLine(p.Value);
                        }
                    }
                }

                return sb.ToString().Trim();
            }
            catch (Exception ex)
            {
                throw new Exception($"Lỗi khi parse XML từ GROBID: {ex.Message}");
            }
        }
    }
}
