# Daytona Runner + Registry — local machine (macOS / Linux)

Run a Daytona **runner** and a Docker **registry** on your own machine, expose
both through one **named Cloudflare tunnel** with stable hostnames, and point the
hosted Daytona API at them using **Railway env vars only** — no DB scripts.

## How it fits together

```
        Railway (cloud)                  one named Cloudflare tunnel        your machine
  ┌───────────────────────┐            ┌───────────────────────────┐   ┌─────────────────────────┐
  │  daytona API / proxy  │  ───────▶  │ runner.example.com   ──────┼──▶│ daytona-runner :3003    │
  │  (DEFAULT_RUNNER_* +  │  jobs,     │ registry.example.com ──────┼──▶│ registry :5000          │
  │   *_REGISTRY_* env)   │  toolbox,  │                           │   │   └─ dockerd (DinD)      │
  │                       │  registry  └───────────────────────────┘   └─────────────────────────┘
  │                       │  ◀───────  runner polls jobs + posts health (outbound)
  └───────────────────────┘
```

The Daytona API is told about the runner and registry purely through its own env
vars on Railway. The local `.env` only configures the containers; the
`↔ Railway` values in it must match the corresponding API env vars (that's the
shared-secret handshake). **No `register-runner.py` / DB writes** — the named
tunnel gives stable hostnames, so once configured nothing needs updating.

> ### One-time caveat on an already-running deployment
> Daytona seeds the default runner and registries from env vars with
> **create-only-if-missing** semantics (`apps/api/src/app.service.ts`) — it never
> updates existing rows. So:
> - **Fresh deployment / empty DB:** set the env vars below and you're done.
> - **Existing deployment (rows already seeded):** clear the relevant rows once so
>   the API re-seeds from your new env vars on the next deploy:
>   ```sql
>   DELETE FROM runner WHERE name = 'default';
>   DELETE FROM docker_registry WHERE "registryType" IN ('internal','transient','backup');
>   ```
>   (Or add the runner + registry from the Daytona **dashboard / admin API**, which
>   also avoids SQL.) After that it's env-driven and stable.
>
> Daytona's env model expresses **one** default runner + **one** registry set, so
> this is a "local-first" mode: your machine becomes the default runner/registry.
> If you also keep the Fly runner, drain it (`UPDATE runner SET unschedulable=true
> WHERE name='fly.io';`) while working locally.

## Railway env vars (on the `daytona` API service)

Point the API at your tunnel hostnames. `<TOKEN>` = `DAYTONA_RUNNER_TOKEN`,
`<USER>`/`<PASS>` = `REGISTRY_USER`/`REGISTRY_PASS` from your local `.env`.

```
# default runner -> local runner via the tunnel
DEFAULT_RUNNER_DOMAIN=runner.example.com
DEFAULT_RUNNER_API_URL=https://runner.example.com
DEFAULT_RUNNER_PROXY_URL=https://runner.example.com
DEFAULT_RUNNER_API_KEY=<TOKEN>
DEFAULT_RUNNER_NAME=default
DEFAULT_RUNNER_CPU=4
DEFAULT_RUNNER_MEMORY=8
DEFAULT_RUNNER_DISK=50

# registries -> local registry via the tunnel
INTERNAL_REGISTRY_URL=https://registry.example.com
INTERNAL_REGISTRY_ADMIN=<USER>
INTERNAL_REGISTRY_PASSWORD=<PASS>
INTERNAL_REGISTRY_PROJECT_ID=daytona
TRANSIENT_REGISTRY_URL=https://registry.example.com
TRANSIENT_REGISTRY_ADMIN=<USER>
TRANSIENT_REGISTRY_PASSWORD=<PASS>
TRANSIENT_REGISTRY_PROJECT_ID=daytona
```

## Prerequisites

- **Docker** (Docker Desktop on macOS / Docker Engine on Linux). The runner ships
  its own `dockerd` and runs **privileged**.
- A **Cloudflare account + a domain** for the named tunnel.
- The MinIO root creds (Railway `minio` service) for the local `.env`.

## Setup

```bash
cd runner/local
cp .env.example .env
# edit .env: DAYTONA_RUNNER_TOKEN, REGISTRY_USER/PASS, AWS_* (MinIO), tunnel hostnames
```

**1. Generate the registry's htpasswd** (bcrypt, via Docker — no extra tooling):

```bash
set -a; . ./.env; set +a
docker run --rm --entrypoint htpasswd httpd:2 -Bbn "$REGISTRY_USER" "$REGISTRY_PASS" > registry/htpasswd
```

**2. Create the named Cloudflare tunnel** (commands in `cloudflared/config.example.yml`):

```bash
cloudflared tunnel login
cloudflared tunnel create daytona-local
cp ~/.cloudflared/<TUNNEL_ID>.json cloudflared/
cloudflared tunnel route dns daytona-local runner.example.com
cloudflared tunnel route dns daytona-local registry.example.com
cp cloudflared/config.example.yml cloudflared/config.yml   # fill in TUNNEL_ID + hostnames
```

**3. Start everything**

```bash
docker compose up -d
docker compose logs -f
# verify the registry through the tunnel:
curl -s -o /dev/null -w '%{http_code}\n' https://registry.example.com/v2/                       # 401
curl -s -u "$REGISTRY_USER:$REGISTRY_PASS" https://registry.example.com/v2/_catalog              # {"repositories":[...]}
```

**4. Set the Railway env vars** (above) and redeploy the API — on an existing DB,
do the one-time clear first (see caveat). The API seeds the runner + registries
from the env vars and the runner's health checks flip it to `ready`:

```bash
psql "$DATABASE_URL" -c "SELECT name, state FROM runner;"   # default -> ready
docker compose logs -f runner                                # watch PULL_SNAPSHOT / CREATE_SANDBOX
```

Create a sandbox; the runner pulls the base image, tags + pushes it to the local
registry, and starts the sandbox. It then shows in `https://registry.example.com/v2/_catalog`.

## Notes & gotchas

- **Stable hostnames are required**, not optional: the registry host is baked into
  every snapshot's `ref`, and the runner host is stored on the runner row. A named
  tunnel gives fixed hostnames; a throwaway quick tunnel would break refs on every
  restart.
- **Stuck snapshots:** a snapshot whose `ref` was built under a different registry
  sits in `state='error'` and won't retry — reset it (see
  [../flyio/registry/README.md](../flyio/registry/README.md)).
- **macOS performance:** DinD runs inside Docker Desktop's VM — give it enough
  CPU/RAM/disk (Settings → Resources).
```
