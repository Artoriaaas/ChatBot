using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace DataAccessLayer.Migrations
{
    /// <inheritdoc />
    public partial class AddChatSessionEntity : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<Guid>(
                name: "SessionId",
                table: "ChatHistories",
                type: "uuid",
                nullable: true);

            migrationBuilder.CreateTable(
                name: "ChatSessions",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    Title = table.Column<string>(type: "character varying(255)", maxLength: 255, nullable: false),
                    DocumentId = table.Column<int>(type: "integer", nullable: true),
                    UserId = table.Column<string>(type: "text", nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_ChatSessions", x => x.Id);
                });

            migrationBuilder.CreateIndex(
                name: "IX_ChatHistories_SessionId",
                table: "ChatHistories",
                column: "SessionId");

            migrationBuilder.AddForeignKey(
                name: "FK_ChatHistories_ChatSessions_SessionId",
                table: "ChatHistories",
                column: "SessionId",
                principalTable: "ChatSessions",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_ChatHistories_ChatSessions_SessionId",
                table: "ChatHistories");

            migrationBuilder.DropTable(
                name: "ChatSessions");

            migrationBuilder.DropIndex(
                name: "IX_ChatHistories_SessionId",
                table: "ChatHistories");

            migrationBuilder.DropColumn(
                name: "SessionId",
                table: "ChatHistories");
        }
    }
}
