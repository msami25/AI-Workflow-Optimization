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
