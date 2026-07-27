using PromptEvaluation.Api.DTOs;

namespace PromptEvaluation.Api.Services;

public interface IEventService
{
    Task<IEnumerable<EventListItemResponse>> GetAllAsync(CancellationToken cancellationToken = default);
    Task<EventResponse?> GetByIdAsync(int id, CancellationToken cancellationToken = default);
    Task<EventResponse> CreateAsync(EventCreateRequest request, CancellationToken cancellationToken = default);
    Task UpdateAsync(int id, EventUpdateRequest request, CancellationToken cancellationToken = default);
    Task DeleteAsync(int id, CancellationToken cancellationToken = default);
}
