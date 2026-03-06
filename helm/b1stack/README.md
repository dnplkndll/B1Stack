# B1Stack Helm Chart

Deploys the full [ChurchApps B1Stack](https://b1.church) on Kubernetes.

| Component | Description | Default port |
|-----------|-------------|--------------|
| **api** | ChurchApps unified API (membership, attendance, giving, content, messaging, doing, reporting) | 8084 |
| **b1admin** | Staff dashboard — React SPA served by nginx | 80 |
| **b1app** | Public church website / member portal — Next.js SSR | 3301 |
| **lessonsapi** | Lessons curriculum API (optional) | 8090 |
| **askapi** | AI-powered Ask feature API (optional) | 8097 |
| **mysql** | Bitnami MySQL — bundled DB (optional, disable for managed DB) | 3306 |

## Quick Start

### Zero-override deploy (port-forward)

```bash
helm repo add bitnami https://charts.bitnami.com/bitnami
helm dep update helm/b1stack
helm upgrade --install b1stack helm/b1stack -n b1stack --create-namespace \
  --set mysql.image.registry=public.ecr.aws \
  --set mysql.image.repository=bitnami/mysql \
  --wait

# Access via port-forward
kubectl -n b1stack port-forward svc/b1stack-b1admin 3101:80
# Open http://localhost:3101
```

### With ingress (one flag)

```bash
helm upgrade --install b1stack helm/b1stack -n b1stack --create-namespace \
  --set global.baseDomain=church.example.com --wait
```

Hostnames are derived using dash separators for wildcard cert compatibility:
- `api-church.example.com` (API)
- `admin-church.example.com` (B1Admin)
- `church.example.com` (B1App)

All hostnames are subdomains of `example.com`, so a single `*.example.com` wildcard cert covers everything.

### Production

```bash
helm upgrade --install b1stack helm/b1stack -n b1stack \
  --set global.baseDomain=church.example.com \
  --set global.ingress.clusterIssuer=letsencrypt-prod \
  --set mysql.auth.rootPassword=<strong> \
  --set mysql.auth.password=<strong> \
  --set api.secrets.ENCRYPTION_KEY=<24chars> \
  --set api.secrets.JWT_SECRET=<secret>
```

## Demo Login

The initdb Job seeds a demo church on first install:

| Field | Value |
|-------|-------|
| Email | `demo@b1.church` |
| Password | `password` |
| Church | Grace Community Church |

## Configuration

### `global.baseDomain`

When set, all service hostnames and ingress resources are auto-derived:

| Service | Hostname pattern |
|---------|-----------------|
| api | `api-{baseDomain}` |
| b1admin | `admin-{baseDomain}` |
| b1app | `{baseDomain}` |
| lessonsapi | `lessons-api-{baseDomain}` |
| askapi | `ask-api-{baseDomain}` |

Per-service `ingress.hostname` still overrides if explicitly set.

When empty (default): no ingress resources created — use port-forward.

### `global.ingress`

| Key | Default | Description |
|-----|---------|-------------|
| `className` | `nginx` | Ingress controller class (`nginx`, `gce`, `alb`) |
| `tls` | `false` | Enable TLS on all ingresses |
| `clusterIssuer` | `""` | cert-manager ClusterIssuer (auto-added to annotations) |
| `annotations` | `{}` | Annotations applied to all ingresses |

### Auto-generated secrets

`ENCRYPTION_KEY` and `JWT_SECRET` are auto-generated when empty. The chart uses Helm `lookup` to persist values across upgrades. On fresh install, `randAlphaNum` generates new values.

> **Note:** `helm template` (offline) always generates new randoms since `lookup` returns empty. Only live `helm install/upgrade` persists secrets.

### External database

```yaml
mysql:
  enabled: false
api:
  secrets:
    MEMBERSHIP_CONNECTION_STRING: "mysql://user:pass@host:3306/membership"
    # ... remaining 6 connection strings
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

### TLS with cert-manager

```bash
--set global.ingress.clusterIssuer=letsencrypt-prod
```

Or per-service annotations for AWS ACM, GCP managed certs, etc. — see inline comments in `values.yaml`.

## Known Limitations

- **WebSocket (port 8087)**: Not exposed via Ingress. Requires TCP ConfigMap on ingress-nginx or NLB passthrough. Messaging degrades gracefully without it.
- **B1Admin bake-time URLs**: `REACT_APP_*` API URLs are baked into the JS bundle at Vite build time. The pre-built GHCR images target the `b1-test` environment. For other environments, rebuild the images with `--build-arg` to set the correct API URLs.
- **Secrets**: Stored in K8s Secrets (base64). Use [External Secrets Operator](https://external-secrets.io) for production.
- **`helm template` secrets**: Auto-generated secrets change on every `helm template` run (no cluster to `lookup`). This is expected — only live deploys are stable.
