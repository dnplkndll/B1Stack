# B1Stack

Docker Compose and Helm orchestration for the [ChurchApps](https://b1.church) B1 product suite — run the full stack locally in minutes.

> **Evaluating B1Stack for your church?**
> → [Cloud hosting costs & CLI install steps](docs/cloud-hosting.md) — from **~$13/mo** (Hetzner) to ~$121/mo (AWS EKS)
> → [On-site hardware & implementation plan](docs/implementation-guide.md) — kiosks, printers, AV, project timeline *(WIP — community review welcome)*

## Quick Start (Docker Compose)

```bash
git clone https://github.com/dnplkndll/B1Stack && cd B1Stack && make setup && make up && make init
```

Then open **http://localhost:3101** — login with `demo@b1.church` / `password`.

> **First time?** `make setup` prompts you to set `ENCRYPTION_KEY` (24 chars) and `JWT_SECRET` in `.env` before starting.

## Quick Start (Kubernetes / Helm)

Port-forward only (no domain needed):

```bash
helm upgrade --install b1stack helm/b1stack -n b1stack --create-namespace --wait
kubectl -n b1stack port-forward svc/b1stack-b1admin 3101:80
```

With ingress + TLS (one flag):

```bash
helm upgrade --install b1stack helm/b1stack -n b1stack --create-namespace \
  --set global.baseDomain=church.example.com \
  --set global.ingress.clusterIssuer=letsencrypt-prod --wait
```

See [helm/b1stack/README.md](helm/b1stack/README.md) for full configuration.

## Services

| Service      | Port  | Description                                      |
|-------------|-------|--------------------------------------------------|
| **Api**     | 8084/8087 | ChurchApps REST API + WebSocket |
| **B1Admin** | 3101  | Church staff dashboard (React/Vite SPA)          |
| **B1App**   | 3301  | Public church website / member portal (Next.js)  |
| **MySQL**   | 3306  | MySQL 8.0                                        |
| **Mailpit** | 8025  | Local email catcher                              |

Optional (start with `make up-full`): **LessonsApi** (8090), **AskApi** (8097).

## Makefile

```bash
make setup       # first-time: aggregate repos, create .env
make up          # start core services
make init        # create DB tables (first run)
make demo-data   # load demo/seed data
make test        # run Playwright E2E tests
make down        # stop all services
make logs        # tail logs
make health      # health check
make reset       # drop + recreate all tables
make shell-api   # shell into API container
make shell-db    # MySQL shell
make mail        # open Mailpit web UI
make help        # show all targets
```

## How Service Repos Work

Service repos live in `services/` (gitignored), managed by [git-aggregator](https://github.com/acsone/git-aggregator) via `repos.yaml`. Running `make aggregate` clones each repo and merges upstream + fork branches:

```yaml
./services/B1Admin:
  remotes:
    upstream: https://github.com/ChurchApps/B1Admin.git
    origin: https://github.com/dnplkndll/B1Admin.git
  target: origin main
  merges:
    - upstream main
    - origin feat/my-feature  # our patches on top
```

## Architecture

```
B1Stack/
├── repos.yaml         # git-aggregator: all service repos + merge strategy
├── services/          # cloned repos (gitignored)
├── docker/            # Dockerfiles (volume-mount for hot-reload)
├── mysql/init/        # SQL: creates all 9 databases on first start
├── scripts/           # setup, init-db, health-check, reset-db helpers
└── helm/b1stack/      # Helm umbrella chart (flat, no sub-charts)
```

## Contributing · Roadmap · License

See [CONTRIBUTING.md](CONTRIBUTING.md) | [ROADMAP.md](ROADMAP.md)

This repo is MIT licensed. Services in `services/` retain their original licenses.
