# B1Stack Helm Chart

Deploys the full [ChurchApps B1Stack](https://b1.church) on Kubernetes. No sub-chart dependencies — uses the official `mysql:8.0` image directly.

| Component | Description | Port |
|-----------|-------------|------|
| **api** | ChurchApps unified API (membership, attendance, giving, content, messaging, doing, reporting) | 8084 |
| **b1admin** | Staff dashboard — React SPA served by nginx | 80 |
| **b1app** | Public church website / member portal — Next.js SSR | 3301 |
| **mysql** | MySQL 8.0 StatefulSet — bundled DB (disable for managed DB) | 3306 |
| **lessonsapi** | Lessons curriculum API (optional, disabled by default) | 8090 |
| **askapi** | AI-powered Ask feature API (optional, disabled by default) | 8097 |

## Quick Start

### Port-forward only (no domain)

```bash
helm upgrade --install b1stack helm/b1stack -n b1stack --create-namespace --wait
kubectl -n b1stack port-forward svc/b1stack-b1admin 3101:80
# Open http://localhost:3101 → demo@b1.church / password
```

### With ingress (one flag)

```bash
helm upgrade --install b1stack helm/b1stack -n b1stack --create-namespace \
  --set global.baseDomain=church.example.com --wait
```

### Production (ingress + TLS + strong secrets)

```bash
helm upgrade --install b1stack helm/b1stack -n b1stack --create-namespace \
  --set global.baseDomain=church.example.com \
  --set global.ingress.clusterIssuer=letsencrypt-prod \
  --set mysql.auth.rootPassword=<strong> \
  --set mysql.auth.password=<strong> \
  --set api.secrets.ENCRYPTION_KEY=<24chars> \
  --set api.secrets.JWT_SECRET=<secret> --wait
```

Hostnames use dash separators for wildcard cert compatibility:

| Service | Hostname |
|---------|---------|
| api | `api-{baseDomain}` |
| b1admin | `admin-{baseDomain}` |
| b1app | `{baseDomain}` |
| lessonsapi | `lessons-api-{baseDomain}` |
| askapi | `ask-api-{baseDomain}` |

A single `*.example.com` wildcard cert covers all services.

## Demo Login

| Field | Value |
|-------|-------|
| Email | `demo@b1.church` |
| Password | `password` |
| Church | Grace Community Church |

## Configuration

### `global.baseDomain`

When set, all ingress resources are auto-derived from this domain. When empty (default), no ingress is created — use port-forward.

### `global.ingress`

| Key | Default | Description |
|-----|---------|-------------|
| `className` | `nginx` | Ingress controller class (`nginx`, `gce`, `alb`) |
| `tls` | `false` | Enable TLS (auto-enabled when `clusterIssuer` is set) |
| `clusterIssuer` | `""` | cert-manager ClusterIssuer (auto-added to annotations) |
| `annotations` | `{}` | Annotations applied to all ingresses |

### Auto-generated secrets

`ENCRYPTION_KEY` and `JWT_SECRET` are auto-generated when empty. The chart uses Helm `lookup` to persist values across upgrades.

> `helm template` (offline) always generates new randoms — only live `helm install/upgrade` persists secrets via `lookup`.

### External database

```yaml
mysql:
  enabled: false
api:
  secrets:
    MEMBERSHIP_CONNECTION_STRING: "mysql://user:pass@host:3306/membership"
    ATTENDANCE_CONNECTION_STRING: "mysql://user:pass@host:3306/attendance"
    CONTENT_CONNECTION_STRING: "mysql://user:pass@host:3306/content"
    GIVING_CONNECTION_STRING: "mysql://user:pass@host:3306/giving"
    MESSAGING_CONNECTION_STRING: "mysql://user:pass@host:3306/messaging"
    DOING_CONNECTION_STRING: "mysql://user:pass@host:3306/doing"
    REPORTING_CONNECTION_STRING: "mysql://user:pass@host:3306/reporting"
```

### File storage (S3)

```yaml
api:
  env:
    FILE_STORE: S3
    DELIVERY_PROVIDER: aws
    CONTENT_ROOT: "https://your-bucket.s3.amazonaws.com/"
  secrets:
    AWS_S3_BUCKET: your-bucket
    AWS_ACCESS_KEY_ID: AKIA...
    AWS_SECRET_ACCESS_KEY: ...
    AWS_REGION: us-east-1
```

## Known Limitations

- **WebSocket (port 8087)**: Not exposed via Ingress. Requires TCP ConfigMap on ingress-nginx or NLB passthrough. Messaging degrades gracefully without it.
- **B1Admin bake-time URLs**: `REACT_APP_*` API URLs are baked into the JS bundle at Vite build time. Pre-built GHCR images target the `b1-test` environment. Rebuild images with correct API URLs for other environments.
- **Secrets**: Stored in K8s Secrets (base64). Use [External Secrets Operator](https://external-secrets.io) for production vaults.
