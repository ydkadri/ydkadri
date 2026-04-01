# Docker Patterns

Docker and container guidelines for development environments.

## Project Organization

All Docker-related files should live in `docker/` directory at project root:

```
project-name/
└── docker/
    ├── docker-compose.yml
    ├── Dockerfile
    ├── .env.example
    └── (other Docker-related files)
```

## Docker Compose for Development

Use docker-compose for local development environments.

### Environment Variables

- Always use `.env` files for configuration
- Never commit `.env` files
- Provide `.env.example` as template

### Volumes

- Use volumes for data persistence
- Mount code directories for live reload during development

### Port Exposure

- Only expose ports to host that are needed
- Don't expose internal service ports unless necessary

## Dockerfile Patterns

### Multi-Stage Builds

Use multi-stage builds to create minimal final images:

```dockerfile
# Build stage - includes all build tools
FROM rust:latest AS builder
WORKDIR /app
COPY . .
RUN cargo build --release

# Runtime stage - minimal image
FROM debian:bookworm-slim
COPY --from=builder /app/target/release/app /usr/local/bin/
CMD ["app"]
```

**Goal**: End up with lightweight images, not bloated with build dependencies.

### Base Images

Use sensible defaults for the language/use case:

**Python:**
- Build: `python:3.11-slim`
- Runtime: `python:3.11-slim` (smaller than full image)
- Avoid alpine for Python (compilation issues with C extensions)

**Rust:**
- Build: `rust:1.75` or `rust:latest`
- Runtime: `debian:bookworm-slim` or `alpine:latest`
- Use static linking for true portability

**Node:**
- Build/Runtime: `node:20-alpine`

**General principle:** Prefer smaller images that still work reliably.

## Integration with justfile

Standard Docker commands in justfile:

```makefile
# Docker management
up:
    docker compose -f docker/docker-compose.yml up -d

down:
    docker compose -f docker/docker-compose.yml down

reset:
    docker compose -f docker/docker-compose.yml down -v
    docker compose -f docker/docker-compose.yml up -d --build

logs:
    docker compose -f docker/docker-compose.yml logs -f
```

## Networking

Use sensible defaults for development:
- Services can connect to each other by service name
- Only expose necessary ports to host machine
- Don't need to worry about custom networks for dev environments

## Common Patterns

### Database Services

```yaml
services:
  postgres:
    image: postgres:15-alpine
    environment:
      POSTGRES_DB: ${DB_NAME}
      POSTGRES_USER: ${DB_USER}
      POSTGRES_PASSWORD: ${DB_PASSWORD}
    volumes:
      - postgres_data:/var/lib/postgresql/data
    ports:
      - "5432:5432"

volumes:
  postgres_data:
```

### Application Services

```yaml
services:
  app:
    build:
      context: ..
      dockerfile: docker/Dockerfile
    environment:
      DATABASE_URL: ${DATABASE_URL}
    volumes:
      - ../src:/app/src  # Live reload
    ports:
      - "8000:8000"
    depends_on:
      - postgres
```

## Best Practices

### Image Size

**Use multi-stage builds:**
```dockerfile
# Build stage - all build tools
FROM python:3.11-slim AS builder
WORKDIR /app
RUN pip install uv
COPY pyproject.toml .
RUN uv sync --frozen --no-dev

# Production - minimal runtime
FROM python:3.11-slim
WORKDIR /app
COPY --from=builder /app/.venv /app/.venv
COPY src/ /app/src/
ENV PATH="/app/.venv/bin:${PATH}"
CMD ["python", "-m", "myproject"]
```

**Use .dockerignore:**
```
# .dockerignore
.git/
.venv/
__pycache__/
*.pyc
.pytest_cache/
.mypy_cache/
.ruff_cache/
target/
node_modules/
.env
*.log
```

### Security

**Run as non-root user:**
```dockerfile
RUN useradd -m -u 1000 appuser && \
    chown -R appuser:appuser /app
USER appuser
```

**Use health checks:**
```dockerfile
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD python -c "import sys; sys.exit(0)"
```

```yaml
# In docker-compose.yml
services:
  app:
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8000/health"]
      interval: 30s
      timeout: 3s
      retries: 3
```

### Layer Caching

**Order operations from least to most frequently changed:**

```dockerfile
# ✅ CORRECT - Dependencies change less than code
FROM python:3.11-slim
WORKDIR /app

# Install dependencies first (cached layer)
COPY pyproject.toml .
RUN pip install uv && uv sync

# Copy code last (invalidates cache less often)
COPY src/ /app/src/

# ❌ INCORRECT - Code changes invalidate dependency cache
FROM python:3.11-slim
WORKDIR /app
COPY . .
RUN pip install uv && uv sync
```

### Development vs Production

**Use different targets:**

```dockerfile
# Development stage - includes dev tools and test files
FROM python:3.11-slim AS development
WORKDIR /app
COPY --from=builder /app/.venv /app/.venv
COPY src/ /app/src/
COPY tests/ /app/tests/
ENV PATH="/app/.venv/bin:${PATH}"
CMD ["python", "-m", "myproject"]

# Production stage - minimal runtime
FROM python:3.11-slim AS production
WORKDIR /app
COPY --from=builder /app/.venv /app/.venv
COPY src/ /app/src/
ENV PATH="/app/.venv/bin:${PATH}"
CMD ["python", "-m", "myproject"]
```

**Use docker-compose overrides:**

```yaml
# docker-compose.yml - base config
services:
  app:
    build:
      context: .
      target: production

# docker-compose.dev.yml - development overrides
services:
  app:
    build:
      target: development
    volumes:
      - ./src:/app/src
      - ./tests:/app/tests
    environment:
      - LOG_LEVEL=DEBUG
```

Run development: `docker compose -f docker-compose.yml -f docker-compose.dev.yml up`

## Service Dependencies

### Health Checks and Wait Conditions

```yaml
services:
  app:
    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_healthy

  postgres:
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${DB_USER} -d ${DB_NAME}"]
      interval: 5s
      timeout: 5s
      retries: 5

  redis:
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 5s
      timeout: 3s
      retries: 5
```

## Maintenance

**Clean up regularly:**

```bash
# Remove unused images
docker image prune -a

# Remove stopped containers
docker container prune

# Remove unused volumes
docker volume prune

# Remove everything unused
docker system prune -a --volumes
```

**Add to justfile:**

```makefile
[group('docker')]
docker-clean:
    docker system prune -f

[group('docker')]
docker-clean-all:
    docker system prune -a -f --volumes
```

## Examples

See `claude/examples/` for:
- `docker-compose.yml` - Multi-service development environment
- `Dockerfile` - Multi-stage build with development and production targets

---

**Last Updated**: 2026-03-23
