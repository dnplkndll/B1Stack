# B1Stack Helm Chart

Deploys the full [ChurchApps B1Stack](https://b1.church) on Kubernetes:

| Component | Description | Default port |
|-----------|-------------|--------------|
| **api** | ChurchApps unified API (membership, attendance, giving, content, messaging, doing, reporting) | 8084 |
| **b1admin** | Staff dashboard — React SPA served by nginx | 80 |
| **b1app** | Public church website / member portal — Next.js SSR | 3301 |
| **lessonsapi** | Lessons curriculum API (optional) | 8090 |
| **askapi** | AI-powered Ask feature API (optional) | 8097 |
| **mysql** | Bitnami MySQL — bundled DB (optional, disable for managed DB) | 3306 |

---

## Prerequisites

- Kubernetes ≥ 1.24
- Helm 3
- An ingress controller (nginx-ingress, GKE Ingress, AWS ALB — see [Ingress](#ingress))
- cert-manager (if using TLS — see [TLS](#tls))
- metrics-server (if enabling HPA)

## Quick start

```bash
# 1. Add Bitnami repo and fetch dependencies
helm repo add bitnami https://charts.bitnami.com/bitnami
helm dep update helm/b1stack

# 2. Dry-run to verify templates render
helm template b1stack helm/b1stack \
  -f helm/b1stack/values.yaml \
  -f helm/b1stack/values.b1-test.yaml \
  --set mysql.auth.rootPassword=test \
  --set mysql.auth.password=test \
  --set api.secrets.ENCRYPTION_KEY=changeme \
  --set api.secrets.JWT_SECRET=changeme

# 3. Deploy
kubectl create namespace b1-test --dry-run=client -o yaml | kubectl apply -f -

helm upgrade --install b1stack helm/b1stack \
  --kube-context hetzner-ledo --namespace b1-test \
  -f helm/b1stack/values.yaml \
  -f helm/b1stack/values.b1-test.yaml \
  --set mysql.auth.rootPassword=<ROOT_PW> \
  --set mysql.auth.password=<APP_PW> \
  --set api.secrets.ENCRYPTION_KEY=<24_CHAR_KEY> \
  --set api.secrets.JWT_SECRET=<SECRET> \
  --set "api.secrets.MEMBERSHIP_CONNECTION_STRING=mysql://b1stack:<APP_PW>@b1stack-mysql:3306/membership" \
  --set "api.secrets.ATTENDANCE_CONNECTION_STRING=mysql://b1stack:<APP_PW>@b1stack-mysql:3306/attendance" \
  --set "api.secrets.CONTENT_CONNECTION_STRING=mysql://b1stack:<APP_PW>@b1stack-mysql:3306/content" \
  --set "api.secrets.GIVING_CONNECTION_STRING=mysql://b1stack:<APP_PW>@b1stack-mysql:3306/giving" \
  --set "api.secrets.MESSAGING_CONNECTION_STRING=mysql://b1stack:<APP_PW>@b1stack-mysql:3306/messaging" \
  --set "api.secrets.DOING_CONNECTION_STRING=mysql://b1stack:<APP_PW>@b1stack-mysql:3306/doing" \
  --set "api.secrets.REPORTING_CONNECTION_STRING=mysql://b1stack:<APP_PW>@b1stack-mysql:3306/reporting" \
  --wait --timeout 10m

# 4. First deploy only — run database migrations
kubectl --context hetzner-ledo -n b1-test exec -it \
  $(kubectl --context hetzner-ledo -n b1-test get pod -l app=b1stack-api \
    -o jsonpath='{.items[0].metadata.name}') \
  -- npm run initdb
```

---

## Values reference

### Global

| Key | Default | Description |
|-----|---------|-------------|
| `global.imageRegistry` | `""` (Docker Hub) | Override to pull from a custom registry / pull-through cache. Leave empty for Docker Hub. Note: `registry.bitnami.com` is a commercial registry — not suitable here. |
| `global.imagePullSecrets` | `[]` | Secrets added to every pod's `imagePullSecrets` |
| `global.storageClass` | `""` | Storage class for MySQL PVC. Empty = cluster default (`gp2` on EKS, `standard` on GKE, `hcloud-volumes` on Hetzner). |

### Per-service keys (api / b1admin / b1app / lessonsapi / askapi)

| Key | Description |
|-----|-------------|
| `<svc>.enabled` | Enable/disable the component |
| `<svc>.replicaCount` | Pod count (ignored when `autoscaling.enabled=true`) |
| `<svc>.image.repository/tag/pullPolicy` | Container image |
| `<svc>.service.type/port` | Kubernetes Service |
| `<svc>.ingress.enabled` | Create an Ingress resource |
| `<svc>.ingress.className` | Ingress controller class — `nginx` (default), `gce` (GKE), `alb` (EKS) |
| `<svc>.ingress.hostname` | FQDN |
| `<svc>.ingress.tls` | Enable TLS + create Secret |
| `<svc>.ingress.annotations` | Arbitrary ingress annotations (cert-manager, timeouts, etc.) |
| `<svc>.resources` | CPU/memory requests and limits |
| `<svc>.env` | Non-secret environment variables (go into a ConfigMap) |
| `<svc>.secrets` | Secret environment variables (go into a Kubernetes Secret — use ExternalSecrets in production) |
| `<svc>.podAnnotations` | Pod-level annotations (Prometheus scrape, Datadog, Linkerd, etc.) |
| `<svc>.imagePullSecrets` | Per-service pull secrets |
| `<svc>.nodeSelector` | Node selector labels |
| `<svc>.tolerations` | Pod tolerations |
| `<svc>.affinity` | Pod affinity / anti-affinity rules |
| `<svc>.autoscaling.*` | HPA settings (requires metrics-server) |

### API environment variables

**Required secrets** (must be set at deploy time):

| Variable | Description |
|----------|-------------|
| `ENCRYPTION_KEY` | AES encryption key (min 24 chars) |
| `JWT_SECRET` | JWT signing secret |
| `MEMBERSHIP_CONNECTION_STRING` | `mysql://user:pass@host:3306/membership` |
| `ATTENDANCE_CONNECTION_STRING` | — |
| `CONTENT_CONNECTION_STRING` | — |
| `GIVING_CONNECTION_STRING` | — |
| `MESSAGING_CONNECTION_STRING` | — |
| `DOING_CONNECTION_STRING` | — |
| `REPORTING_CONNECTION_STRING` | — |

**Optional env (set in `api.env`):**

| Variable | Default | Description |
|----------|---------|-------------|
| `ENVIRONMENT` | `production` | `dev` / `staging` / `prod` — selects `config/<env>.json` defaults |
| `CORS_ORIGIN` | `*` | Restrict to your domains in production |
| `FILE_STORE` | `disk` | `disk` (ephemeral) or `S3` |
| `DELIVERY_PROVIDER` | `local` | `local` or `aws` |
| `CONTENT_ROOT` | | Public base URL for uploaded files (required with `FILE_STORE=S3`) |
| `MAIL_SYSTEM` | | `SES` to enable email via AWS SES, empty to disable |
| `EMAIL_ON_REGISTRATION` | `false` | Send welcome email on signup |
| `SUPPORT_EMAIL` | | From address for system emails |
| `B1ADMIN_ROOT` | | URL of the admin dashboard (used in email links) |
| `AI_PROVIDER` | `openrouter` | `openai` or `openrouter` |

**Optional secrets (set in `api.secrets`):**

| Variable | Description |
|----------|-------------|
| `AWS_S3_BUCKET` | S3 bucket name (when `FILE_STORE=S3`) |
| `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY` / `AWS_REGION` | S3 credentials |
| `OPENAI_API_KEY` | OpenAI (when `AI_PROVIDER=openai`) |
| `OPENROUTER_API_KEY` | OpenRouter (when `AI_PROVIDER=openrouter`) |
| `YOUTUBE_API_KEY` | YouTube video search in content editor |
| `PEXELS_KEY` | Pexels stock photo search |
| `VIMEO_TOKEN` | Vimeo video integration |
| `API_BIBLE_KEY` | Bible text via API.Bible |
| `YOUVERSION_API_KEY` | YouVersion Bible integration |
| `PRAISECHARTS_CONSUMER_KEY` / `_SECRET` | PraiseCharts sheet music |
| `GOOGLE_RECAPTCHA_SECRET_KEY` | reCAPTCHA for giving forms |
| `HUBSPOT_KEY` | HubSpot CRM integration |
| `DOING_MEMBERSHIP_CONNECTION_STRING` | Separate Membership DB connection for the Doing module |

> **Note:** ChurchApps uses its own membership/auth system. There is no built-in Google, Apple, or Facebook OAuth at the API level. Social login would require upstream ChurchApps changes or a custom OAuth proxy.

---

## Ingress

The `ingressClassName` defaults to `nginx`. Override per environment:

```yaml
# GKE with GKE Ingress
api:
  ingress:
    className: gce
    annotations:
      kubernetes.io/ingress.allow-http: "false"

# EKS with AWS Load Balancer Controller
api:
  ingress:
    className: alb
    annotations:
      alb.ingress.kubernetes.io/scheme: internet-facing
      alb.ingress.kubernetes.io/target-type: ip
      alb.ingress.kubernetes.io/certificate-arn: arn:aws:acm:...
```

---

## TLS

cert-manager (recommended):
```yaml
api:
  ingress:
    tls: true
    annotations:
      cert-manager.io/cluster-issuer: letsencrypt-prod
```

AWS ACM (no cert-manager needed — annotate the ALB):
```yaml
api:
  ingress:
    tls: false   # ACM terminates at ALB, not at the pod
    className: alb
    annotations:
      alb.ingress.kubernetes.io/certificate-arn: arn:aws:acm:us-east-1:123456789:certificate/...
      alb.ingress.kubernetes.io/listen-ports: '[{"HTTP": 80}, {"HTTPS": 443}]'
      alb.ingress.kubernetes.io/ssl-redirect: "443"
```

GCP Cloud Armor / managed certs:
```yaml
api:
  ingress:
    tls: true
    className: gce
    annotations:
      networking.gke.io/managed-certificates: b1stack-api-cert
```

---

## External database (no bundled MySQL)

To use Cloud SQL, RDS, PlanetScale, or any external MySQL:

```yaml
# values.yaml overlay
mysql:
  enabled: false

api:
  secrets:
    MEMBERSHIP_CONNECTION_STRING: "mysql://user:pass@your-db-host:3306/membership"
    # ... remaining 6 connection strings
```

No `helm dep update` needed when `mysql.enabled: false` — the dependency is simply not rendered.

---

## File storage (S3 / GCS)

For persistent file uploads across pods:

```yaml
api:
  env:
    FILE_STORE: S3
    DELIVERY_PROVIDER: aws
    CONTENT_ROOT: "https://your-bucket.s3.amazonaws.com/"
  secrets:
    AWS_S3_BUCKET: your-bucket-name
    AWS_ACCESS_KEY_ID: AKIA...
    AWS_SECRET_ACCESS_KEY: ...
    AWS_REGION: us-east-1
```

GCS via S3-compatible endpoint:
```yaml
api:
  env:
    FILE_STORE: S3
    DELIVERY_PROVIDER: aws
    CONTENT_ROOT: "https://storage.googleapis.com/your-bucket/"
  secrets:
    AWS_S3_BUCKET: your-gcs-bucket
    AWS_ACCESS_KEY_ID: <HMAC access key>
    AWS_SECRET_ACCESS_KEY: <HMAC secret>
    AWS_REGION: auto
    # Override S3 endpoint via additional env if supported upstream
```

---

## Node scheduling (multi-cloud node pools)

```yaml
# Pin API to a high-memory node pool on GKE
api:
  nodeSelector:
    cloud.google.com/gke-nodepool: highmem-pool
  tolerations:
    - key: dedicated
      operator: Equal
      value: highmem
      effect: NoSchedule

# Spread b1app replicas across zones
b1app:
  affinity:
    podAntiAffinity:
      preferredDuringSchedulingIgnoredDuringExecution:
        - weight: 100
          podAffinityTerm:
            labelSelector:
              matchLabels:
                app: b1stack-b1app
            topologyKey: topology.kubernetes.io/zone
```

---

## HPA (autoscaling)

Requires [metrics-server](https://github.com/kubernetes-sigs/metrics-server).

```yaml
api:
  autoscaling:
    enabled: true
    minReplicas: 2
    maxReplicas: 10
    targetCPUUtilizationPercentage: 60
    targetMemoryUtilizationPercentage: 80
    # Optional: tune scale-up/down stabilization
    behavior:
      scaleUp:
        stabilizationWindowSeconds: 60
      scaleDown:
        stabilizationWindowSeconds: 600
```

---

## Docker Hub rate limits

The Bitnami MySQL sub-chart pulls from Docker Hub by default. `global.imageRegistry` is empty by default — images come from Docker Hub.

To avoid Docker Hub rate limits in production, configure a pull-through cache at the cluster level:
- **k3s**: Add a containerd mirror in `/etc/rancher/k3s/registries.yaml`
- **EKS**: Use ECR pull-through cache
- **GKE**: Use Artifact Registry remote repositories

---

## Known limitations

- **WebSocket (port 8087)**: Not exposed via Ingress. Requires a TCP ConfigMap on ingress-nginx or an NLB passthrough on AWS. Messaging features work without it in most deployments (they degrade gracefully).
- **B1Admin images are env-specific**: `REACT_APP_*` API URLs are baked into the JS bundle by Vite at build time. The GHCR images point at `b1-test.hz.ledoweb.com`. To deploy to a different environment, rebuild the image with the appropriate `--build-arg` values.
- **Secrets management**: Secrets are stored in Kubernetes Secrets (base64, not encrypted at rest by default). For production, use [External Secrets Operator](https://external-secrets.io) with AWS Secrets Manager, GCP Secret Manager, or Vault.
