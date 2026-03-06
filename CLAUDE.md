# CLAUDE.md — B1Stack

This repo orchestrates the ChurchApps B1 product suite for local development and Kubernetes deployment.

## Repo Structure

- `repos.yaml` — git-aggregator config declaring all service repos, remotes, and merge strategy
- `services/` — cloned service repos (gitignored, managed by `gitaggregate`)
- `docker/` — Dockerfiles for each service (volume-mount pattern for hot-reload)
- `mysql/init/` — SQL run by MySQL on first container start (creates databases, not tables)
- `scripts/` — setup, init-db, health-check, reset-db, wait-ready helpers
- `helm/b1stack/` — Helm umbrella chart (flat, no sub-charts; deployed on Hetzner b1-test)

## Services and Ports

| Service    | Port(s)   | Dev command          |
|-----------|-----------|----------------------|
| mysql     | 3306      | MySQL 8.0 image      |
| mailpit   | 8025/1025 | Local SMTP catcher (web UI: 8025, SMTP: 1025) |
| api       | 8084/8087 | `tsx watch src/index.ts` |
| b1admin   | 3101      | `npm start` (Vite)   |
| b1app     | 3301      | `npm run dev` (Next.js) |
| lessonsapi| 8090      | `nodemon` + `ts-node` (profile: full) |
| askapi    | 8097      | `nodemon` (profile: full) |

## Key Facts

- **Api connection strings**: Per-module env vars: `MEMBERSHIP_CONNECTION_STRING`, `ATTENDANCE_CONNECTION_STRING`, etc. (`mysql://root:...@mysql:3306/<db>`)
- **LessonsApi/AskApi**: Single `CONNECTION_STRING` env var (from `@churchapps/apihelper` `EnvironmentBase.populateBase`)
- **B1Admin env prefix**: `REACT_APP_*` — read at Vite dev-server start. Container restart required to pick up changes (not just HMR).
- **B1App env prefix**: `NEXT_PUBLIC_*`
- **Hot-reload on macOS Docker**: Uses `CHOKIDAR_USEPOLLING=true` (B1Admin) and `WATCHPACK_POLLING=true` (B1App)
- **Named volumes** prevent host `node_modules` from shadowing container's: `api_node_modules`, `b1admin_node_modules`, etc.
- **Api initdb**: `npm run initdb` = `tsx tools/initdb.ts`. Run via `docker compose exec api npm run initdb` after first `up`.
- **Api `dev` script**: `tsx watch src/index.ts` (verified in package.json)
- **LessonsApi `dev` script**: `nodemon --watch src -e ts,ejs --exec "ts-node src/index.ts"`
- **AskApi `dev` script**: `nodemon --watch src -e ts,ejs --exec "node --import ./register.js src/index.ts"` (uses ESM `register.js`)

## Common Commands

```bash
make setup                                    # first-time: aggregate repos, create .env
make aggregate                                # pull/merge repos from upstream + fork branches
make up                                       # start core services + wait for ready
make down                                     # stop all services
make up-full                                  # + lessonsapi + askapi
make init                                     # create DB tables (first run)
make logs                                     # tail all service logs
make health                                   # health check all services
make test                                     # run Playwright E2E against localhost
make mail                                     # open Mailpit web UI
make reset                                    # drop + recreate tables
make demo-data                                # load demo/seed data
make shell-api                                # sh into API container
make shell-db                                 # MySQL shell
```

## Service Repos (git-aggregator)

Service repos are managed by [git-aggregator](https://github.com/acsone/git-aggregator) via `repos.yaml`.
The `services/` directory is gitignored — repos are cloned locally by `make setup` or `make aggregate`.

| Service | Fork (origin) | Upstream |
|---------|---------------|----------|
| Api | `dnplkndll/Api` | `ChurchApps/Api` |
| B1Admin | `dnplkndll/B1Admin` | `ChurchApps/B1Admin` |
| B1App | `dnplkndll/B1App` | `ChurchApps/B1App` |
| LessonsApi | — | `ChurchApps/LessonsApi` |
| AskApi | — | `ChurchApps/AskApi` |

### How repos.yaml works

Each entry in `repos.yaml` declares remotes and an ordered list of merges:

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

Running `make aggregate` (or `gitaggregate -c repos.yaml`) clones each repo, sets up remotes, and builds a consolidated branch by merging each ref in order.

### Making changes in a service

1. `cd services/<Name>` and create a feature branch
2. Commit and push to fork: `git push origin feat/my-change`
3. Add the branch to `repos.yaml` merges list
4. Run `make aggregate` to verify the merge applies cleanly
5. When ready for upstream, PR from `dnplkndll/<Name>` → `ChurchApps/<Name>`
6. After upstream merges, remove the branch from `repos.yaml`

### Remotes inside service repos

- `origin` — our fork (`dnplkndll/*`), for day-to-day work
- `upstream` — ChurchApps original, pulled automatically by git-aggregator

### Other notes

- Helm chart uses `public.ecr.aws/bitnami/mysql` (Bitnami removed Docker Hub tags).
- See [CONTRIBUTING.md](CONTRIBUTING.md) for contributor workflow, [ROADMAP.md](ROADMAP.md) for feature priorities.
