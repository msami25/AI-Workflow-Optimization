using System.ComponentModel.DataAnnotations;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using PromptEvaluation.Api.Data;
using PromptEvaluation.Api.DTOs;
using PromptEvaluation.Api.Exceptions;
using PromptEvaluation.Api.Models;

namespace PromptEvaluation.Api.Services;

public class EventService : IEventService
{
    private readonly EvaluationDbContext _context;
    private readonly ILogger<EventService> _logger;

    public EventService(EvaluationDbContext context, ILogger<EventService> logger)
    {
        _context = context;
        _logger = logger;
    }

    public async Task<IEnumerable<EventListItemResponse>> GetAllAsync(CancellationToken cancellationToken = default)
    {
        return await _context.Events
            .AsNoTracking()
            .Include(e => e.Category)
            .OrderBy(e => e.StartUtc)
            .ThenBy(e => e.Id)
            .Select(e => new EventListItemResponse
            {
                Id = e.Id,
                Title = e.Title,
                Location = e.Location,
                StartUtc = e.StartUtc,
                EndUtc = e.EndUtc,
                CategoryName = e.Category != null ? e.Category.Name : string.Empty,
                RemainingCapacity = e.Capacity
            })
            .ToListAsync(cancellationToken);
    }

    public async Task<EventResponse?> GetByIdAsync(int id, CancellationToken cancellationToken = default)
    {
        var ev = await _context.Events
            .AsNoTracking()
            .Where(e => e.Id == id)
            .Select(e => new EventResponse
            {
                Id = e.Id,
                Title = e.Title,
                Description = e.Description,
                Location = e.Location,
                StartUtc = e.StartUtc,
                EndUtc = e.EndUtc,
                Capacity = e.Capacity,
                CategoryId = e.CategoryId,
                OrganizerId = e.OrganizerId,
                DurationMinutes = (e.EndUtc - e.StartUtc).TotalMinutes
            })
            .SingleOrDefaultAsync(cancellationToken);

        return ev;
    }

    public async Task<EventResponse> CreateAsync(EventCreateRequest request, CancellationToken cancellationToken = default)
    {
        if (request.EndUtc <= request.StartUtc)
        {
            throw new ValidationException("EndUtc must be later than StartUtc.");
        }

        var duplicate = await _context.Events
            .AsNoTracking()
            .AnyAsync(e =>
                e.Title == request.Title &&
                e.StartUtc == request.StartUtc &&
                e.Location == request.Location,
                cancellationToken);

        if (duplicate)
        {
            _logger.LogWarning("Event uniqueness conflict: Title={Title}, StartUtc={StartUtc}, Location={Location}",
                request.Title, request.StartUtc, request.Location);
            throw new BusinessConflictException(
                "An event with the same Title, StartUtc, and Location already exists.",
                "DUPLICATE_EVENT");
        }

        var entity = new Event
        {
            Title = request.Title,
            Description = request.Description,
            Location = request.Location,
            StartUtc = request.StartUtc,
            EndUtc = request.EndUtc,
            Capacity = request.Capacity,
            CategoryId = request.CategoryId,
            OrganizerId = request.OrganizerId
        };

        _context.Events.Add(entity);
        await _context.SaveChangesAsync(cancellationToken);

        _logger.LogInformation("Created event {EventId}", entity.Id);

        return new EventResponse
        {
            Id = entity.Id,
            Title = entity.Title,
            Description = entity.Description,
            Location = entity.Location,
            StartUtc = entity.StartUtc,
            EndUtc = entity.EndUtc,
            Capacity = entity.Capacity,
            CategoryId = entity.CategoryId,
            OrganizerId = entity.OrganizerId,
            DurationMinutes = (entity.EndUtc - entity.StartUtc).TotalMinutes
        };
    }

    public async Task UpdateAsync(int id, EventUpdateRequest request, CancellationToken cancellationToken = default)
    {
        if (request.EndUtc <= request.StartUtc)
        {
            throw new ValidationException("EndUtc must be later than StartUtc.");
        }

        var entity = await _context.Events.FindAsync(new object[] { id }, cancellationToken);
        if (entity is null)
        {
            throw new EntityNotFoundException(nameof(Event), id);
        }

        var duplicate = await _context.Events
            .AsNoTracking()
            .AnyAsync(e =>
                e.Id != id &&
                e.Title == request.Title &&
                e.StartUtc == request.StartUtc &&
                e.Location == request.Location,
                cancellationToken);

        if (duplicate)
        {
            throw new BusinessConflictException(
                "An event with the same Title, StartUtc, and Location already exists.",
                "DUPLICATE_EVENT");
        }

        entity.Title = request.Title;
        entity.Description = request.Description;
        entity.Location = request.Location;
        entity.StartUtc = request.StartUtc;
        entity.EndUtc = request.EndUtc;
        entity.Capacity = request.Capacity;
        entity.CategoryId = request.CategoryId;
        entity.OrganizerId = request.OrganizerId;

        await _context.SaveChangesAsync(cancellationToken);

        _logger.LogInformation("Updated event {EventId}", id);
    }

    public async Task DeleteAsync(int id, CancellationToken cancellationToken = default)
    {
        var entity = await _context.Events.FindAsync(new object[] { id }, cancellationToken);
        if (entity is null)
        {
            throw new EntityNotFoundException(nameof(Event), id);
        }

        _context.Events.Remove(entity);
        await _context.SaveChangesAsync(cancellationToken);

        _logger.LogInformation("Deleted event {EventId}", id);
    }
}
