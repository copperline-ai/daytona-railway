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

```bash
fly secrets set \
  GHCR_DOCKER_CONFIG_JSON="$(cat /tmp/ghcr-auth/config.json)" \
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
