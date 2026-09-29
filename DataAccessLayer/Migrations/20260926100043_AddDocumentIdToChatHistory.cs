using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace DataAccessLayer.Migrations
{
    /// <inheritdoc />
    public partial class AddDocumentIdToChatHistory : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<int>(
                name: "DocumentId",
                table: "ChatHistories",
                type: "integer",
                nullable: true);

            migrationBuilder.Sql("""
                UPDATE "ChatHistories" AS history
                SET "DocumentId" = source_documents."DocumentId"
                FROM (
                    SELECT chat_source."ChatHistoryId", MIN(chunk."DocumentId") AS "DocumentId"
                    FROM "ChatHistorySources" AS chat_source
                    INNER JOIN "DocumentChunks" AS chunk
                        ON chunk."Id" = chat_source."DocumentChunkId"
                    GROUP BY chat_source."ChatHistoryId"
                    HAVING COUNT(DISTINCT chunk."DocumentId") = 1
                ) AS source_documents
                WHERE history."Id" = source_documents."ChatHistoryId";
                """);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "DocumentId",
                table: "ChatHistories");
        }
    }
}
