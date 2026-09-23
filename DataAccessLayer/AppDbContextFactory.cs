using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Design;
using System;
using System.IO;

namespace DataAccessLayer
{
    public class AppDbContextFactory : IDesignTimeDbContextFactory<AppDbContext>
    {
        public AppDbContext CreateDbContext(string[] args)
        {
            string? connectionString = null;

            var currentDir = Directory.GetCurrentDirectory();
            while (!string.IsNullOrWhiteSpace(currentDir))
            {
                var envPath = Path.Combine(currentDir, ".env");
                if (File.Exists(envPath))
                {
                    try
                    {
                        foreach (var line in File.ReadAllLines(envPath))
                        {
                            var trimmed = line.Trim();
                            if (trimmed.StartsWith("#") || !trimmed.Contains('=')) continue;
                            var idx = trimmed.IndexOf('=');
                            var key = trimmed[..idx].Trim();
                            var val = trimmed[(idx + 1)..].Trim();
                            if (key.Equals("ConnectionStrings__DefaultConnection", StringComparison.OrdinalIgnoreCase) ||
                                key.Equals("DefaultConnection", StringComparison.OrdinalIgnoreCase))
                            {
                                connectionString = val;
                                break;
                            }
                        }
                    }
                    catch { }
                    break;
                }
                currentDir = Directory.GetParent(currentDir)?.FullName;
            }

            connectionString ??= Environment.GetEnvironmentVariable("ConnectionStrings__DefaultConnection")
                ?? Environment.GetEnvironmentVariable("DefaultConnection")
                ?? "Host=localhost;Port=5432;Database=ChatBotDb;Username=postgres;Password=05052005;Trust Server Certificate=true";

            var optionsBuilder = new DbContextOptionsBuilder<AppDbContext>();
            optionsBuilder.UseNpgsql(connectionString, o => o.UseVector());

            return new AppDbContext(optionsBuilder.Options);
        }
    }
}
