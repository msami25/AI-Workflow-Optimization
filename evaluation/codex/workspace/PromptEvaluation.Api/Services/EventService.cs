using Microsoft.EntityFrameworkCore;
using PromptEvaluation.Api.Contracts;
using PromptEvaluation.Api.Data;
using PromptEvaluation.Api.Models;

namespace PromptEvaluation.Api.Services;

public sealed class EventService(
    EvaluationDbContext dbContext,
    ILogger<EventService> logger) : IEventService
{
    public async Task<IReadOnlyList<EventResponse>> GetAllAsync(
        CancellationToken cancellationToken) =>
        await dbContext.Events.AsNoTracking()
            .OrderBy(x => x.StartUtc).ThenBy(x => x.Id)
            .Select(x => ToResponse(x))
            .ToListAsync(cancellationToken);

    public Task<EventResponse?> GetByIdAsync(int id, CancellationToken cancellationToken) =>
        dbContext.Events.AsNoTracking()
            .Where(x => x.Id == id)
            .Select(x => ToResponse(x))
            .SingleOrDefaultAsync(cancellationToken);

    public async Task<EventResponse> CreateAsync(
        EventCreateRequest request,
        CancellationToken cancellationToken)
    {
        await EnsureUniqueAsync(request.Title, request.StartUtc, request.Location, null, cancellationToken);
        var entity = new Event
        {
            Title = request.Title.Trim(),
            Description = request.Description,
            Location = request.Location.Trim(),
            StartUtc = request.StartUtc,
            EndUtc = request.EndUtc,
            Capacity = request.Capacity,
            CategoryId = request.CategoryId,
            OrganizerId = request.OrganizerId
        };
        dbContext.Events.Add(entity);
        await dbContext.SaveChangesAsync(cancellationToken);
        logger.LogInformation("Created event {EventId}", entity.Id);
        return ToResponse(entity);
    }

    public async Task<bool> UpdateAsync(
        int id,
        EventUpdateRequest request,
        CancellationToken cancellationToken)
    {
        var entity = await dbContext.Events.FindAsync([id], cancellationToken);
        if (entity is null)
        {
            return false;
        }

        await EnsureUniqueAsync(request.Title, request.StartUtc, request.Location, id, cancellationToken);
        entity.Title = request.Title.Trim();
        entity.Description = request.Description;
        entity.Location = request.Location.Trim();
        entity.StartUtc = request.StartUtc;
        entity.EndUtc = request.EndUtc;
        entity.Capacity = request.Capacity;
        entity.CategoryId = request.CategoryId;
        entity.OrganizerId = request.OrganizerId;
        await dbContext.SaveChangesAsync(cancellationToken);
        return true;
    }

    public async Task<bool> DeleteAsync(int id, CancellationToken cancellationToken)
    {
        var entity = await dbContext.Events.FindAsync([id], cancellationToken);
        if (entity is null)
        {
            return false;
        }

        dbContext.Events.Remove(entity);
        await dbContext.SaveChangesAsync(cancellationToken);
        return true;
    }

    private async Task EnsureUniqueAsync(
        string title,
        DateTime startUtc,
        string location,
        int? excludedId,
        CancellationToken cancellationToken)
    {
        var duplicate = await dbContext.Events.AnyAsync(
            x => x.Title == title.Trim()
                && x.StartUtc == startUtc
                && x.Location == location.Trim()
                && (!excludedId.HasValue || x.Id != excludedId.Value),
            cancellationToken);
        if (duplicate)
        {
            throw new BusinessConflictException("An event already exists for that title, start, and location.");
        }
    }

    private static EventResponse ToResponse(Event entity) =>
        new(
            entity.Id,
            entity.Title,
            entity.Description,
            entity.Location,
            entity.StartUtc,
            entity.EndUtc,
            entity.Capacity,
            entity.CategoryId,
            entity.OrganizerId);
}
