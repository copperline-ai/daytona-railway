# Daytona on Railway

Deploy the [Daytona](https://daytona.io) development environment manager on Railway with Postgres, Redis, and MinIO as backing services.

## Table of Contents

1. [Overview](#overview)
2. [Architecture](#architecture)
3. [Prerequisites](#prerequisites)
4. [Quick Deploy](#quick-deploy)
5. [Manual Setup](#manual-setup)
6. [Environment Variables](#environment-variables)
7. [First-run: MinIO Bucket Setup](#first-run-minio-bucket-setup)
8. [Accessing the Dashboard](#accessing-the-dashboard)
9. [Limitations & Next Steps](#limitations--next-steps)

---

## Overview

This template deploys the **Daytona API server and dashboard** (`daytonaio/daytona-api`) on Railway. Daytona is an open-source development environment manager that lets teams provision and manage remote dev environments.

**v1 scope — dashboard only.** This deployment exposes the Daytona management dashboard so you can configure and monitor your Daytona instance. Workspace runners (the components that actually spin up dev environments) are not included in v1 and are planned for v2.

Services in this template:

| Service | Image | Purpose |
|---------|-------|---------|
| `daytona-api` | `daytonaio/daytona-api` | Daytona API server + dashboard |
| `Postgres` | Railway plugin | Primary database |
| `Redis` | Railway plugin | Session/cache store |
| `Minio` | `minio/minio` | S3-compatible workspace artifact storage |

---

## Architecture

```
Internet (HTTPS)
       │
       ▼
Railway public domain
       │
       ▼
┌──────────────────────┐
│     daytona-api      │  ← port 3000
│  daytonaio/daytona-api│    health: /api/health
└───────┬──────┬───────┘
        │      │  Railway private network
   ┌────┘      └──────────────────┐
   ▼                              ▼
┌──────────┐           ┌──────────────────┐
│ Postgres │           │      Redis       │
│ (plugin) │           │    (plugin)      │
└──────────┘           └──────────────────┘

┌──────────────────────────┐
│         Minio            │  ← private port 9000 (S3 API)
│      minio/minio         │    public port 9001  (console, temp)
│  volume: /data           │
└──────────────────────────┘
```

`daytona-api` connects to Postgres, Redis, and MinIO over Railway's private network. No database or storage port is exposed to the internet.

---

## Prerequisites

- A [Railway](https://railway.app) account — Hobby plan or higher recommended (free tier services sleep after inactivity)
- A GitHub account to fork or deploy this repository
- Familiarity with Railway's service and variable UI

---

## Quick Deploy

[![Deploy on Railway](https://railway.app/button.svg)](https://railway.app/new/template)

> **After clicking Deploy:** The button creates the `daytona-api` service. You still need to add the Postgres and Redis plugins and the MinIO custom service, then wire environment variables. Follow the [Manual Setup](#manual-setup) steps below to complete the deployment.

---

## Manual Setup

Follow each step in order. Services must exist before you can reference their variables.

### Step 1 — Create a Railway project

1. Go to [railway.app/new](https://railway.app/new)
2. Select **Empty project**
3. Name the project (e.g. `daytona`)

### Step 2 — Add Postgres

1. Inside your project, click **+ New** → **Database** → **Add PostgreSQL**
2. Railway provisions a managed Postgres instance automatically
3. The service is named `Postgres` by default — this name is used in variable references

### Step 3 — Add Redis

1. Click **+ New** → **Database** → **Add Redis**
2. Railway provisions a managed Redis instance automatically
3. The service is named `Redis` by default — this name is used in variable references

### Step 4 — Add MinIO

MinIO provides S3-compatible object storage. It runs on Railway's private network so the storage port is never internet-accessible.

1. Click **+ New** → **Empty Service**
2. Name the service exactly **`Minio`** (capitalization matters for Railway variable references)
3. Open the service's **Settings** tab:
   - Under **Source**, choose **Docker Image** and enter: `minio/minio`
   - Under **Deploy** → **Start Command**, enter: `server /data --console-address :9001`
4. Open the **Volumes** tab → **Add Volume** → mount path: `/data`
5. Open the **Variables** tab and add:

   | Variable | Value |
   |----------|-------|
   | `MINIO_ROOT_USER` | `minioadmin` (or any username you choose) |
   | `MINIO_ROOT_PASSWORD` | A strong random password — keep this secret |
   | `MINIO_IDENTITY_STS_EXPIRY` | `24h` |

6. Click **Deploy**. Wait for MinIO to show a green health status before proceeding.

### Step 5 — Add daytona-api service

1. Click **+ New** → **GitHub Repo** → select this repository  
   *(Alternatively: **Empty Service** → **Settings** → **Source** → Docker Image → `daytonaio/daytona-api`)*
2. Name the service **`daytona-api`**
3. Open the **Settings** tab → **Deploy** section:
   - Set **Health Check Path** to `/api/health`
4. Open the **Variables** tab and add all variables from `.env.example` (see [Environment Variables](#environment-variables))
5. Click **Deploy**

### Step 6 — Wire environment variables

Railway variable references automatically inject values from other services at deploy time. In the `daytona-api` service variables, use the following reference syntax:

| Variable | Value |
|----------|-------|
| `DB_HOST` | `${{Postgres.PGHOST}}` |
| `DB_PORT` | `${{Postgres.PGPORT}}` |
| `DB_USERNAME` | `${{Postgres.PGUSER}}` |
| `DB_PASSWORD` | `${{Postgres.PGPASSWORD}}` |
| `DB_DATABASE` | `${{Postgres.PGDATABASE}}` |
| `REDIS_HOST` | `${{Redis.REDISHOST}}` |
| `REDIS_PORT` | `${{Redis.REDISPORT}}` |
| `S3_ENDPOINT` | `http://${{Minio.RAILWAY_PRIVATE_DOMAIN}}:9000` |
| `S3_ACCESS_KEY` | `${{Minio.MINIO_ROOT_USER}}` |
| `S3_SECRET_KEY` | `${{Minio.MINIO_ROOT_PASSWORD}}` |
| `S3_BUCKET` | `daytona` |
| `S3_REGION` | `us-east-1` |
| `DASHBOARD_URL` | `https://${{RAILWAY_PUBLIC_DOMAIN}}/dashboard` |
| `DASHBOARD_BASE_API_URL` | `https://${{RAILWAY_PUBLIC_DOMAIN}}` |
| `ENCRYPTION_KEY` | *(generate with `openssl rand -hex 16`)* |
| `ENCRYPTION_SALT` | *(generate with `openssl rand -hex 16`)* |
| `RUN_MIGRATIONS` | `true` |
| `PORT` | `3000` |
| `NODE_ENV` | `production` |

The `.env.example` file in this repository contains the full list with reference syntax pre-filled. You can copy it directly into Railway's bulk variable editor.

---

## Environment Variables

Full reference with descriptions for every variable. See [docs/env-variables.md](docs/env-variables.md) for detailed per-variable documentation including security guidance.

| Variable | Required | Description |
|----------|----------|-------------|
| `DB_HOST` | Yes | Postgres hostname |
| `DB_PORT` | Yes | Postgres port |
| `DB_USERNAME` | Yes | Postgres user |
| `DB_PASSWORD` | Yes | Postgres password |
| `DB_DATABASE` | Yes | Postgres database name |
| `REDIS_HOST` | Yes | Redis hostname |
| `REDIS_PORT` | Yes | Redis port |
| `S3_ENDPOINT` | Yes | MinIO S3 API endpoint (private network URL) |
| `S3_ACCESS_KEY` | Yes | MinIO root user |
| `S3_SECRET_KEY` | Yes | MinIO root password |
| `S3_BUCKET` | Yes | Bucket for workspace artifacts (default: `daytona`) |
| `S3_REGION` | Yes | S3 region (use `us-east-1` for MinIO) |
| `DASHBOARD_URL` | Yes | Full public URL of the dashboard |
| `DASHBOARD_BASE_API_URL` | Yes | Base public URL of the API |
| `ENCRYPTION_KEY` | Yes | **Must change** — 32-char random string |
| `ENCRYPTION_SALT` | Yes | **Must change** — 32-char random string |
| `RUN_MIGRATIONS` | Yes | `true` to run DB migrations on startup |
| `PORT` | Yes | API listen port (`3000`) |
| `NODE_ENV` | Yes | Runtime environment (`production`) |
| `SMTP_HOST` | No | SMTP hostname for outbound email |
| `SMTP_PORT` | No | SMTP port |
| `SMTP_USER` | No | SMTP username |
| `SMTP_PASS` | No | SMTP password |
| `SMTP_FROM` | No | From address for emails |
| `DEFAULT_QUOTA_CPU` | No | Default CPU cores per workspace |
| `DEFAULT_QUOTA_MEMORY` | No | Default memory (MB) per workspace |
| `DEFAULT_QUOTA_DISK` | No | Default disk (GB) per workspace |

> **Security:** `ENCRYPTION_KEY` and `ENCRYPTION_SALT` protect all encrypted data at rest. Generate both with `openssl rand -hex 16`. Changing these after initial deployment will make existing encrypted data unreadable — treat them as permanent once set.

---

## First-run: MinIO Bucket Setup

Daytona stores workspace artifacts in a MinIO bucket that you must create before first use.

**Option A — MinIO web console**

1. Temporarily expose the MinIO console port publicly:
   - In the `Minio` service → **Settings** → **Networking** → **Add Port Exposure** → port `9001`
   - Railway generates a public URL for that port
2. Open the console URL in your browser
3. Log in with `MINIO_ROOT_USER` and `MINIO_ROOT_PASSWORD`
4. Click **Buckets** → **Create Bucket**
5. Enter the bucket name matching `S3_BUCKET` (default: `daytona`)
6. Leave the access policy as **Private**
7. After creating the bucket, remove the public port exposure for security

**Option B — MinIO CLI (`mc`)**

```bash
# Install mc: https://min.io/docs/minio/linux/reference/minio-mc.html
mc alias set railway https://<minio-public-port-url> $MINIO_ROOT_USER $MINIO_ROOT_PASSWORD
mc mb railway/daytona
mc ls railway
```

Once the bucket exists, redeploy or restart `daytona-api` if it failed health checks waiting for storage.

---

## Accessing the Dashboard

1. In your Railway project, open the `daytona-api` service
2. Go to **Settings** → **Networking** → **Public Networking** — Railway shows the generated public domain (e.g. `daytona-api-production.up.railway.app`)
3. Navigate to `https://<your-public-domain>/dashboard` in a browser
4. Complete the Daytona first-run setup wizard

The `DASHBOARD_URL` variable must match this public domain exactly. If you assign a custom domain to the service, update `DASHBOARD_URL` and `DASHBOARD_BASE_API_URL` to use that domain.

---

## Limitations & Next Steps

**v1 is dashboard-only.** This deployment lets you configure and manage a Daytona instance but does not include the infrastructure needed to run workspaces:

- No **workspace runner** — workspaces cannot be started
- No **SSH gateway** — no direct SSH access to workspaces
- No **Dex OIDC provider** — team authentication via SSO is not configured
- No **sandbox execution** — isolated build/run environments are out of scope

**Planned for v2:**

- Daytona runner service (workspace execution)
- SSH gateway for workspace terminal access
- Dex identity provider for team SSO
- Workspace-level CPU, memory, and disk quota enforcement

For questions or to contribute, open an issue on this repository.
