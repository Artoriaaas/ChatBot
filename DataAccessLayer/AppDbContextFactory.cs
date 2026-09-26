using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Design;
using Microsoft.Extensions.Configuration;
using System;
using System.IO;

namespace DataAccessLayer
{
    public class AppDbContextFactory : IDesignTimeDbContextFactory<AppDbContext>
    {
        public AppDbContext CreateDbContext(string[] args)
        {
            var currentDirectory = new DirectoryInfo(Directory.GetCurrentDirectory());
            string? settingsDirectory = null;

            while (currentDirectory != null)
            {
                var chatbotSettingsPath = Path.Combine(currentDirectory.FullName, "ChatBot", "appsettings.json");
                if (File.Exists(chatbotSettingsPath))
                {
                    settingsDirectory = Path.Combine(currentDirectory.FullName, "ChatBot");
                    break;
                }

                if (File.Exists(Path.Combine(currentDirectory.FullName, "appsettings.json")))
                {
                    settingsDirectory = currentDirectory.FullName;
                    break;
                }

                currentDirectory = currentDirectory.Parent;
            }

            if (settingsDirectory == null)
            {
                throw new FileNotFoundException("Không tìm thấy ChatBot/appsettings.json để đọc cấu hình database.");
            }

            var configuration = new ConfigurationBuilder()
                .SetBasePath(settingsDirectory)
                .AddJsonFile("appsettings.json", optional: false)
                .Build();

            var connectionString = configuration.GetConnectionString("DefaultConnection");
            if (string.IsNullOrWhiteSpace(connectionString))
            {
                throw new InvalidOperationException("Thiếu ConnectionStrings:DefaultConnection trong appsettings.json.");
            }

            var optionsBuilder = new DbContextOptionsBuilder<AppDbContext>();
            optionsBuilder.UseNpgsql(connectionString, o => o.UseVector());

            return new AppDbContext(optionsBuilder.Options);
        }
    }
}
