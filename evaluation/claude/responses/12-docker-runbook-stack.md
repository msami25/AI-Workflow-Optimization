# Unedited first response — 12 Docker Runbook (Stack)

## Dockerfile

**Path:** `src/PromptEvaluation.Api/Dockerfile`

```dockerfile
# Stage 1: Build
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src

# Copy solution and project files first to cache NuGet restore layer
COPY ["PromptEvaluation.slnx", "./"]
COPY ["src/PromptEvaluation.Api/PromptEvaluation.Api.csproj", "src/PromptEvaluation.Api/"]
COPY ["tests/PromptEvaluation.Tests/PromptEvaluation.Tests.csproj", "tests/PromptEvaluation.Tests/"]
RUN dotnet restore "src/PromptEvaluation.Api/PromptEvaluation.Api.csproj"

# Copy remaining source code
COPY . .
WORKDIR "/src/src/PromptEvaluation.Api"
RUN dotnet build "PromptEvaluation.Api.csproj" -c Release -o /app/build

# Stage 2: Publish
FROM build AS publish
RUN dotnet publish "PromptEvaluation.Api.csproj" -c Release -o /app/publish /p:UseAppHost=false

# Stage 3: Runtime
FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS final
WORKDIR /app
EXPOSE 8080

# Run as non-root user for security
USER app

COPY --from=publish /app/publish .

# Define entrypoint
ENTRYPOINT ["dotnet", "PromptEvaluation.Api.dll"]
```

---

## Docker Compose

**Path:** `docker-compose.yml` (at solution root)

```yaml
version: '3.8'

services:
  api:
    build:
      context: .
      dockerfile: src/PromptEvaluation.Api/Dockerfile
    ports:
      - "8080:8080"
    environment:
      - ASPNETCORE_ENVIRONMENT=Production
      - ASPNETCORE_URLS=http://+:8080
      # Override the local dev connection string to use a mounted volume
      - ConnectionStrings__DefaultConnection=Data Source=/app/data/evaluation.db
      - Jwt__SigningKey=${JWT_SIGNING_KEY:-ProvideAStrongSecretKeyAtLeast32BytesLong!}
    volumes:
      - app-data:/app/data
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 10s

volumes:
  app-data:
    # Persist the SQLite database across container restarts/recreations
```

---

## Execution Instructions

1. **Build the Stack:**
   Run the following command from the root of the repository (where `docker-compose.yml` is located):
   ```bash
   docker compose build
   ```

2. **Start the Stack:**
   To run in the background (detached mode):
   ```bash
   docker compose up -d
   ```

3. **Verify Health:**
   Check the status of the containers:
   ```bash
   docker compose ps
   ```
   Or explicitly hit the health endpoint:
   ```bash
   curl http://localhost:8080/health
   ```

4. **View Logs (if needed):**
   ```bash
   docker compose logs -f api
   ```

5. **Stop the Stack:**
   ```bash
   docker compose down
   ```

*(Note: The SQLite database file will persist in the `app-data` Docker volume. If you need to completely reset the database, use `docker compose down -v` to destroy the volume as well.)*
