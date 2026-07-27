# Unedited first response - 08 secure Event image upload

| Threat | Control |
| --- | --- |
| oversized body | server request limit plus bounded stream copy capped at 5 MiB |
| MIME/extension spoofing | allowlist `.jpg/.jpeg/.png`, declared MIME, and JPEG/PNG magic bytes |
| traversal/overwrite | ignore client path; cryptographic random server filename; create-new mode |
| executable/public content | store in isolated volume outside content root |
| malware | scanner unavailable; document residual risk and restrict image decoding |
| unauthorized upload | `[Authorize(Roles = "Admin")]` on endpoint |

`IEventImageStorage.SaveAsync(Stream, originalName, declaredContentType,
CancellationToken)` should return an opaque stored identifier. Options must
contain the absolute storage root and maximum bytes. Validate an empty stream
and signature before finalizing the file; delete any partial temporary file on
failure. Log size/type/result and Event Id, never file contents.

Tests required: valid JPEG/PNG, 5 MiB boundary, oversize, MIME mismatch, invalid
signature, double extension, traversal filename, empty stream, collision,
unauthorized user, and cancellation cleanup.

No storage code was compiled because the prompt supplied no existing upload
abstraction or controller target. This response is design-reviewed only and
does not claim malware scanning.

