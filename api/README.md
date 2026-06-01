# Daytona API (Railway)

Thin wrapper that pins the Daytona API to a specific version
(`daytonaio/daytona-api:0.171.0`) and lets Railway build/deploy it from this
repo instead of pulling the upstream Daytona repo directly.

This is the same pattern as [`../migrations`](../migrations) — that service
runs the schema migrations once (`restartPolicyType = "never"`); this service
runs the long-lived API server (`restartPolicyType = "always"`).

## Pointing the Railway `daytona` API service at this folder

The API service currently builds from the upstream Daytona source. To switch it
to this folder:

1. Railway dashboard → project `daytona` → the API service → **Settings**.
2. **Source**: connect this repo (if not already) and set **Root Directory** to
   `/api`. Railway will pick up [`railway.toml`](railway.toml) and
   [`Dockerfile`](Dockerfile) from here.
3. Leave all existing **Variables** as-is — env config stays on the Railway
   service; this folder only pins the image version.
4. Redeploy.

## Bumping the version

Edit the tag in [`Dockerfile`](Dockerfile) and keep
[`../migrations/Dockerfile`](../migrations/Dockerfile) on the same tag so schema
and API move together, then redeploy both services.
