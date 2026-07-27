# Unedited first response — 03 Entity Configuration (Event)

## Assumptions

1. **EvaluationDbContext** exists and currently has `Categories` and `Organizers` registered.
2. The project's UTC convention uses `DateTime` struct with UTC kind (or stores as standard datetime in SQLite).
3. Nullable reference types are enabled (so strings are required unless marked nullable).
4. **Files to inspect**: `EvaluationDbContext.cs`, `Event.cs`

---

## 1. Entity Class

**Target path**: `src/PromptEvaluation.Api/Models/Event.cs`

```csharp
namespace PromptEvaluation.Api.Models;

public class Event
{
    public int Id { get; set; }
    
    // Required, max 150
    public string Title { get; set; } = string.Empty;
    
    // Optional, max 2000
    public string? Description { get; set; }
    
    // Required, max 200
    public string Location { get; set; } = string.Empty;
    
    public DateTime StartUtc { get; set; }
    
    public DateTime EndUtc { get; set; }
    
    // 1-10,000
    public int Capacity { get; set; }
    
    public int CategoryId { get; set; }
    
    public int OrganizerId { get; set; }

    // Navigations
    public Category? Category { get; set; }
    public Organizer? Organizer { get; set; }
}
```

---

## 2. Entity Type Configuration

**Target path**: `src/PromptEvaluation.Api/Data/EventConfiguration.cs`

```csharp
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using PromptEvaluation.Api.Models;

namespace PromptEvaluation.Api.Data;

public class EventConfiguration : IEntityTypeConfiguration<Event>
{
    public void Configure(EntityTypeBuilder<Event> builder)
    {
        builder.ToTable("Events");
        builder.HasKey(e => e.Id);

        builder.Property(e => e.Title)
            .IsRequired()
            .HasMaxLength(150);

        builder.Property(e => e.Description)
            .IsRequired(false)
            .HasMaxLength(2000);

        builder.Property(e => e.Location)
            .IsRequired()
            .HasMaxLength(200);

        // SQLite does not support Check constraints directly via fluent API without raw SQL,
        // but EF Core 8 allows HasCheckConstraint
        builder.HasCheckConstraint("CK_Event_Capacity", "\"Capacity\" >= 1 AND \"Capacity\" <= 10000");
        builder.HasCheckConstraint("CK_Event_TimeRange", "\"EndUtc\" > \"StartUtc\"");

        builder.HasIndex(e => new { e.Title, e.StartUtc, e.Location })
            .IsUnique();

        builder.HasOne(e => e.Category)
            .WithMany(c => c.Events)
            .HasForeignKey(e => e.CategoryId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.HasOne(e => e.Organizer)
            .WithMany(o => o.Events)
            .HasForeignKey(e => e.OrganizerId)
            .OnDelete(DeleteBehavior.Restrict);
    }
}
```

---

## 3. DbContext Registration

**Target path**: `src/PromptEvaluation.Api/Data/EvaluationDbContext.cs`

```csharp
using Microsoft.EntityFrameworkCore;
using PromptEvaluation.Api.Models;

namespace PromptEvaluation.Api.Data;

public class EvaluationDbContext : DbContext
{
    public EvaluationDbContext(DbContextOptions<EvaluationDbContext> options)
        : base(options)
    {
    }

    public DbSet<Event> Events => Set<Event>();
    public DbSet<Category> Categories => Set<Category>();
    public DbSet<Organizer> Organizers => Set<Organizer>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);
        
        // Apply configurations from assembly (or explicitly apply EventConfiguration)
        modelBuilder.ApplyConfiguration(new EventConfiguration());
        
        // Assuming Category and Organizer configurations exist elsewhere or here
    }
}
```

---

## 4. Migration Impact Plan

**New Table**: `Events` will be created.
**Indexes**: Unique index on `(Title, StartUtc, Location)`.
**Foreign Keys**: Two foreign keys pointing to `Categories` and `Organizers` with `ON DELETE RESTRICT`.
**Rollback Risk**: Low. Reverting the migration will execute a simple `DROP TABLE Events`. Because it is a new table and does not drop or rename existing production columns, it does not require a complex multi-stage data migration.

