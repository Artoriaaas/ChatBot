using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace DataAccessLayer.Migrations
{
    /// <inheritdoc />
    public partial class AddExtendedPaperMetadata : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "Doi",
                table: "Papers",
                type: "text",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "Issue",
                table: "Papers",
                type: "text",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "Journal",
                table: "Papers",
                type: "text",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "Keywords",
                table: "Papers",
                type: "text",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "Pages",
                table: "Papers",
                type: "text",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "Publisher",
                table: "Papers",
                type: "text",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "Volume",
                table: "Papers",
                type: "text",
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "Doi",
                table: "Papers");

            migrationBuilder.DropColumn(
                name: "Issue",
                table: "Papers");

            migrationBuilder.DropColumn(
                name: "Journal",
                table: "Papers");

            migrationBuilder.DropColumn(
                name: "Keywords",
                table: "Papers");

            migrationBuilder.DropColumn(
                name: "Pages",
                table: "Papers");

            migrationBuilder.DropColumn(
                name: "Publisher",
                table: "Papers");

            migrationBuilder.DropColumn(
                name: "Volume",
                table: "Papers");
        }
    }
}
