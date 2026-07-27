# Unedited first response — 02 CRUD Service (Category)

## Assumptions

1. **EvaluationDbContext** exists with `DbSet<Category> Categories` and `DbSet<Event> Events`.
2. **Category** entity has `Id`, `Name`, `Description`, `IsActive`, and navigation `ICollection<Event> Events`.
3. **DTOs**: `CategoryCreateRequest`, `CategoryUpdateRequest`, `CategoryResponse`, `CategoryListItemResponse` exist.
4. **Exception types**: `EntityNotFoundException` and `BusinessConflictException` are handled by middleware → 404/409.
5. The project treats `DbContext` as the unit of work; no separate repository abstraction.
6. **Files to inspect**: `EvaluationDbContext.cs`, `Category.cs`, Category DTOs, `Program.cs`.

---

## Interface Signatures

**Target path**: `src/PromptEvaluation.Api/Services/ICategoryService.cs`

```csharp
using PromptEvaluation.Api.DTOs;

namespace PromptEvaluation.Api.Services;

public interface ICategoryService
{
    Task<IEnumerable<CategoryListItemResponse>> GetAllAsync(CancellationToken cancellationToken = default);
    Task<CategoryResponse?> GetByIdAsync(int id, CancellationToken cancellationToken = default);
    Task<CategoryResponse> CreateAsync(CategoryCreateRequest request, CancellationToken cancellationToken = default);
    Task UpdateAsync(int id, CategoryUpdateRequest request, CancellationToken cancellationToken = default);
    Task DeleteAsync(int id, CancellationToken cancellationToken = default);
}
```

---

## Complete Service Code

**Target path**: `src/PromptEvaluation.Api/Services/CategoryService.cs`

**Choice: `SingleOrDefaultAsync` vs `FindAsync`**
- `FindAsync` is used for update/delete because it leverages the identity map (the entity will be tracked for `SaveChangesAsync`).
- `SingleOrDefaultAsync` with `AsNoTracking` is used for reads to avoid polluting the change tracker.
- For the delete case, `SingleOrDefaultAsync` with an `Include(c => c.Events)` is used because we need the navigation to check referential usage; `FindAsync` does not load navigations.

```csharp
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using PromptEvaluation.Api.Data;
using PromptEvaluation.Api.DTOs;
using PromptEvaluation.Api.Exceptions;
using PromptEvaluation.Api.Models;

namespace PromptEvaluation.Api.Services;

public class CategoryService : ICategoryService
{
    private readonly EvaluationDbContext _context;
    private readonly ILogger<CategoryService> _logger;

    public CategoryService(EvaluationDbContext context, ILogger<CategoryService> logger)
    {
        _context = context;
        _logger = logger;
    }

    public async Task<IEnumerable<CategoryListItemResponse>> GetAllAsync(
        CancellationToken cancellationToken = default)
    {
        return await _context.Categories
            .AsNoTracking()
            .Select(c => new CategoryListItemResponse
            {
                Id = c.Id,
                Name = c.Name,
                IsActive = c.IsActive
            })
            .ToListAsync(cancellationToken);
    }

    public async Task<CategoryResponse?> GetByIdAsync(
        int id, CancellationToken cancellationToken = default)
    {
        return await _context.Categories
            .AsNoTracking()
            .Where(c => c.Id == id)
            .Select(c => new CategoryResponse
            {
                Id = c.Id,
                Name = c.Name,
                Description = c.Description,
                IsActive = c.IsActive
            })
            .SingleOrDefaultAsync(cancellationToken);
    }

    public async Task<CategoryResponse> CreateAsync(
        CategoryCreateRequest request, CancellationToken cancellationToken = default)
    {
        var nameExists = await _context.Categories
            .AsNoTracking()
            .AnyAsync(c => c.Name.ToLower() == request.Name.ToLower(), cancellationToken);

        if (nameExists)
        {
            _logger.LogWarning("Category name conflict: {Name}", request.Name);
            throw new BusinessConflictException(
                $"A category with name '{request.Name}' already exists.",
                "DUPLICATE_CATEGORY_NAME");
        }

        var entity = new Category
        {
            Name = request.Name,
            Description = request.Description,
            IsActive = request.IsActive
        };

        _context.Categories.Add(entity);
        await _context.SaveChangesAsync(cancellationToken);

        _logger.LogInformation("Created category {CategoryId}", entity.Id);

        return new CategoryResponse
        {
            Id = entity.Id,
            Name = entity.Name,
            Description = entity.Description,
            IsActive = entity.IsActive
        };
    }

    public async Task UpdateAsync(
        int id, CategoryUpdateRequest request, CancellationToken cancellationToken = default)
    {
        var entity = await _context.Categories.FindAsync(new object[] { id }, cancellationToken);
        if (entity is null)
        {
            throw new EntityNotFoundException(nameof(Category), id);
        }

        var nameConflict = await _context.Categories
            .AsNoTracking()
            .AnyAsync(c => c.Id != id && c.Name.ToLower() == request.Name.ToLower(), cancellationToken);

        if (nameConflict)
        {
            throw new BusinessConflictException(
                $"A category with name '{request.Name}' already exists.",
                "DUPLICATE_CATEGORY_NAME");
        }

        // Map only allowed properties — prevents over-posting
        entity.Name = request.Name;
        entity.Description = request.Description;
        entity.IsActive = request.IsActive;

        await _context.SaveChangesAsync(cancellationToken);

        _logger.LogInformation("Updated category {CategoryId}", id);
    }

    public async Task DeleteAsync(
        int id, CancellationToken cancellationToken = default)
    {
        var entity = await _context.Categories
            .Include(c => c.Events)
            .SingleOrDefaultAsync(c => c.Id == id, cancellationToken);

        if (entity is null)
        {
            throw new EntityNotFoundException(nameof(Category), id);
        }

        if (entity.Events.Any())
        {
            throw new BusinessConflictException(
                $"Category '{entity.Name}' is referenced by {entity.Events.Count} event(s) and cannot be deleted.",
                "CATEGORY_IN_USE");
        }

        _context.Categories.Remove(entity);
        await _context.SaveChangesAsync(cancellationToken);

        _logger.LogInformation("Deleted category {CategoryId}", id);
    }
}
```

