# Unedited first response — 08 Secure Upload (Event)

## Threat Table

| Threat | Mitigation | Risk without mitigation |
|---|---|---|
| Malicious File Execution | Store files outside the web root (no direct URL access). | Code execution (RCE) if an attacker uploads a `.aspx` or `.php` file. |
| Path Traversal (`../../etc/passwd`) | Generate a server-side random Guid filename. Never trust client `filename`. | Overwrite system files or leak sensitive files. |
| MIME Spoofing / Extension Bypass | Validate file extension against an allowlist AND verify magic bytes (file signature). | Bypassing client-side checks to host malware. |
| Denial of Service (Oversized files) | Enforce 5 MiB size limit via configuration before buffering the whole stream. | Memory exhaustion, disk fill, bandwidth saturation. |
| Double Extension (`file.jpg.exe`) | Parse the final extension using safe built-in tools (`Path.GetExtension`). | Bypassing basic string matching. |

---

## Service Code

**Target path**: `src/PromptEvaluation.Api/Services/ImageUploadService.cs`

```csharp
using System.Security.Cryptography;

namespace PromptEvaluation.Api.Services;

public interface IImageUploadService
{
    Task<string> UploadImageAsync(Stream fileStream, string fileName, string contentType, CancellationToken cancellationToken);
}

public class ImageUploadService : IImageUploadService
{
    private readonly string _storagePath;
    private const int MaxBytes = 5 * 1024 * 1024; // 5 MiB
    private readonly string[] _allowedExtensions = { ".jpg", ".jpeg", ".png" };

    public ImageUploadService(IConfiguration configuration)
    {
        // Must be outside content root, e.g. /var/uploads/events
        _storagePath = configuration["Uploads:EventImagesPath"] 
            ?? throw new ArgumentNullException("Upload path not configured");
            
        if (!Directory.Exists(_storagePath))
        {
            Directory.CreateDirectory(_storagePath);
        }
    }

    public async Task<string> UploadImageAsync(Stream fileStream, string fileName, string contentType, CancellationToken cancellationToken)
    {
        if (fileStream.Length == 0 || fileStream.Length > MaxBytes)
            throw new ArgumentException("File size is invalid or exceeds limit.");

        var ext = Path.GetExtension(fileName).ToLowerInvariant();
        if (!_allowedExtensions.Contains(ext))
            throw new ArgumentException("File type not allowed.");

        // Read magic bytes
        var magicBytes = new byte[4];
        var bytesRead = await fileStream.ReadAsync(magicBytes, 0, 4, cancellationToken);
        if (bytesRead < 4 || !IsValidSignature(magicBytes, ext))
            throw new ArgumentException("File signature mismatch.");

        fileStream.Position = 0; // Reset stream

        // Generate random, non-predictable filename
        var safeFileName = $"{Guid.NewGuid():N}{ext}";
        var fullPath = Path.Combine(_storagePath, safeFileName);

        await using var destinationStream = new FileStream(fullPath, FileMode.CreateNew, FileAccess.Write, FileShare.None, 4096, true);
        await fileStream.CopyToAsync(destinationStream, cancellationToken);

        return safeFileName;
    }

    private bool IsValidSignature(byte[] magicBytes, string extension)
    {
        return extension switch
        {
            ".jpg" or ".jpeg" => magicBytes[0] == 0xFF && magicBytes[1] == 0xD8 && magicBytes[2] == 0xFF,
            ".png" => magicBytes[0] == 0x89 && magicBytes[1] == 0x50 && magicBytes[2] == 0x4E && magicBytes[3] == 0x47,
            _ => false
        };
    }
}
```

---

## Controller Integration

```csharp
[HttpPost("{eventId:int}/image")]
[Authorize(Roles = "Admin")]
[RequestSizeLimit(5_242_880)] // Enforces size at Kestrel layer before reading stream
public async Task<IActionResult> UploadImage(
    int eventId, 
    IFormFile file, 
    CancellationToken cancellationToken)
{
    // Authorization is handled by [Authorize(Roles = "Admin")]
    
    try
    {
        await using var stream = file.OpenReadStream();
        var safeFileName = await _uploadService.UploadImageAsync(
            stream, file.FileName, file.ContentType, cancellationToken);
            
        // TODO: Update Event entity with safeFileName reference
        
        return Ok(new { Filename = safeFileName });
    }
    catch (ArgumentException ex)
    {
        return BadRequest(new ProblemDetails { Detail = ex.Message });
    }
}
```

---

## Tests

**Target path**: `tests/PromptEvaluation.Tests/Services/ImageUploadServiceTests.cs`

```csharp
using Microsoft.Extensions.Configuration;
using PromptEvaluation.Api.Services;

namespace PromptEvaluation.Tests.Services;

public class ImageUploadServiceTests
{
    private readonly ImageUploadService _service;
    private readonly string _testPath = Path.Combine(Path.GetTempPath(), "test_uploads");

    public ImageUploadServiceTests()
    {
        var config = new ConfigurationBuilder()
            .AddInMemoryCollection(new Dictionary<string, string> { { "Uploads:EventImagesPath", _testPath } }!)
            .Build();
        _service = new ImageUploadService(config);
    }

    [Fact]
    public async Task Upload_ValidPng_Succeeds()
    {
        var bytes = new byte[] { 0x89, 0x50, 0x4E, 0x47, 0x00, 0x00, 0x00 };
        using var stream = new MemoryStream(bytes);
        
        var result = await _service.UploadImageAsync(stream, "test.png", "image/png", CancellationToken.None);
        
        Assert.NotNull(result);
        Assert.True(File.Exists(Path.Combine(_testPath, result)));
    }

    [Fact]
    public async Task Upload_SpoofedExtension_ThrowsException()
    {
        // Fake PNG signature but .jpg extension
        var bytes = new byte[] { 0x89, 0x50, 0x4E, 0x47, 0x00, 0x00, 0x00 };
        using var stream = new MemoryStream(bytes);
        
        await Assert.ThrowsAsync<ArgumentException>(() => 
            _service.UploadImageAsync(stream, "test.jpg", "image/jpeg", CancellationToken.None));
    }

    [Fact]
    public async Task Upload_Oversized_ThrowsException()
    {
        using var stream = new MemoryStream(new byte[5 * 1024 * 1024 + 1]);
        await Assert.ThrowsAsync<ArgumentException>(() => 
            _service.UploadImageAsync(stream, "test.jpg", "image/jpeg", CancellationToken.None));
    }
}
```

---

## Manual Verification Checklist

- [ ] Use `curl` or Postman to upload a valid `<5MB` JPG as an Admin. Verify 200 OK.
- [ ] Upload the same valid image as a User or Anonymous. Verify 401/403.
- [ ] Attempt to upload a 6MB image. Verify rejection by `[RequestSizeLimit]`.
- [ ] Rename a `.txt` file to `.jpg` and upload. Verify signature mismatch rejection.
- [ ] Pass `../../../test.jpg` as the filename. Verify stored filename is a random Guid.
