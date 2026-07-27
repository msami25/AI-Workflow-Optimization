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

    public async Task<IEnumerable<CategoryListItemResponse>> GetAllAsync(CancellationToken cancellationToken = default)
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

    public async Task<CategoryResponse?> GetByIdAsync(int id, CancellationToken cancellationToken = default)
    {
        var category = await _context.Categories
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

        return category;
    }

    public async Task<CategoryResponse> CreateAsync(CategoryCreateRequest request, CancellationToken cancellationToken = default)
    {
        var existingName = await _context.Categories
            .AsNoTracking()
            .AnyAsync(c => c.Name.ToLower() == request.Name.ToLower(), cancellationToken);

        if (existingName)
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

    public async Task UpdateAsync(int id, CategoryUpdateRequest request, CancellationToken cancellationToken = default)
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

        entity.Name = request.Name;
        entity.Description = request.Description;
        entity.IsActive = request.IsActive;

        await _context.SaveChangesAsync(cancellationToken);

        _logger.LogInformation("Updated category {CategoryId}", id);
    }

    public async Task DeleteAsync(int id, CancellationToken cancellationToken = default)
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
