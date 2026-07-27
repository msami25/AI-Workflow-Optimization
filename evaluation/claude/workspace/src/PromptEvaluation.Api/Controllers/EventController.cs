using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using PromptEvaluation.Api.DTOs;
using PromptEvaluation.Api.Exceptions;
using PromptEvaluation.Api.Services;

namespace PromptEvaluation.Api.Controllers;

[ApiController]
[Route("api/events")]
public class EventController : ControllerBase
{
    private readonly IEventService _eventService;
    private readonly ILogger<EventController> _logger;

    public EventController(IEventService eventService, ILogger<EventController> logger)
    {
        _eventService = eventService;
        _logger = logger;
    }

    [HttpGet]
    [AllowAnonymous]
    public async Task<ActionResult<IEnumerable<EventListItemResponse>>> GetAllAsync(
        CancellationToken cancellationToken)
    {
        var events = await _eventService.GetAllAsync(cancellationToken);
        return Ok(events);
    }

    [HttpGet("{id:int}")]
    [ActionName(nameof(GetByIdAsync))]
    [AllowAnonymous]
    public async Task<ActionResult<EventResponse>> GetByIdAsync(
        int id, CancellationToken cancellationToken)
    {
        var ev = await _eventService.GetByIdAsync(id, cancellationToken);
        if (ev is null)
        {
            return NotFound();
        }

        return Ok(ev);
    }

    [HttpPost]
    [Authorize(Roles = "Admin")]
    public async Task<ActionResult<EventResponse>> CreateAsync(
        [FromBody] EventCreateRequest request, CancellationToken cancellationToken)
    {
        var created = await _eventService.CreateAsync(request, cancellationToken);
        return CreatedAtAction(nameof(GetByIdAsync), new { id = created.Id }, created);
    }

    [HttpPut("{id:int}")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> UpdateAsync(
        int id, [FromBody] EventUpdateRequest request, CancellationToken cancellationToken)
    {
        await _eventService.UpdateAsync(id, request, cancellationToken);
        return NoContent();
    }

    [HttpDelete("{id:int}")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> DeleteAsync(
        int id, CancellationToken cancellationToken)
    {
        await _eventService.DeleteAsync(id, cancellationToken);
        return NoContent();
    }
}
