# Unedited first response — 01 API Controller (Event)

## Assumptions and Required Existing Interfaces/DTOs

1. **IEventService** exists at `PromptEvaluation.Api.Services.IEventService` with methods:
   - `GetAllAsync(CancellationToken)` → `IEnumerable<EventListItemResponse>`
   - `GetByIdAsync(int, CancellationToken)` → `EventResponse?`
   - `CreateAsync(EventCreateRequest, CancellationToken)` → `EventResponse`
   - `UpdateAsync(int, EventUpdateRequest, CancellationToken)` → `void`
   - `DeleteAsync(int, CancellationToken)` → `void`

2. **DTOs** exist under `PromptEvaluation.Api.DTOs`:
   - `EventCreateRequest`, `EventUpdateRequest`, `EventResponse`, `EventListItemResponse`

3. **Centralized exception handling** maps domain exceptions to HTTP status codes. The controller does not contain broad catch blocks.

4. **Files to inspect**: `IEventService.cs`, Event DTOs, `Program.cs` (service registration, auth scheme).

---

## Complete Controller Code

**Target path**: `src/PromptEvaluation.Api/Controllers/EventController.cs`

```csharp
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using PromptEvaluation.Api.DTOs;
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
```

---

## Supporting Contracts

No additional contracts are missing. The controller depends only on `IEventService` and the Event DTOs.

---

## Unit/Integration Test Cases

**Target path**: `tests/PromptEvaluation.Tests/Controllers/EventControllerTests.cs`

```csharp
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;
using Moq;
using PromptEvaluation.Api.Controllers;
using PromptEvaluation.Api.DTOs;
using PromptEvaluation.Api.Services;

namespace PromptEvaluation.Tests.Controllers;

public class EventControllerTests
{
    private readonly Mock<IEventService> _serviceMock = new();
    private readonly Mock<ILogger<EventController>> _loggerMock = new();
    private readonly EventController _controller;

    public EventControllerTests()
    {
        _controller = new EventController(_serviceMock.Object, _loggerMock.Object);
    }

    [Fact]
    public async Task GetAllAsync_ReturnsOk_WithEvents()
    {
        var items = new[] { new EventListItemResponse { Id = 1, Title = "Concert" } };
        _serviceMock.Setup(s => s.GetAllAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(items);

        var result = await _controller.GetAllAsync(CancellationToken.None);

        var okResult = Assert.IsType<OkObjectResult>(result.Result);
        Assert.Equal(200, okResult.StatusCode);
    }

    [Fact]
    public async Task GetByIdAsync_EventExists_ReturnsOk()
    {
        _serviceMock.Setup(s => s.GetByIdAsync(1, It.IsAny<CancellationToken>()))
            .ReturnsAsync(new EventResponse { Id = 1, Title = "Concert" });

        var result = await _controller.GetByIdAsync(1, CancellationToken.None);

        var okResult = Assert.IsType<OkObjectResult>(result.Result);
        Assert.Equal(200, okResult.StatusCode);
    }

    [Fact]
    public async Task GetByIdAsync_EventNotFound_Returns404()
    {
        _serviceMock.Setup(s => s.GetByIdAsync(999, It.IsAny<CancellationToken>()))
            .ReturnsAsync((EventResponse?)null);

        var result = await _controller.GetByIdAsync(999, CancellationToken.None);

        Assert.IsType<NotFoundResult>(result.Result);
    }

    [Fact]
    public async Task CreateAsync_ValidRequest_Returns201()
    {
        var request = new EventCreateRequest
        {
            Title = "Concert",
            Location = "Arena",
            StartUtc = DateTime.UtcNow.AddDays(1),
            EndUtc = DateTime.UtcNow.AddDays(1).AddHours(2),
            Capacity = 100,
            CategoryId = 1,
            OrganizerId = 1
        };
        _serviceMock.Setup(s => s.CreateAsync(request, It.IsAny<CancellationToken>()))
            .ReturnsAsync(new EventResponse { Id = 1, Title = "Concert" });

        var result = await _controller.CreateAsync(request, CancellationToken.None);

        var created = Assert.IsType<CreatedAtActionResult>(result.Result);
        Assert.Equal(201, created.StatusCode);
        Assert.Equal(nameof(EventController.GetByIdAsync), created.ActionName);
    }

    [Fact]
    public async Task UpdateAsync_ValidRequest_Returns204()
    {
        _serviceMock.Setup(s => s.UpdateAsync(1, It.IsAny<EventUpdateRequest>(), It.IsAny<CancellationToken>()))
            .Returns(Task.CompletedTask);

        var result = await _controller.UpdateAsync(1,
            new EventUpdateRequest
            {
                Title = "Updated",
                Location = "New Arena",
                StartUtc = DateTime.UtcNow.AddDays(1),
                EndUtc = DateTime.UtcNow.AddDays(1).AddHours(3),
                Capacity = 200,
                CategoryId = 1,
                OrganizerId = 1
            },
            CancellationToken.None);

        Assert.IsType<NoContentResult>(result);
    }

    [Fact]
    public async Task DeleteAsync_ValidId_Returns204()
    {
        _serviceMock.Setup(s => s.DeleteAsync(1, It.IsAny<CancellationToken>()))
            .Returns(Task.CompletedTask);

        var result = await _controller.DeleteAsync(1, CancellationToken.None);

        Assert.IsType<NoContentResult>(result);
    }
}
```

---

## Verification Commands

```powershell
dotnet build evaluation/claude/workspace/PromptEvaluation.slnx --configuration Release
dotnet test evaluation/claude/workspace/PromptEvaluation.slnx --configuration Release --filter "FullyQualifiedName~EventControllerTests"
```

---

## Changed Files

| File | Action |
|------|--------|
| `src/PromptEvaluation.Api/Controllers/EventController.cs` | Created |
| `tests/PromptEvaluation.Tests/Controllers/EventControllerTests.cs` | Created |

## Risks

- Authorization attributes are applied but not testable at the unit level. Integration tests with `WebApplicationFactory` are needed for 401/403.
- Controller delegates all logic to `IEventService`; if the service interface changes, the controller must be updated.

## Remaining Work

- Integration tests with `WebApplicationFactory` and a test authentication handler for authorization paths.
- Pagination support on `GetAllAsync` if the event list grows large.