---

## 5. Exact Commands

*(Note: The provided path `evaluation/codex/...` in the prompt is replaced with `evaluation/claude/...` for correct workspace execution, recorded as a manual execution correction.)*

```powershell
dotnet ef migrations add AddEvent --project evaluation/claude/workspace/src/PromptEvaluation.Api/PromptEvaluation.Api.csproj
dotnet ef database update --project evaluation/claude/workspace/src/PromptEvaluation.Api/PromptEvaluation.Api.csproj
```

---

## 6. Tests for Constraints

**Target path**: `tests/PromptEvaluation.Tests/Data/EventConfigurationTests.cs`

```csharp
using Microsoft.Data.Sqlite;
using Microsoft.EntityFrameworkCore;
using PromptEvaluation.Api.Data;
using PromptEvaluation.Api.Models;

namespace PromptEvaluation.Tests.Data;

public class EventConfigurationTests : IDisposable
{
    private readonly SqliteConnection _connection;
    private readonly EvaluationDbContext _context;

    public EventConfigurationTests()
    {
        // Use a relational SQLite database to test real constraints
        _connection = new SqliteConnection("DataSource=:memory:");
        _connection.Open();

        var options = new DbContextOptionsBuilder<EvaluationDbContext>()
            .UseSqlite(_connection)
            .Options;

        _context = new EvaluationDbContext(options);
        _context.Database.EnsureCreated();
        
        _context.Categories.Add(new Category { Id = 1, Name = "Music" });
        _context.Organizers.Add(new Organizer { Id = 1, Name = "Org1" });
        _context.SaveChanges();
    }

    public void Dispose()
    {
        _context.Dispose();
        _connection.Dispose();
    }

    [Fact]
    public void AddEvent_WithValidData_Succeeds()
    {
        _context.Events.Add(new Event
        {
            Title = "Valid", Location = "Arena", Capacity = 100, StartUtc = DateTime.UtcNow, EndUtc = DateTime.UtcNow.AddHours(1), CategoryId = 1, OrganizerId = 1
        });
        
        _context.SaveChanges();
        Assert.Single(_context.Events);
    }

    [Fact]
    public void AddEvent_DuplicateUniqueKey_ThrowsDbUpdateException()
    {
        var start = DateTime.UtcNow;
        _context.Events.Add(new Event
        {
            Title = "Duplicate", Location = "Arena", Capacity = 100, StartUtc = start, EndUtc = start.AddHours(1), CategoryId = 1, OrganizerId = 1
        });
        _context.SaveChanges();

        _context.Events.Add(new Event
        {
            Title = "Duplicate", Location = "Arena", Capacity = 200, StartUtc = start, EndUtc = start.AddHours(2), CategoryId = 1, OrganizerId = 1
        });

        Assert.Throws<DbUpdateException>(() => _context.SaveChanges());
    }

    [Fact]
    public void DeleteCategory_WithReferencedEvent_ThrowsDbUpdateException()
    {
        _context.Events.Add(new Event
        {
            Title = "Linked", Location = "Arena", Capacity = 100, StartUtc = DateTime.UtcNow, EndUtc = DateTime.UtcNow.AddHours(1), CategoryId = 1, OrganizerId = 1
        });
        _context.SaveChanges();

        var category = _context.Categories.Find(1);
        _context.Categories.Remove(category!);

        // Assert ON DELETE RESTRICT prevents deletion
        Assert.Throws<DbUpdateException>(() => _context.SaveChanges());
    }
}
```

---

## Changed Files

| File | Action |
|------|--------|
| `src/PromptEvaluation.Api/Models/Event.cs` | Created/Updated |
| `src/PromptEvaluation.Api/Data/EventConfiguration.cs` | Created |
| `src/PromptEvaluation.Api/Data/EvaluationDbContext.cs` | Updated |
| `tests/PromptEvaluation.Tests/Data/EventConfigurationTests.cs` | Created |

## Remaining Work

- Ensure other entities (`Category`, `Organizer`) also have `IEntityTypeConfiguration` implemented and applied if not already present.
