# B1Stack

Docker Compose and Helm orchestration for the [ChurchApps](https://b1.church) B1 product suite — run the full stack locally in minutes.

Follows the B1 naming convention: B1Admin, B1App, B1Checkin, B1Mobile… **B1Stack**.

## Services

| Service      | Port  | Description                                      |
|-------------|-------|--------------------------------------------------|
| **Api**     | 8084  | ChurchApps REST API (membership, attendance, content, giving, messaging, doing, reporting) |
| **B1Admin** | 3101  | Church staff dashboard (React/Vite SPA)          |
| **B1App**   | 3301  | Public church website / member portal (Next.js)  |
| **MySQL**   | 3306  | MySQL 8.0 with all 9 databases pre-created       |

Optional services (start with `--profile full`):

| Service        | Port  | Description               |
|---------------|-------|---------------------------|
| **LessonsApi** | 8090  | Curriculum/lessons API   |
| **AskApi**     | 8097  | AI-powered Q&A API       |

## Quick Start

```bash
# 1. Clone with submodules
git clone --recurse-submodules https://github.com/dnplkndll/B1Stack
cd B1Stack

# 2. Setup: init submodules, copy .env
./scripts/setup.sh

# 3. Edit .env — set ENCRYPTION_KEY (exactly 24 chars) and JWT_SECRET
nano .env

# 4. Start services
docker compose up -d

# 5. First run only — create database tables
./scripts/init-db.sh
```

Then open:
- **B1Admin**: http://localhost:3101
- **B1App**: http://localhost:3301
- **Api**: http://localhost:8084

## Prerequisites

- Docker Desktop (or Docker Engine + Compose v2)
- Git with submodule support

## Development Workflow

### Hot reload
- **Api**: `tsx watch` restarts on any `.ts` change in `services/Api/src/`
- **B1Admin**: Vite HMR — page auto-refreshes on save. **Note**: `REACT_APP_*` env vars are read at dev-server start; changing them requires a container restart (`docker compose restart b1admin`).
- **B1App**: Next.js dev server HMR — page auto-refreshes on save.

### Useful commands

```bash
# View logs
docker compose logs -f api
docker compose logs -f b1admin

# Health check
./scripts/health-check.sh

# Reset database (destructive!)
./scripts/reset-db.sh

# Populate demo data
docker compose exec api npx tsx tools/initdb.ts --demo-only

# Start optional services
docker compose --profile full up -d

# Stop everything
docker compose down

# Stop + remove volumes (full reset)
docker compose down -v
```

## Subdomain Routing in B1App

B1App uses subdomain-based routing in production (`church.example.com` → church "church"). In local dev at `http://localhost:3301`, the subdomain rewrite doesn't apply automatically.

Workarounds:
- Add a local hosts entry: `127.0.0.1 demo.localhost` and navigate to `http://demo.localhost:3301`
- Or set the `x-site` header via a browser extension

## Helm Chart

A skeleton Helm umbrella chart is provided in `helm/b1stack/` for Kubernetes deployment. It is a **stub** — not production-ready — but provides the structure for building out a full deployment.

```bash
# Render templates locally (requires Helm 3)
helm template b1stack helm/b1stack

# Install to a cluster (staging)
helm dependency update helm/b1stack
helm upgrade --install b1stack helm/b1stack \
  -f helm/b1stack/values.staging.yaml \
  --set api.secrets.ENCRYPTION_KEY="..." \
  --set api.secrets.JWT_SECRET="..."
```

> **Production note**: Use the [ExternalSecrets operator](https://external-secrets.io/) or [sealed-secrets](https://github.com/bitnami-labs/sealed-secrets) instead of storing secret values in values files.

## Architecture

```
B1Stack/
├── services/          # git submodules — ChurchApps upstream repos
│   ├── B1Admin/       → ChurchApps/B1Admin (React/Vite)
│   ├── B1App/         → ChurchApps/B1App (Next.js)
│   ├── Api/           → ChurchApps/Api (Node/tsx)
│   ├── LessonsApi/    → ChurchApps/LessonsApi (optional)
│   └── AskApi/        → ChurchApps/AskApi (optional)
├── docker/            # Dockerfiles for each service
├── mysql/init/        # SQL to create all 9 databases on first start
├── scripts/           # setup, init-db, health-check, reset-db
└── helm/b1stack/      # Helm umbrella chart skeleton
```

## Updating Submodules

```bash
git submodule update --remote services/Api
git submodule update --remote services/B1Admin
# ... etc
git add services/
git commit -m "chore: update submodules to latest"
```

## License

This repo (orchestration scripts, Dockerfiles, Helm charts) is MIT licensed.
The ChurchApps services in `services/` retain their original licenses — see each submodule.
