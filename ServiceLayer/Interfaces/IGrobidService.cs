using System.IO;
using System.Threading.Tasks;

namespace ServiceLayer.Interfaces
{
    public interface IGrobidService
    {
        Task<string> ProcessPdfAsync(Stream pdfStream);
    }
}
