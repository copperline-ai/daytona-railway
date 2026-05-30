# Daytona Docker Registry (Fly.io)

The internal Docker registry that Daytona's runner pushes snapshot images to and
pulls them from. It runs as its own Fly.io app rather than on Railway because the
Fly runner cannot reach Railway's private network (`*.railway.internal`).

- **Image:** `registry:2.8.3`
- **App:** `copperline-daytona-registry` → `https://copperline-daytona-registry.fly.dev`
- **Storage:** S3 driver pointed at the Railway MinIO public endpoint
  (`minio-production-3b7b.up.railway.app`, bucket `daytona`, prefix `/registry`) —
  the registry itself is stateless (no Fly volume).
- **Auth:** htpasswd basic auth over HTTPS. Required for **all** operations
  (pull and push); there is no anonymous access. `force_https` redirects HTTP→HTTPS.

## Files

| File | Purpose | In git? |
|------|---------|---------|
| `Dockerfile` | `FROM registry:2.8.3` + copies `config.yml` and `htpasswd` | yes |
| `config.yml` | registry config: S3 storage, htpasswd auth, port 5000 | yes |
| `fly.toml` | Fly app config (always-on, internal port 5000) | yes |
| `htpasswd` | bcrypt hash of the registry password | **no (.gitignore)** |
| `.registry-creds.env` | plaintext `REGISTRY_USER` / `REGISTRY_PASS` for wiring the DB + API | **no (.gitignore)** |

The S3 access/secret keys are **not** in any file — they are set as Fly secrets
(`REGISTRY_STORAGE_S3_ACCESSKEY` / `REGISTRY_STORAGE_S3_SECRETKEY`), which `config.yml`
inherits via the registry's env-override mechanism.

## First-time setup

Prerequisites: `flyctl` authenticated to the `copperline-ai` org, and Python with
`bcrypt` (`pip install --user bcrypt`) to generate the htpasswd hash.

```bash
cd registry

# 1. Generate registry credentials + bcrypt htpasswd (writes htpasswd + .registry-creds.env)
python3 - <<'PY'
import secrets, bcrypt, pathlib
user = "daytona"
pw   = secrets.token_urlsafe(24)
h    = bcrypt.hashpw(pw.encode(), bcrypt.gensalt(rounds=10)).decode()
pathlib.Path("htpasswd").write_text(f"{user}:{h}\n")
pathlib.Path(".registry-creds.env").write_text(f"REGISTRY_USER={user}\nREGISTRY_PASS={pw}\n")
print("user:", user, "\npass:", pw)
PY

# 2. Create the Fly app
fly apps create copperline-daytona-registry --org copperline-ai

# 3. Set the S3 (MinIO) credentials as Fly secrets — use the MinIO root user/password.
#    (MinIO must have a public domain on its S3 port 9000 for this to be reachable.)
fly secrets set --stage \
  REGISTRY_STORAGE_S3_ACCESSKEY="<MINIO_ROOT_USER>" \
  REGISTRY_STORAGE_S3_SECRETKEY="<MINIO_ROOT_PASSWORD>" \
  --app copperline-daytona-registry

# 4. Deploy
fly deploy --app copperline-daytona-registry --ha=false
```

If MinIO's public S3 endpoint changes, update `regionendpoint` in `config.yml` and redeploy.

## Wire Daytona to use it

The registry alone is not enough — Daytona must be told to use it, in **two** places
(it does not auto-sync from env after first boot). Replace `<USER>`/`<PASS>` with the
values from `.registry-creds.env`.

**1. Postgres `docker_registry` table** — point the `internal`, `transient`, and
`backup` rows at the registry. The `url` must be a **bare host** (no scheme):

```sql
UPDATE docker_registry
SET url='copperline-daytona-registry.fly.dev', username='<USER>', password='<PASS>', "updatedAt"=now()
WHERE "registryType" IN ('internal','transient','backup');
```

**2. Railway `daytona` API env vars** (setting these triggers a redeploy):

```
INTERNAL_REGISTRY_URL=https://copperline-daytona-registry.fly.dev
INTERNAL_REGISTRY_ADMIN=<USER>
INTERNAL_REGISTRY_PASSWORD=<PASS>
TRANSIENT_REGISTRY_URL=https://copperline-daytona-registry.fly.dev
TRANSIENT_REGISTRY_ADMIN=<USER>
TRANSIENT_REGISTRY_PASSWORD=<PASS>
```

> Any `snapshot` row created while the registry was misconfigured stores a stale
> `ref` and sits in `state='error'`; the API won't retry it. Reset such rows with
> `UPDATE snapshot SET ref='copperline-daytona-registry.fly.dev/daytona/<image>', state='pending', "errorReason"=NULL`.

## Verify

```bash
REG=https://copperline-daytona-registry.fly.dev
curl -s -o /dev/null -w '%{http_code}\n' $REG/v2/                                   # 401 (auth enforced)
curl -s -o /dev/null -w '%{http_code}\n' -u "$USER:$PASS" $REG/v2/                  # 200
curl -s -u "$USER:$PASS" $REG/v2/_catalog                                           # lists pushed snapshot images
```

## Rotate the registry password

1. Regenerate `htpasswd` (step 1 above) and `fly deploy`.
2. Update the `docker_registry` rows and the API env vars (both sections above) with the new password.

## Rotate the S3 (MinIO) credentials

```bash
fly secrets set \
  REGISTRY_STORAGE_S3_ACCESSKEY="<new>" \
  REGISTRY_STORAGE_S3_SECRETKEY="<new>" \
  --app copperline-daytona-registry   # auto-redeploys
```

## Operations

```bash
fly status  --app copperline-daytona-registry
fly logs    --app copperline-daytona-registry
fly deploy  --app copperline-daytona-registry --ha=false
```
