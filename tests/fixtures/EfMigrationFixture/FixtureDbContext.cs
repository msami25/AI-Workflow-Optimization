using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Design;

namespace EfMigrationFixture;

public sealed class FixtureDbContext(DbContextOptions<FixtureDbContext> options)
    : DbContext(options)
{
    public DbSet<Widget> Widgets => Set<Widget>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<Widget>(entity =>
        {
            entity.Property(widget => widget.Name)
                .HasMaxLength(100)
                .IsRequired();
        });

        if (Environment.GetEnvironmentVariable("EF_MIGRATION_FIXTURE_MODEL_CHANGE") == "1")
        {
            modelBuilder.Entity<Widget>().Property<string>("PendingValue");
        }
    }
}

public sealed class FixtureDbContextFactory
    : IDesignTimeDbContextFactory<FixtureDbContext>
{
    public FixtureDbContext CreateDbContext(string[] args)
    {
        var databasePath =
            Environment.GetEnvironmentVariable("EF_MIGRATION_FIXTURE_DB")
            ?? Path.Combine(AppContext.BaseDirectory, "fixture.db");
        var options = new DbContextOptionsBuilder<FixtureDbContext>()
            .UseSqlite($"Data Source={databasePath}")
            .Options;

        return new FixtureDbContext(options);
    }
}

public sealed class NoMigrationsDbContext(
    DbContextOptions<NoMigrationsDbContext> options)
    : DbContext(options);

public sealed class NoMigrationsDbContextFactory
    : IDesignTimeDbContextFactory<NoMigrationsDbContext>
{
    public NoMigrationsDbContext CreateDbContext(string[] args)
    {
        var databasePath =
            Environment.GetEnvironmentVariable("EF_MIGRATION_FIXTURE_DB")
            ?? Path.Combine(AppContext.BaseDirectory, "fixture.db");
        var options = new DbContextOptionsBuilder<NoMigrationsDbContext>()
            .UseSqlite($"Data Source={databasePath}")
            .Options;

        return new NoMigrationsDbContext(options);
    }
}

public sealed class Widget
{
    public int Id { get; set; }

    public required string Name { get; set; }
}
