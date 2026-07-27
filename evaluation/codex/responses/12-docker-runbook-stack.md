# Unedited first response - 12 Docker/runbook

Assumptions: API and frontend source paths must be confirmed; PostgreSQL is the
production relational provider; uploads and database data use named volumes.

Proposed Compose architecture:

- multi-stage .NET 8 API image with non-root runtime user;
- PostgreSQL with an internal-only port and health check;
- Node build stage and non-root nginx frontend;
- API health dependency on PostgreSQL health, plus its own `/health`;
- named `postgres-data` and `event-uploads` volumes;
- exact frontend origin and no committed secret values.

`.env.example` should list placeholders for
`ConnectionStrings__DefaultConnection`, `Jwt__Issuer`, `Jwt__Audience`,
`Jwt__SigningKey`, and `Frontend__Origin`. Real values must remain outside Git.

Verification:

```powershell
docker compose config
docker compose build
docker compose up -d
docker compose ps
curl.exe --fail http://localhost:8080/health
docker compose logs api
docker compose down
```

Use `docker compose down -v` only when deletion of named data is explicitly
intended. No Dockerfiles or Compose file were generated or executed because
the actual frontend/API build paths and health implementation were not
supplied. This response is reviewed only.

