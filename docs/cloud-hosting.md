# B1Stack Cloud Hosting Guide

Self-hosted deployment options for ChurchApps B1 on major cloud providers.
Estimated costs are for a **10 concurrent-user** baseline (small/medium church, ~500-2,000 members).
See [Sizing](#sizing) for scaling to 50+ users.

---

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Sizing Reference](#sizing)
3. [Hetzner Cloud](#hetzner) -- cheapest; recommended starting point
4. [DigitalOcean](#digitalocean)
5. [AWS (EKS)](#aws)
6. [Google Cloud (GKE)](#gcp)
7. [Comparison Table](#comparison)
8. [Choosing a Provider](#choosing)
9. [Terraform](#terraform)

---

## Prerequisites <a name="prerequisites"></a>

### CLI tools (install once)

```bash
# Helm (required for all providers)
brew install helm           # macOS
# or: curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# kubectl (required for all providers)
brew install kubectl        # macOS
# or: curl -LO "https://dl.k8s.io/release/$(curl -Ls https://dl.k8s.io/release/stable.txt)/bin/$(uname -s | tr A-Z a-z)/$(uname -m)/kubectl" && chmod +x kubectl && sudo mv kubectl /usr/local/bin/

# Provider-specific CLIs (install only the one you need):

# Hetzner
brew install hcloud         # macOS
# or: https://github.com/hetznercloud/cli/releases

# DigitalOcean
brew install doctl          # macOS
doctl auth init             # paste your API token from cloud.digitalocean.com/account/api/tokens

# AWS
brew install awscli eksctl  # macOS
aws configure               # paste your access key + secret + region

# Google Cloud
brew install --cask google-cloud-sdk   # macOS
gcloud auth login && gcloud config set project YOUR_PROJECT_ID
```

### Shared setup (all providers)

After creating a cluster on any provider, these three steps are the same:

```bash
# 1. cert-manager (TLS certificate automation)
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/latest/download/cert-manager.yaml
kubectl -n cert-manager rollout status deployment cert-manager --timeout=90s

# 2. nginx ingress controller (skip for AWS ALB — see AWS section)
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
helm install ingress-nginx ingress-nginx/ingress-nginx --wait

# 3. ClusterIssuer for Let's Encrypt (enables auto-TLS on all ingresses)
kubectl apply -f - <<'EOF'
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
```

### B1Stack deploy command (all providers)

Once the cluster, ingress, and cert-manager are ready:

```bash
helm upgrade --install b1stack \
  oci://ghcr.io/dnplkndll/b1stack/charts/b1stack \
  --set global.baseDomain=church.YOUR_DOMAIN \
  --set global.ingress.clusterIssuer=letsencrypt-prod \
  --set mysql.auth.rootPassword="$(openssl rand -hex 16)" \
  --set mysql.auth.password="$(openssl rand -hex 16)" \
  --set api.secrets.ENCRYPTION_KEY="$(openssl rand -hex 32)" \
  --set api.secrets.JWT_SECRET="$(openssl rand -hex 32)" \
  --namespace b1stack --create-namespace \
  --wait --timeout 10m

# First deploy only: create tables + load demo data
kubectl -n b1stack exec deployment/b1stack-api -- npm run initdb
```

> Secrets are generated inline by `openssl rand` and passed via `--set`.
> They are stored in the Kubernetes Secret `b1stack-api-secrets` — not in shell history
> if you run this in a script. For production, use `existingSecret` with
> a sealed-secret, ESO, or Vault-injected Secret instead.

### DNS setup

Add a wildcard A record pointing to your cluster's load balancer IP:

```
*.YOUR_DOMAIN  A  <LB_IP>
```

> **Important**: `baseDomain` must include an app slug (e.g. `church.example.com`),
> NOT the bare wildcard level (`example.com`). The chart generates dash-prefixed
> hostnames (`api-church.example.com`, `admin-church.example.com`) that must fall
> under the `*.example.com` wildcard.

This gives you: `api-church.YOUR_DOMAIN`, `admin-church.YOUR_DOMAIN`, `church.YOUR_DOMAIN` (public site).

---

## Sizing Reference <a name="sizing"></a>

### Application resource footprint (per replica, steady-state)

| Service     | CPU req | Mem req | Notes                                  |
|-------------|---------|---------|----------------------------------------|
| api         | 100m    | 256Mi   | Node.js; CPU spikes on SSR/auth        |
| b1admin     | 50m     | 128Mi   | Nginx static -- nearly zero at idle    |
| b1app       | 100m    | 256Mi   | Next.js SSR; memory grows with traffic |
| mysql       | 250m    | 512Mi   | Buffer pool + connection overhead      |
| **Total**   | ~500m   | ~1.2Gi  | + OS/kubelet overhead ~300m/512Mi      |

### Concurrent user targets

| Users | API replicas | DB max_conn | Min node size           | Storage |
|-------|--------------|-------------|-------------------------|---------|
| 10    | 1            | 100         | 2 vCPU / 4 GB RAM       | 20 GB   |
| 50    | 2            | 100         | 4 vCPU / 8 GB RAM       | 50 GB   |
| 200   | 4            | 200         | 8 vCPU / 16 GB RAM (x2) | 100 GB  |
| 500+  | HPA          | managed DB  | dedicated DB node       | managed |

> **Validated**: 10-user baseline measured with k6 against 500-member dataset.
> Peak MySQL connections: 39 (of 100 max). API p(95) latency: 25ms. See [Load Testing](./load-testing.md).

### What drives load for a church

A typical 500-member church:
- 3 weekend services x ~150 concurrent checkins -> burst ~150 API calls/min Sunday morning
- 10 weekly events (mid-week, youth, small groups)
- Staff: 5-20 admin users daily in B1Admin
- Public site (B1App): low sustained, moderate burst around service times

A 5,000-member church (multiply above x10):
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
| **Total**             |                    | **~EUR12/mo**  |

> Pricing from hetzner.com/cloud as of early 2026. Verify at console.hetzner.cloud.

### Setup steps

```bash
# 1. Create server
hcloud server create \
  --name b1stack-node1 \
  --type cx22 \
  --image ubuntu-24.04 \
  --location nbg1 \
  --ssh-key YOUR_KEY_NAME

# 2. Install k3s
ssh root@<SERVER_IP> 'curl -sfL https://get.k3s.io | sh -'

# 3. Copy kubeconfig locally
scp root@<SERVER_IP>:/etc/rancher/k3s/k3s.yaml ~/.kube/b1stack-hetzner.yaml
sed -i '' "s/127.0.0.1/<SERVER_IP>/" ~/.kube/b1stack-hetzner.yaml
export KUBECONFIG=~/.kube/b1stack-hetzner.yaml

# 4. Install cert-manager + nginx ingress + ClusterIssuer (see Prerequisites above)

# 5. Add wildcard DNS: *.YOUR_DOMAIN -> SERVER_IP

# 6. Deploy B1Stack (see Prerequisites above)
```

### Scaling Hetzner
- Upgrade node: `hcloud server change-type b1stack-node1 --type cx32` (4 vCPU/8GB, ~EUR8/mo)
- Volume: resize online in console; no pod restart needed
- Multi-node: add workers and label them; update nodeSelector in values

### Teardown

```bash
hcloud server delete b1stack-node1
# Also delete volumes and floating IPs from the Hetzner console to stop billing
```

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
# 1. Create cluster
doctl kubernetes cluster create b1stack \
  --region nyc1 \
  --node-pool "name=default;size=s-2vcpu-4gb;count=1" \
  --wait

# Saves kubeconfig automatically
doctl kubernetes cluster kubeconfig save b1stack

# 2. Install cert-manager + nginx ingress + ClusterIssuer (see Prerequisites above)

# 3. Get the load balancer IP (created automatically by nginx ingress)
kubectl get svc ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}'

# 4. Add wildcard DNS: *.YOUR_DOMAIN -> LB_IP

# 5. Deploy B1Stack (see Prerequisites above)
```

### Managed DB option (50+ users)

```bash
doctl databases create b1stack-db --engine mysql --version 8 --size db-s-1vcpu-1gb --region nyc1

# Get connection string, then deploy with bundled MySQL disabled:
helm upgrade b1stack \
  oci://ghcr.io/dnplkndll/b1stack/charts/b1stack \
  --set mysql.enabled=false \
  --set api.secrets.MEMBERSHIP_CONNECTION_STRING="mysql://..." \
  # ... (all DB connection strings)
```

### Teardown

```bash
doctl kubernetes cluster delete b1stack --force
# LB and volumes are deleted automatically with the cluster
# If you created a managed DB: doctl databases delete <DB_ID>
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
> Consider a single EC2 VM with k3s for budget deployments (same as Hetzner approach, ~$15/mo).

### Setup steps

```bash
# 1. Create cluster (takes ~15 min)
eksctl create cluster \
  --name b1stack \
  --region us-east-1 \
  --nodegroup-name default \
  --node-type t3.medium \
  --nodes 1

# 2. Install cert-manager + ClusterIssuer (see Prerequisites above)

# 3. Install AWS Load Balancer Controller
#    This replaces nginx-ingress on AWS — it provisions ALB/NLB natively.
#    Full guide: https://docs.aws.amazon.com/eks/latest/userguide/aws-load-balancer-controller.html
#
#    Short version:
eksctl utils associate-iam-oidc-provider --cluster b1stack --approve
curl -o iam_policy.json https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.11/docs/install/iam_policy.json
aws iam create-policy --policy-name AWSLoadBalancerControllerIAMPolicy \
  --policy-document file://iam_policy.json
eksctl create iamserviceaccount \
  --cluster b1stack \
  --namespace kube-system \
  --name aws-load-balancer-controller \
  --attach-policy-arn arn:aws:iam::$(aws sts get-caller-identity --query Account --output text):policy/AWSLoadBalancerControllerIAMPolicy \
  --approve
helm repo add eks https://aws.github.io/eks-charts
helm repo update
helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=b1stack \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller

# 4. Get ALB DNS name after deploying B1Stack
kubectl -n b1stack get ingress -o jsonpath='{.items[0].status.loadBalancer.ingress[0].hostname}'

# 5. Add wildcard DNS CNAME: *.YOUR_DOMAIN -> ALB_DNS_NAME

# 6. Deploy B1Stack (use className=alb)
helm upgrade --install b1stack \
  oci://ghcr.io/dnplkndll/b1stack/charts/b1stack \
  --set global.baseDomain=church.YOUR_DOMAIN \
  --set global.ingress.className=alb \
  --set global.ingress.clusterIssuer=letsencrypt-prod \
  --set mysql.auth.rootPassword="$(openssl rand -hex 16)" \
  --set mysql.auth.password="$(openssl rand -hex 16)" \
  --set api.secrets.ENCRYPTION_KEY="$(openssl rand -hex 32)" \
  --set api.secrets.JWT_SECRET="$(openssl rand -hex 32)" \
  --set mysql.persistence.storageClass=gp2 \
  --namespace b1stack --create-namespace --wait --timeout 10m
```

### Managed DB option (RDS)

```bash
aws rds create-db-instance \
  --db-instance-identifier b1stack-mysql \
  --db-instance-class db.t3.micro \
  --engine mysql --engine-version "8.0" \
  --master-username b1stack \
  --master-user-password "$(openssl rand -hex 16)" \
  --allocated-storage 20

# Disable bundled MySQL and pass RDS endpoint:
helm upgrade b1stack \
  oci://ghcr.io/dnplkndll/b1stack/charts/b1stack \
  --set mysql.enabled=false \
  --set api.secrets.MEMBERSHIP_CONNECTION_STRING="mysql://b1stack:PW@RDS_ENDPOINT:3306/membership"
  # ... remaining connection strings
```

### Teardown

```bash
eksctl delete cluster --name b1stack --region us-east-1
# EBS volumes and ALB are deleted with the cluster
# If you created RDS: aws rds delete-db-instance --db-instance-identifier b1stack-mysql --skip-final-snapshot
rm -f iam_policy.json
```

---

## Google Cloud (GKE) <a name="gcp"></a>

**Best for**: Orgs on Google Workspace, needing Autopilot scaling, or YouTube/Drive integrations.

### Monthly cost estimate (10-user baseline)

| Resource                    | Spec              | Cost/mo (USD) |
|-----------------------------|-------------------|---------------|
| GKE Standard control plane  | Managed (free)    | $0            |
| e2-standard-2 node          | 2 vCPU / 8 GB     | ~49           |
| 20 GB SSD persistent disk   | pd-ssd             | ~3.40         |
| Cloud Load Balancer         | Regional HTTPS LB  | ~18           |
| **Total (Standard mode)**   |                   | **~$70/mo**   |

> GKE Standard has no control-plane fee. Autopilot charges per-pod instead.

### Setup steps

```bash
# 1. Create GKE Standard cluster (free control plane in us-central1)
gcloud container clusters create b1stack \
  --zone us-central1-a \
  --machine-type e2-standard-2 \
  --num-nodes 1 \
  --release-channel regular

gcloud container clusters get-credentials b1stack --zone us-central1-a

# 2. Install cert-manager + nginx ingress + ClusterIssuer (see Prerequisites above)

# 3. Get the load balancer IP
kubectl get svc ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}'

# 4. Add wildcard DNS: *.YOUR_DOMAIN -> LB_IP

# 5. Deploy B1Stack (see Prerequisites above)
#    Add: --set mysql.persistence.storageClass=standard-rwo
```

### Cloud SQL option (50+ users)

```bash
gcloud sql instances create b1stack-mysql \
  --database-version MYSQL_8_0 \
  --tier db-f1-micro \
  --region us-central1

# Use Cloud SQL Auth Proxy sidecar or Private IP with VPC-native cluster
```

### Teardown

```bash
gcloud container clusters delete b1stack --zone us-central1-a --quiet
# PD volumes are deleted with the cluster
# If you created Cloud SQL: gcloud sql instances delete b1stack-mysql --quiet
```

---

## Comparison Table <a name="comparison"></a>

| Provider      | 10-user cost/mo | Daily cost | Control plane fee | Managed DB | Complexity |
|---------------|-----------------|------------|-------------------|------------|------------|
| **Hetzner**   | ~EUR12 (~$13)   | ~$0.40     | None (k3s)        | Paid addon | Low        |
| **DO (DOKS)** | ~$38            | ~$1.25     | None              | $15+/mo    | Low        |
| **GCP (GKE)** | ~$70            | ~$2.30     | Free (Standard)   | $8+/mo     | Medium     |
| **AWS (EKS)** | ~$121           | ~$4.00     | $73/mo            | $15+/mo    | High       |

---

## Choosing a Provider <a name="choosing"></a>

**Pick Hetzner** if: you want the lowest cost and are comfortable with self-managed k3s.
Most suitable for churches with a technical volunteer or contractor.

**Pick DigitalOcean** if: you want managed Kubernetes without AWS complexity and are US-based.
Good middle ground for churches with a small IT budget.

**Pick GCP** if: the church already uses Google Workspace, or needs YouTube/Drive integration.
Standard mode has free control plane; Autopilot can auto-scale during off-peak.

**Pick AWS** if: the church is part of a larger organization already on AWS, needs compliance
certifications (HIPAA for counseling programs, etc.), or needs tight S3/SES integration.

### Production checklist (all providers)

- [ ] `mysql.enabled=false` -> use managed DB at 50+ users
- [ ] `FILE_STORE=S3` + configure S3-compatible bucket for media uploads
- [ ] `MAIL_SYSTEM=SES` (AWS SES) or SMTP relay for transactional email
- [ ] Backups: snapshot MySQL volume daily; test restore
- [ ] Monitoring: deploy kube-prometheus-stack; alert on pod restarts + DB connection count
- [ ] `global.ingress.clusterIssuer=letsencrypt-prod` (not staging)
- [ ] Use `existingSecret` with sealed-secrets or ESO for production secrets
- [ ] Run load tests (`load-tests/`) before launch -- see [Load Testing](./load-testing.md)

---

## Terraform <a name="terraform"></a>

One-command infrastructure provisioning is available in [`terraform/`](../terraform/).
Each provider directory creates a complete cluster with cert-manager, nginx-ingress,
and the B1Stack Helm release from the OCI registry.

```bash
cd terraform/<provider>    # do, gcp, or aws
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values

terraform init
terraform apply    # type "yes" to confirm

# When done:
terraform destroy
```

See [`terraform/README.md`](../terraform/README.md) for full details.

---

## Load Test Results <a name="load-tests"></a>

Validated on 2026-03-07 using `load-tests/scenarios/10-users.js` against a 500-member
church dataset (499 people, 199 households, 32 groups). Each test ran 5 minutes:
30s ramp to 10 concurrent users, 4min hold, 30s ramp down.

| Metric | DigitalOcean (NYC1) | GCP (us-central1) |
|--------|--------------------|--------------------|
| **Checks passed** | 100% (1,191/1,191) | 100% (1,228/1,228) |
| **HTTP failures** | 0% (0/976) | 0% (0/1,006) |
| **p50 latency** | 29.5 ms | 56.2 ms |
| **p90 latency** | 37.2 ms | 111.0 ms |
| **p95 latency** | 43.7 ms | 159.1 ms |
| **Max latency** | 324.3 ms | 306.3 ms |
| **Iterations** | 557 | 555 |
| **Node spec** | s-2vcpu-4gb ($24/mo) | e2-medium ($24/mo) |

> **Notes:**
> - All 13 check types passed (login, people list/search, groups, giving, attendance, etc.)
> - DO latency advantage (29ms vs 56ms median) is partly geographic — test client was US East.
> - Both clusters used bundled MySQL (single-pod StatefulSet, not managed DB).
> - AWS EKS was not load-tested due to EBS CSI IAM setup overhead; expect similar numbers
>   to GCP once running.
> - Chart deployed from `oci://ghcr.io/dnplkndll/b1stack/charts/b1stack:0.20260307.0`.
