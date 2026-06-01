# Daytona Runner (Fly.io)

Fly app for the Daytona runner (`copperline-daytona-runner`).

## Runtime shape (COP-663)

- VM class: `performance-2x` (`cpu_kind=performance`, `cpus=2`, `memory_mb=4096`)
- Always-on machines: `min_machines_running=1` (scale to `2` for peak load)
- Persistent Docker sandbox storage: `docker_data` mounted at `/var/lib/docker`
- Volume size: `25gb`

## GHCR pull credentials

The runner's Docker daemon must be able to pull snapshot images from GHCR.
Set one Fly secret containing Docker config JSON and project it to both root and
`daytona` users via `[[files]]` in `fly.toml`.

1. Create local Docker auth JSON:

```bash
mkdir -p /tmp/ghcr-auth
cat > /tmp/ghcr-auth/config.json <<'JSON'
{
  "auths": {
    "ghcr.io": {
      "auth": "<base64(username:token)>"
    }
  }
}
JSON
```

2. Set Fly secret:

   > **IMPORTANT:** Fly base64-**decodes** a secret's value when projecting it to a
   > `[[files]]` guest path. The secret must therefore contain the **base64-encoded**
   > config JSON, *not* the raw JSON. Setting raw JSON makes the machine fail to start:
   > flyd destroys it ~7s after creation, right after "Opening encrypted volume" and
   > before the entrypoint runs (no app logs), and `fly deploy` then times out waiting
   > for a machine that is already gone.

```bash
fly secrets set \
  GHCR_DOCKER_CONFIG_JSON="$(base64 < /tmp/ghcr-auth/config.json | tr -d '\n')" \
  --app copperline-daytona-runner
```

## Deploy + verify

```bash
cd runner/flyio/runner
fly deploy --app copperline-daytona-runner
fly status --app copperline-daytona-runner
```

For two always-on machines:

```bash
fly scale count 2 --app copperline-daytona-runner
fly status --app copperline-daytona-runner
```
