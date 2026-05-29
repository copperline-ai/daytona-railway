# Environment Variable Reference

Detailed documentation for every variable used by the Daytona Railway deployment. Set these in your `daytona-api` Railway service's **Variables** tab using Railway reference syntax (`${{ServiceName.VAR}}`).

See [.env.example](../.env.example) for a ready-to-paste copy.

---

## Database (Postgres)

Railway-managed Postgres plugin. The service name in Railway defaults to `Postgres`; adjust references if you rename it.

| Variable | Railway Reference | Description |
|----------|-------------------|-------------|
| `DB_HOST` | `${{Postgres.PGHOST}}` | Postgres hostname on Railway's private network |
| `DB_PORT` | `${{Postgres.PGPORT}}` | Postgres port (typically `5432`) |
| `DB_USERNAME` | `${{Postgres.PGUSER}}` | Postgres username |
| `DB_PASSWORD` | `${{Postgres.PGPASSWORD}}` | Postgres password |
| `DB_DATABASE` | `${{Postgres.PGDATABASE}}` | Postgres database name |

**Notes:**
- `RUN_MIGRATIONS=true` causes Daytona to apply database migrations on startup. Safe to keep enabled; migrations are idempotent.
- Do not expose the Postgres service publicly. All traffic stays on Railway's private network.

---

## Redis

Railway-managed Redis plugin. The service name defaults to `Redis`.

| Variable | Railway Reference | Description |
|----------|-------------------|-------------|
| `REDIS_HOST` | `${{Redis.REDISHOST}}` | Redis hostname on Railway's private network |
| `REDIS_PORT` | `${{Redis.REDISPORT}}` | Redis port (typically `6379`) |

**Notes:**
- Redis is used for session storage and caching. It is required; Daytona will not start without a reachable Redis instance.

---

## MinIO (S3-compatible object storage)

MinIO runs as a custom Railway service named `Minio`. The S3 endpoint uses Railway's **private networking** so the port is never exposed to the internet.

| Variable | Railway Reference | Description |
|----------|-------------------|-------------|
| `S3_ENDPOINT` | `http://${{Minio.RAILWAY_PRIVATE_DOMAIN}}:9000` | MinIO S3 API URL (private network) |
| `S3_ACCESS_KEY` | `${{Minio.MINIO_ROOT_USER}}` | MinIO root user (access key) |
| `S3_SECRET_KEY` | `${{Minio.MINIO_ROOT_PASSWORD}}` | MinIO root password (secret key) |
| `S3_BUCKET` | *(literal)* `daytona` | Bucket name — must be created manually before first use |
| `S3_REGION` | *(literal)* `us-east-1` | MinIO ignores region but requires a non-empty value |

**MinIO service configuration:**

| Setting | Value |
|---------|-------|
| Docker image | `minio/minio` |
| Start command | `server /data --console-address :9001` |
| Volume mount | `/data` |
| Exposed ports | `9000` (S3 API), `9001` (admin console) |
| `MINIO_ROOT_USER` | Choose a username (e.g. `minioadmin`) |
| `MINIO_ROOT_PASSWORD` | Strong random password — treat as a secret |
| `MINIO_IDENTITY_STS_EXPIRY` | `24h` |

**Security:** MinIO's S3 port (9000) should remain on the private network only. If you need the admin console (9001) from your browser, expose only that port publicly via Railway's networking settings, then lock it down once the bucket is created.

---

## Public URLs

These are populated automatically using Railway's built-in `RAILWAY_PUBLIC_DOMAIN` variable, which resolves to your service's generated public hostname.

| Variable | Railway Reference | Description |
|----------|-------------------|-------------|
| `DASHBOARD_URL` | `https://${{RAILWAY_PUBLIC_DOMAIN}}/dashboard` | Full URL of the Daytona dashboard |
| `DASHBOARD_BASE_API_URL` | `https://${{RAILWAY_PUBLIC_DOMAIN}}` | Base URL for API callbacks and redirects |

**Notes:**
- `RAILWAY_PUBLIC_DOMAIN` is injected automatically by Railway into the `daytona-api` service. No manual value needed.
- If you assign a custom domain to the service, update these variables to use that domain instead.

---

## Security

> **These values protect all encrypted data in Daytona. They must be changed before first use and must never be committed to version control.**

| Variable | Description |
|----------|-------------|
| `ENCRYPTION_KEY` | 32-character random string used to encrypt sensitive data at rest |
| `ENCRYPTION_SALT` | 32-character random string used as salt for encryption operations |

**Generating values:**

```bash
openssl rand -hex 16   # outputs 32 hex characters — use once for KEY, once for SALT
```

**Rules:**
- Never reuse the same value for both `ENCRYPTION_KEY` and `ENCRYPTION_SALT`.
- Never reuse values across environments (dev, staging, production).
- Changing these values after data has been stored will make existing encrypted data unreadable. Treat them as permanent once set.

---

## Runtime

| Variable | Default | Description |
|----------|---------|-------------|
| `RUN_MIGRATIONS` | `true` | Run database migrations on container startup |
| `PORT` | `3000` | Port the API server listens on. Railway injects this automatically; leave as `3000`. |
| `NODE_ENV` | `production` | Runtime environment. Always `production` on Railway. |

---

## SMTP (optional)

Leave all SMTP variables unset to disable email. Daytona will operate without email but some user-facing features (password reset, invitations) will be unavailable.

| Variable | Description |
|----------|-------------|
| `SMTP_HOST` | SMTP server hostname |
| `SMTP_PORT` | SMTP server port (typically `587` for STARTTLS, `465` for SSL) |
| `SMTP_USER` | SMTP authentication username |
| `SMTP_PASS` | SMTP authentication password |
| `SMTP_FROM` | From address for outbound email (e.g. `noreply@yourdomain.com`) |

---

## Quota Defaults (optional)

These control per-workspace resource limits. Omit to use Daytona's built-in defaults.

| Variable | Description |
|----------|-------------|
| `DEFAULT_QUOTA_CPU` | Default CPU cores per workspace |
| `DEFAULT_QUOTA_MEMORY` | Default memory (MB) per workspace |
| `DEFAULT_QUOTA_DISK` | Default disk (GB) per workspace |
