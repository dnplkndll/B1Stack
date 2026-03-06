# B1Stack

Docker Compose and Helm orchestration for the [ChurchApps](https://b1.church) B1 product suite — run the full stack locally in minutes.

Follows the B1 naming convention: B1Admin, B1App, B1Checkin, B1Mobile... **B1Stack**.

## Services

| Service      | Port  | Description                                      |
|-------------|-------|--------------------------------------------------|
| **Api**     | 8084/8087 | ChurchApps REST API + WebSocket (membership, attendance, content, giving, messaging, doing, reporting) |
| **B1Admin** | 3101  | Church staff dashboard (React/Vite SPA)          |
| **B1App**   | 3301  | Public church website / member portal (Next.js)  |
| **MySQL**   | 3306  | MySQL 8.0 with all 9 databases pre-created       |
| **Mailpit** | 8025  | Local email catcher (catches all outbound SMTP)  |

Optional services (start with `make up-full`):

| Service        | Port  | Description               |
|---------------|-------|---------------------------|
| **LessonsApi** | 8090  | Curriculum/lessons API   |
| **AskApi**     | 8097  | AI-powered Q&A API       |

## Quick Start (Docker Compose)

```bash
# 1. Clone
git clone https://github.com/dnplkndll/B1Stack
cd B1Stack

# 2. Setup: aggregate service repos, create .env
make setup

# 3. Edit .env — set ENCRYPTION_KEY (exactly 24 chars) and JWT_SECRET
nano .env

# 4. Start services (waits until all are healthy)
make up

# 5. First run only — create database tables
make init
```

Then open:
- **B1Admin**: http://localhost:3101
- **B1App**: http://localhost:3301
- **Api**: http://localhost:8084
- **Mailpit** (email catcher): http://localhost:8025

### Demo Login

| Field | Value |
|-------|-------|
| Email | `demo@b1.church` |
| Password | `password` |
| Church | Grace Community Church |

## Quick Start (Helm / Kubernetes)

```bash
# Zero-override deploy (port-forward only)
helm repo add bitnami https://charts.bitnami.com/bitnami
helm dep update helm/b1stack
helm upgrade --install b1stack helm/b1stack -n b1stack --create-namespace \
  --set mysql.image.registry=public.ecr.aws --set mysql.image.repository=bitnami/mysql \
  --wait

kubectl -n b1stack port-forward svc/b1stack-b1admin 3101:80
# Open http://localhost:3101 → demo@b1.church / password
```

With ingress (add your domain):

```bash
helm upgrade --install b1stack helm/b1stack -n b1stack --create-namespace \
  --set global.baseDomain=church.example.com \
  --set mysql.image.registry=public.ecr.aws \
  --set mysql.image.repository=bitnami/mysql \
  --wait
```

See [helm/b1stack/README.md](helm/b1stack/README.md) for full configuration, production setup, and values reference.

## Prerequisites

- Docker Desktop (or Docker Engine + Compose v2)
- Python 3.10+ with pip (for git-aggregator)
- Node.js 22+ (only for running Playwright E2E tests on your host)
- Helm 3 + Kubernetes 1.24+ (for Helm deploy only)

## How Service Repos Work

Service repos live in `services/` but are **not tracked by git** (gitignored). They're managed by [git-aggregator](https://github.com/acsone/git-aggregator) via `repos.yaml`.

`repos.yaml` declares each service's upstream remote, our fork remote, and what branches to merge:

```yaml
./services/B1Admin:
  remotes:
    upstream: https://github.com/ChurchApps/B1Admin.git
    origin: https://github.com/dnplkndll/B1Admin.git
  target: origin main
  merges:
    - upstream main           # start from upstream
    - origin feat/my-feature  # merge our branch on top
```

Running `make aggregate` clones each repo, sets up remotes, and merges the listed refs in order.

## Development Workflow

### Hot reload
- **Api**: `tsx watch` restarts on any `.ts` change in `services/Api/src/`
- **B1Admin**: Vite HMR — page auto-refreshes on save. **Note**: `REACT_APP_*` env vars are read at dev-server start; changing them requires a container restart (`docker compose restart b1admin`).
- **B1App**: Next.js dev server HMR — page auto-refreshes on save.

### Makefile shortcuts

```bash
make setup       # first-time: aggregate repos, create .env, check Docker
make aggregate   # pull/merge repos from upstream + fork branches
make up          # start core services + wait for ready
make down        # stop all services
make up-full     # start all services (including LessonsApi, AskApi)
make logs        # tail logs
make health      # health check all services
make init        # create DB tables (first run)
make reset       # drop + recreate all tables
make demo-data   # load demo/seed data
make test        # run Playwright E2E against localhost
make shell-api   # shell into API container
make shell-db    # MySQL shell
make mail        # open Mailpit web UI
make help        # show all targets
```

## Subdomain Routing in B1App

B1App uses subdomain-based routing in production (`church.example.com` -> church "church"). In local dev at `http://localhost:3301`, the subdomain rewrite doesn't apply automatically.

Workarounds:
- Add a local hosts entry: `127.0.0.1 demo.localhost` and navigate to `http://demo.localhost:3301`
- Or set the `x-site` header via a browser extension

## Architecture

```
B1Stack/
├── repos.yaml         # git-aggregator config — declares all service repos + merges
├── services/          # cloned service repos (gitignored, managed by gitaggregate)
│   ├── Api/           → ChurchApps/Api + dnplkndll/Api patches
│   ├── B1Admin/       → ChurchApps/B1Admin + dnplkndll/B1Admin patches
│   ├── B1App/         → ChurchApps/B1App + dnplkndll/B1App patches
│   ├── LessonsApi/    → ChurchApps/LessonsApi (upstream only)
│   └── AskApi/        → ChurchApps/AskApi (upstream only)
├── docker/            # Dockerfiles for each service
├── mysql/init/        # SQL to create all 9 databases on first start
├── scripts/           # setup, init-db, health-check, reset-db, wait-ready
└── helm/b1stack/      # Helm umbrella chart
```

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for the full clone-to-PR workflow, branch naming, and testing guide.

## Roadmap

See [ROADMAP.md](ROADMAP.md) for the prioritized feature roadmap, competitive gap analysis, and issue triage.

## License

This repo (orchestration scripts, Dockerfiles, Helm charts) is MIT licensed.
The ChurchApps services in `services/` retain their original licenses.
