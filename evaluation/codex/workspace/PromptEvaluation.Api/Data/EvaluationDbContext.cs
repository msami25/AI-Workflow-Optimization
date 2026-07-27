using Microsoft.EntityFrameworkCore;
using PromptEvaluation.Api.Models;

namespace PromptEvaluation.Api.Data;

public sealed class EvaluationDbContext(DbContextOptions<EvaluationDbContext> options)
    : DbContext(options)
{
    public DbSet<Event> Events => Set<Event>();
    public DbSet<Category> Categories => Set<Category>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<Event>(entity =>
        {
            entity.Property(x => x.Title).HasMaxLength(150).IsRequired();
            entity.Property(x => x.Description).HasMaxLength(2000);
            entity.Property(x => x.Location).HasMaxLength(200).IsRequired();
            entity.HasIndex(x => new { x.Title, x.StartUtc, x.Location }).IsUnique();
            entity.ToTable(table => table.HasCheckConstraint(
                "CK_Events_TimeRange", "\"EndUtc\" > \"StartUtc\""));
            entity.ToTable(table => table.HasCheckConstraint(
                "CK_Events_Capacity", "\"Capacity\" >= 1 AND \"Capacity\" <= 10000"));
            entity.HasOne(x => x.Category)
                .WithMany(x => x.Events)
                .HasForeignKey(x => x.CategoryId)
                .OnDelete(DeleteBehavior.Restrict);
        });

        modelBuilder.Entity<Category>(entity =>
        {
            entity.Property(x => x.Name)
                .HasMaxLength(80)
                .UseCollation("NOCASE")
                .IsRequired();
            entity.Property(x => x.Description).HasMaxLength(500);
            entity.HasIndex(x => x.Name).IsUnique();
        });
    }
}