---

## DTO/Mapping Code

DTOs use explicit manual mapping within the service methods (no AutoMapper). This is visible in the `Select` projections for reads and explicit property assignment for writes. No additional mapping code is needed.

---

## Tests

**Target path**: `tests/PromptEvaluation.Tests/Services/CategoryServiceTests.cs`

```csharp
using Microsoft.Data.Sqlite;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using Moq;
using PromptEvaluation.Api.Data;
using PromptEvaluation.Api.DTOs;
using PromptEvaluation.Api.Exceptions;
using PromptEvaluation.Api.Models;
using PromptEvaluation.Api.Services;

namespace PromptEvaluation.Tests.Services;

public class CategoryServiceTests : IDisposable
{
    private readonly SqliteConnection _connection;
    private readonly EvaluationDbContext _context;
    private readonly CategoryService _service;

    public CategoryServiceTests()
    {
        _connection = new SqliteConnection("DataSource=:memory:");
        _connection.Open();

        var options = new DbContextOptionsBuilder<EvaluationDbContext>()
            .UseSqlite(_connection)
            .Options;

        _context = new EvaluationDbContext(options);
        _context.Database.EnsureCreated();

        _service = new CategoryService(
            _context,
            Mock.Of<ILogger<CategoryService>>());
    }

    public void Dispose()
    {
        _context.Dispose();
        _connection.Dispose();
    }

    [Fact]
    public async Task GetAllAsync_EmptyDatabase_ReturnsEmptyList()
    {
        var result = await _service.GetAllAsync();
        Assert.Empty(result);
    }

    [Fact]
    public async Task GetByIdAsync_ExistingCategory_ReturnsCategory()
    {
        _context.Categories.Add(new Category { Name = "Music", IsActive = true });
        await _context.SaveChangesAsync();

        var result = await _service.GetByIdAsync(1);

        Assert.NotNull(result);
        Assert.Equal("Music", result!.Name);
    }

    [Fact]
    public async Task GetByIdAsync_NonExistentId_ReturnsNull()
    {
        var result = await _service.GetByIdAsync(999);
        Assert.Null(result);
    }

    [Fact]
    public async Task CreateAsync_ValidRequest_CreatesAndReturns()
    {
        var request = new CategoryCreateRequest { Name = "Music", IsActive = true };

        var result = await _service.CreateAsync(request);

        Assert.Equal("Music", result.Name);
        Assert.True(result.Id > 0);
        Assert.Single(await _context.Categories.ToListAsync());
    }

    [Fact]
    public async Task CreateAsync_DuplicateName_ThrowsConflict()
    {
        _context.Categories.Add(new Category { Name = "Music", IsActive = true });
        await _context.SaveChangesAsync();

        var request = new CategoryCreateRequest { Name = "music" };

        await Assert.ThrowsAsync<BusinessConflictException>(
            () => _service.CreateAsync(request));
    }

    [Fact]
    public async Task UpdateAsync_ExistingCategory_UpdatesProperties()
    {
        _context.Categories.Add(new Category { Name = "Music", IsActive = true });
        await _context.SaveChangesAsync();

        await _service.UpdateAsync(1, new CategoryUpdateRequest
        {
            Name = "Live Music",
            IsActive = false
        });

        var updated = await _context.Categories.FindAsync(1);
        Assert.Equal("Live Music", updated!.Name);
        Assert.False(updated.IsActive);
    }

    [Fact]
    public async Task UpdateAsync_NonExistentId_ThrowsNotFound()
    {
        await Assert.ThrowsAsync<EntityNotFoundException>(
            () => _service.UpdateAsync(999, new CategoryUpdateRequest { Name = "X" }));
    }

    [Fact]
    public async Task DeleteAsync_UnreferencedCategory_Deletes()
    {
        _context.Categories.Add(new Category { Name = "Music", IsActive = true });
        await _context.SaveChangesAsync();

        await _service.DeleteAsync(1);

        Assert.Empty(await _context.Categories.ToListAsync());
    }

    [Fact]
    public async Task DeleteAsync_ReferencedCategory_ThrowsConflict()
    {
        var category = new Category { Name = "Music", IsActive = true };
        _context.Categories.Add(category);
        _context.Organizers.Add(new Organizer { Name = "Org1" });
        await _context.SaveChangesAsync();

        _context.Events.Add(new Event
        {
            Title = "Concert",
            Location = "Arena",
            StartUtc = DateTime.UtcNow,
            EndUtc = DateTime.UtcNow.AddHours(2),
            Capacity = 100,
            CategoryId = 1,
            OrganizerId = 1
        });
        await _context.SaveChangesAsync();

        await Assert.ThrowsAsync<BusinessConflictException>(
            () => _service.DeleteAsync(1));
    }

    [Fact]
    public async Task DeleteAsync_NonExistentId_ThrowsNotFound()
    {
        await Assert.ThrowsAsync<EntityNotFoundException>(
            () => _service.DeleteAsync(999));
    }

    [Fact]
    public async Task CreateAsync_Cancellation_ThrowsOperationCanceled()
    {
        var cts = new CancellationTokenSource();
        cts.Cancel();

        await Assert.ThrowsAnyAsync<OperationCanceledException>(
            () => _service.CreateAsync(
                new CategoryCreateRequest { Name = "Music" }, cts.Token));
    }
}
```

