# B1Stack Cloud Hosting Guide

Self-hosted deployment options for ChurchApps B1 on major cloud providers.
Estimated costs are for a **10 concurrent-user** baseline (small/medium church, ~500–2,000 members).
See [Sizing](#sizing) for scaling to 50+ users.

---

## Table of Contents

1. [Sizing Reference](#sizing)
2. [Hetzner Cloud](#hetzner) ← cheapest; recommended starting point
3. [DigitalOcean](#digitalocean)
4. [AWS (EKS)](#aws)
5. [Google Cloud (GKE)](#gcp)
6. [Comparison Table](#comparison)
7. [Choosing a Provider](#choosing)

---

## Sizing Reference <a name="sizing"></a>

### Application resource footprint (per replica, steady-state)

| Service     | CPU req | Mem req | Notes                                  |
|-------------|---------|---------|----------------------------------------|
| api         | 100m    | 256Mi   | Node.js; CPU spikes on SSR/auth        |
| b1admin     | 50m     | 128Mi   | Nginx static — nearly zero at idle     |
| b1app       | 100m    | 256Mi   | Next.js SSR; memory grows with traffic |
| mysql       | 250m    | 512Mi   | Buffer pool + connection overhead      |
| **Total**   | ~500m   | ~1.2Gi  | + OS/kubelet overhead ~300m/512Mi      |

### Concurrent user targets

| Users | API replicas | DB max_conn | Min node size           | Storage |
|-------|--------------|-------------|-------------------------|---------|
| 10    | 1            | 50          | 2 vCPU / 4 GB RAM       | 20 GB   |
| 50    | 2            | 100         | 4 vCPU / 8 GB RAM       | 50 GB   |
| 200   | 4            | 200         | 8 vCPU / 16 GB RAM (×2) | 100 GB  |
| 500+  | HPA          | managed DB  | dedicated DB node       | managed |

> **TODO after load testing**: Validate these numbers with k6 results from `load-tests/`.
> Actual API connection pool behaviour and Next.js memory growth need to be measured.

### What drives load for a church

A typical 500-member church:
- 3 weekend services × ~150 concurrent checkins → burst ~150 API calls/min Sunday morning
- 10 weekly events (mid-week, youth, small groups)
- Staff: 5–20 admin users daily in B1Admin
- Public site (B1App): low sustained, moderate burst around service times

A 5,000-member church (multiply above ×10):
- Sunday morning burst: ~1,500 check-ins, possible livestream/podcast traffic
- May need CDN (Cloudflare) in front of B1App, S3-compatible file storage
- Managed DB strongly recommended at this scale

---

## Hetzner Cloud <a name="hetzner"></a>

**Best for**: Budget-conscious churches, EU/German data residency, technical admins.

### Monthly cost estimate (10-user baseline)

| Resource              | Spec               | Cost/mo (EUR) |
|-----------------------|--------------------|---------------|
| CX22 node (k3s)       | 2 vCPU / 4 GB      | ~4.35         |
| 20 GB SSD volume      | Block storage       | ~0.96         |
| Load balancer LB11    | 1 service, 5 Mbps  | ~5.83         |
| Floating IP           | Static IP           | ~1.19         |
| **Total**             |                    | **~€12/mo**   |

> Pricing from hetzner.com/cloud as of early 2026. Verify at console.hetzner.cloud.

### Setup steps

```bash
# 1. Create server (or use Hetzner Cloud console)
hcloud server create \
  --name b1stack-node1 \
  --type cx22 \
  --image ubuntu-24.04 \
  --location nbg1 \
  --ssh-key YOUR_KEY_NAME

# 2. Install k3s
ssh root@<SERVER_IP>
curl -sfL https://get.k3s.io | sh -

# 3. Copy kubeconfig
scp root@<SERVER_IP>:/etc/rancher/k3s/k3s.yaml ~/.kube/b1stack-hetzner.yaml
# Edit server URL: replace 127.0.0.1 with SERVER_IP
export KUBECONFIG=~/.kube/b1stack-hetzner.yaml

# 4. Install cert-manager
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/latest/download/cert-manager.yaml

# 5. Install nginx ingress (k3s bundles Traefik — switch to nginx for B1Stack compat)
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm install ingress-nginx ingress-nginx/ingress-nginx

# 6. Create ClusterIssuer for Let's Encrypt
kubectl apply -f - <<EOF
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: YOUR_EMAIL
    privateKeySecretRef:
      name: letsencrypt-prod
    solvers:
      - http01:
          ingress:
            class: nginx
EOF

# 7. Add wildcard DNS A record: *.YOUR_DOMAIN → SERVER_IP

# 8. Deploy B1Stack
helm upgrade --install b1stack helm/b1stack \
  -f helm/b1stack/values.yaml \
  --set global.baseDomain=YOUR_DOMAIN \
  --set global.ingress.clusterIssuer=letsencrypt-prod \
  --set mysql.auth.rootPassword=STRONG_ROOT_PW \
  --set mysql.auth.password=STRONG_APP_PW \
  --set api.secrets.ENCRYPTION_KEY=$(openssl rand -hex 32) \
  --set api.secrets.JWT_SECRET=$(openssl rand -hex 32) \
  --namespace b1stack --create-namespace \
  --wait --timeout 10m

# 9. Run initdb (first deploy only)
kubectl exec -n b1stack deployment/b1stack-api -- npm run initdb
```

### Scaling Hetzner
- Upgrade node: `hcloud server rebuild` with a CX32 (4 vCPU/8GB, ~€8/mo) or CX42
- Volume: resize online in console; no pod restart needed
- Multi-node: add workers and label them; update nodeSelector in values

---

## DigitalOcean (DOKS) <a name="digitalocean"></a>

**Best for**: Teams wanting managed Kubernetes without AWS complexity.

### Monthly cost estimate (10-user baseline)

| Resource                       | Spec              | Cost/mo (USD) |
|-------------------------------|-------------------|---------------|
| DOKS cluster (1 node)         | s-2vcpu-4gb       | ~24           |
| 20 GB block volume            | Block storage      | ~2            |
| Load balancer                 | Auto-provisioned   | ~12           |
| **Total**                     |                   | **~$38/mo**   |

### Setup steps

```bash
# 1. Create cluster (or use DO console)
doctl kubernetes cluster create b1stack \
  --region nyc1 \
  --node-pool "name=default;size=s-2vcpu-4gb;count=1" \
  --wait

doctl kubernetes cluster kubeconfig save b1stack

# 2. Install cert-manager
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/latest/download/cert-manager.yaml

# 3. nginx-ingress (DO uses LoadBalancer type — auto-creates DO LB)
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm install ingress-nginx ingress-nginx/ingress-nginx

# 4. Get LB IP, add wildcard DNS A record: *.YOUR_DOMAIN → LB_IP

# 5. Deploy B1Stack (same helm command as Hetzner above)
helm upgrade --install b1stack helm/b1stack \
  -f helm/b1stack/values.yaml \
  --set global.baseDomain=YOUR_DOMAIN \
  --set global.ingress.clusterIssuer=letsencrypt-prod \
  --set mysql.auth.rootPassword=STRONG_ROOT_PW \
  --set mysql.auth.password=STRONG_APP_PW \
  --set api.secrets.ENCRYPTION_KEY=$(openssl rand -hex 32) \
  --set api.secrets.JWT_SECRET=$(openssl rand -hex 32) \
  --namespace b1stack --create-namespace --wait --timeout 10m
```

### Managed DB option (50+ users)
Replace bundled MySQL with DO Managed MySQL:
```bash
# Create managed DB
doctl databases create b1stack-db --engine mysql --version 8 --size db-s-1vcpu-1gb --region nyc1

# Get connection string and pass to chart
helm upgrade b1stack helm/b1stack \
  --set mysql.enabled=false \
  --set api.secrets.MEMBERSHIP_CONNECTION_STRING="mysql://..." \
  # ... (all DB connection strings)
```

---

## AWS (EKS) <a name="aws"></a>

**Best for**: Orgs already on AWS, needing compliance (SOC2, HIPAA path), or large scale.

### Monthly cost estimate (10-user baseline)

| Resource              | Spec                     | Cost/mo (USD) |
|-----------------------|--------------------------|---------------|
| EKS control plane     | Managed                  | ~73           |
| EC2 node (t3.medium)  | 2 vCPU / 4 GB            | ~30           |
| EBS volume 20 GB      | gp3 SSD                  | ~1.60         |
| ALB                   | Auto-provisioned          | ~16           |
| **Total**             |                          | **~$121/mo**  |

> EKS control plane cost alone ($73) makes it expensive for small churches.
> Consider EKS Fargate or a single EC2 VM with k3s for small deployments.

### Setup steps

```bash
# Prerequisites: aws CLI, eksctl, kubectl

# 1. Create cluster
eksctl create cluster \
  --name b1stack \
  --region us-east-1 \
  --nodegroup-name default \
  --node-type t3.medium \
  --nodes 1

# 2. Install cert-manager
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/latest/download/cert-manager.yaml

# 3. Install AWS Load Balancer Controller (required for ALB ingress)
# See: https://docs.aws.amazon.com/eks/latest/userguide/aws-load-balancer-controller.html
# Then set global.ingress.className=alb in values

# 4. Deploy
helm upgrade --install b1stack helm/b1stack \
  -f helm/b1stack/values.yaml \
  --set global.baseDomain=YOUR_DOMAIN \
  --set global.ingress.className=alb \
  --set global.ingress.clusterIssuer=letsencrypt-prod \
  --set mysql.auth.rootPassword=STRONG_ROOT_PW \
  --set mysql.auth.password=STRONG_APP_PW \
  --set api.secrets.ENCRYPTION_KEY=$(openssl rand -hex 32) \
  --set api.secrets.JWT_SECRET=$(openssl rand -hex 32) \
  --set mysql.persistence.storageClass=gp2 \
  --namespace b1stack --create-namespace --wait --timeout 10m
```

### Managed DB option (RDS)
```bash
# Create RDS MySQL 8.0 instance (db.t3.micro = ~$15/mo)
aws rds create-db-instance \
  --db-instance-identifier b1stack-mysql \
  --db-instance-class db.t3.micro \
  --engine mysql \
  --engine-version "8.0" \
  --master-username b1stack \
  --master-user-password STRONG_PW \
  --allocated-storage 20

# Disable bundled MySQL
helm upgrade b1stack helm/b1stack \
  --set mysql.enabled=false \
  --set api.secrets.MEMBERSHIP_CONNECTION_STRING="mysql://b1stack:PW@RDS_ENDPOINT:3306/membership"
  # ... remaining connection strings
```

---

## Google Cloud (GKE) <a name="gcp"></a>

**Best for**: Orgs on Google Workspace, needing Autopilot scaling, or YouTube/Drive integrations.

### Monthly cost estimate (10-user baseline)

| Resource                    | Spec              | Cost/mo (USD) |
|-----------------------------|-------------------|---------------|
| GKE Autopilot (always-on)   | Managed control   | ~73 (standard mode ~0) |
| e2-standard-2 node          | 2 vCPU / 8 GB     | ~49           |
| 20 GB SSD persistent disk   | pd-ssd             | ~3.40         |
| Cloud Load Balancer         | Global HTTPS LB    | ~18           |
| **Total (Standard mode)**   |                   | **~$70/mo**   |

> GKE Standard has no control-plane fee in some regions. Autopilot is per-pod billing.

### Setup steps

```bash
# Prerequisites: gcloud CLI, kubectl

# 1. Create GKE Standard cluster (free control plane in us-central1)
gcloud container clusters create b1stack \
  --zone us-central1-a \
  --machine-type e2-standard-2 \
  --num-nodes 1 \
  --release-channel regular

gcloud container clusters get-credentials b1stack --zone us-central1-a

# 2. Install cert-manager
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/latest/download/cert-manager.yaml

# 3. Install nginx ingress (or use GCE ingress with className=gce)
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm install ingress-nginx ingress-nginx/ingress-nginx

# 4. Deploy
helm upgrade --install b1stack helm/b1stack \
  -f helm/b1stack/values.yaml \
  --set global.baseDomain=YOUR_DOMAIN \
  --set global.ingress.clusterIssuer=letsencrypt-prod \
  --set mysql.auth.rootPassword=STRONG_ROOT_PW \
  --set mysql.auth.password=STRONG_APP_PW \
  --set api.secrets.ENCRYPTION_KEY=$(openssl rand -hex 32) \
  --set api.secrets.JWT_SECRET=$(openssl rand -hex 32) \
  --set mysql.persistence.storageClass=standard-rwo \
  --namespace b1stack --create-namespace --wait --timeout 10m
```

### Cloud SQL option (50+ users)
```bash
# Create Cloud SQL MySQL 8.0 instance (db-f1-micro ~$8/mo)
gcloud sql instances create b1stack-mysql \
  --database-version MYSQL_8_0 \
  --tier db-f1-micro \
  --region us-central1

# Use Cloud SQL Auth Proxy sidecar or Private IP with VPC-native cluster
```

---

## Comparison Table <a name="comparison"></a>

| Provider      | 10-user cost/mo | 50-user cost/mo | Control plane fee | Managed DB | Complexity |
|---------------|-----------------|-----------------|-------------------|------------|------------|
| **Hetzner**   | ~€12 (~$13)     | ~€20 (~$22)     | None (k3s)        | Paid addon | Low        |
| **DO (DOKS)** | ~$38            | ~$65            | None              | $15+/mo    | Low        |
| **GCP (GKE)** | ~$70            | ~$130           | Free (Standard)   | $8+/mo     | Medium     |
| **AWS (EKS)** | ~$121           | ~$200           | $73/mo            | $15+/mo    | High       |

---

## Choosing a Provider <a name="choosing"></a>

**Pick Hetzner** if: you want the lowest cost and are comfortable with self-managed k3s.
Most suitable for churches with a technical volunteer or contractor.

**Pick DigitalOcean** if: you want managed Kubernetes without AWS complexity and are US-based.
Good middle ground for churches with a small IT budget.

**Pick GCP** if: the church already uses Google Workspace, or needs YouTube/Drive integration.
Autopilot mode can auto-scale to zero during off-peak.

**Pick AWS** if: the church is part of a larger organization already on AWS, needs compliance
certifications (HIPAA for counseling programs, etc.), or needs tight S3/SES integration.

### Production checklist (all providers)

- [ ] `mysql.enabled=false` → use managed DB at 50+ users
- [ ] `FILE_STORE=S3` + configure S3-compatible bucket for media uploads
- [ ] `MAIL_SYSTEM=SES` (AWS SES) or SMTP relay for transactional email
- [ ] Backups: snapshot MySQL volume daily; test restore
- [ ] Monitoring: deploy kube-prometheus-stack; alert on pod restarts + DB connection count
- [ ] `global.ingress.clusterIssuer=letsencrypt-prod` (not staging)
- [ ] Rotate `ENCRYPTION_KEY` and `JWT_SECRET` from defaults
- [ ] Run load tests (`load-tests/`) before launch — see [Load Testing](./load-testing.md)
