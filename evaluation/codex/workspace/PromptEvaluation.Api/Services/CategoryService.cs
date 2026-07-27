using Microsoft.EntityFrameworkCore;
using PromptEvaluation.Api.Contracts;
using PromptEvaluation.Api.Data;
using PromptEvaluation.Api.Models;

namespace PromptEvaluation.Api.Services;

public sealed class CategoryService(
    EvaluationDbContext dbContext,
    ILogger<CategoryService> logger) : ICategoryService
{
    public async Task<IReadOnlyList<CategoryResponse>> GetAllAsync(
        CancellationToken cancellationToken) =>
        await dbContext.Categories.AsNoTracking()
            .OrderBy(x => x.Name)
            .Select(x => ToResponse(x))
            .ToListAsync(cancellationToken);

    public Task<CategoryResponse?> GetByIdAsync(int id, CancellationToken cancellationToken) =>
        dbContext.Categories.AsNoTracking()
            .Where(x => x.Id == id)
            .Select(x => ToResponse(x))
            .SingleOrDefaultAsync(cancellationToken);

    public async Task<CategoryResponse> CreateAsync(
        CategoryCreateRequest request,
        CancellationToken cancellationToken)
    {
        await EnsureUniqueAsync(request.Name, null, cancellationToken);
        var entity = new Category
        {
            Name = request.Name.Trim(),
            Description = request.Description,
            IsActive = request.IsActive
        };
        dbContext.Categories.Add(entity);
        await dbContext.SaveChangesAsync(cancellationToken);
        logger.LogInformation("Created category {CategoryId}", entity.Id);
        return ToResponse(entity);
    }

    public async Task<bool> UpdateAsync(
        int id,
        CategoryUpdateRequest request,
        CancellationToken cancellationToken)
    {
        var entity = await dbContext.Categories.FindAsync([id], cancellationToken);
        if (entity is null)
        {
            return false;
        }

        await EnsureUniqueAsync(request.Name, id, cancellationToken);
        entity.Name = request.Name.Trim();
        entity.Description = request.Description;
        entity.IsActive = request.IsActive;
        await dbContext.SaveChangesAsync(cancellationToken);
        return true;
    }

    public async Task<bool> DeleteAsync(int id, CancellationToken cancellationToken)
    {
        var entity = await dbContext.Categories.FindAsync([id], cancellationToken);
        if (entity is null)
        {
            return false;
        }

        if (await dbContext.Events.AnyAsync(x => x.CategoryId == id, cancellationToken))
        {
            throw new BusinessConflictException("A referenced category cannot be deleted.");
        }

        dbContext.Categories.Remove(entity);
        await dbContext.SaveChangesAsync(cancellationToken);
        return true;
    }

    private async Task EnsureUniqueAsync(
        string name,
        int? excludedId,
        CancellationToken cancellationToken)
    {
        var normalized = name.Trim();
        if (await dbContext.Categories.AnyAsync(
                x => x.Name == normalized && (!excludedId.HasValue || x.Id != excludedId.Value),
                cancellationToken))
        {
            throw new BusinessConflictException("A category with that name already exists.");
        }
    }

    private static CategoryResponse ToResponse(Category entity) =>
        new(entity.Id, entity.Name, entity.Description, entity.IsActive);
}