---

## Build/Test Commands

```powershell
dotnet build evaluation/claude/workspace/PromptEvaluation.slnx --configuration Release
dotnet test evaluation/claude/workspace/PromptEvaluation.slnx --configuration Release --filter "FullyQualifiedName~CategoryServiceTests"
```

## Performance Note

- `AsNoTracking` on read queries avoids identity-map overhead.
- The case-insensitive `Name.ToLower()` comparison works for SQLite (which already uses case-insensitive `NOCASE` collation by default). For PostgreSQL/SQL Server in production, consider a `COLLATE` configuration or `EF.Functions.Like` instead of `ToLower()`.

---

## Changed Files

| File | Action |
|------|--------|
| `src/PromptEvaluation.Api/Services/ICategoryService.cs` | Created |
| `src/PromptEvaluation.Api/Services/CategoryService.cs` | Created |
| `tests/PromptEvaluation.Tests/Services/CategoryServiceTests.cs` | Created |

## Risks

- `ToLower()` comparison may not translate efficiently for all providers. SQLite handles it due to default collation.
- `Include(c => c.Events)` on delete loads all events into memory; for categories with many events, `AnyAsync` would be more efficient.

## Remaining Work

- Pagination on `GetAllAsync` if the category list grows large.
- Consider `AnyAsync(e => e.CategoryId == id)` instead of `Include` for the referential delete check.
