using PromptEvaluation.Api.Contracts;

namespace PromptEvaluation.Api.Services;

public interface IEventService
{
    Task<IReadOnlyList<EventResponse>> GetAllAsync(CancellationToken cancellationToken);
    Task<EventResponse?> GetByIdAsync(int id, CancellationToken cancellationToken);
    Task<EventResponse> CreateAsync(EventCreateRequest request, CancellationToken cancellationToken);
    Task<bool> UpdateAsync(int id, EventUpdateRequest request, CancellationToken cancellationToken);
    Task<bool> DeleteAsync(int id, CancellationToken cancellationToken);
}

public interface ICategoryService
{
    Task<IReadOnlyList<CategoryResponse>> GetAllAsync(CancellationToken cancellationToken);
    Task<CategoryResponse?> GetByIdAsync(int id, CancellationToken cancellationToken);
    Task<CategoryResponse> CreateAsync(CategoryCreateRequest request, CancellationToken cancellationToken);
    Task<bool> UpdateAsync(int id, CategoryUpdateRequest request, CancellationToken cancellationToken);
    Task<bool> DeleteAsync(int id, CancellationToken cancellationToken);
}

public sealed class BusinessConflictException(string message) : Exception(message);
