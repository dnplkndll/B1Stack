# CLAUDE.md — B1Stack

This repo orchestrates the ChurchApps B1 product suite for local development and Kubernetes deployment.

## Repo Structure

- `services/` — git submodules pointing to ChurchApps upstream repos (read-only here; make upstream PRs)
- `docker/` — Dockerfiles for each service (volume-mount pattern for hot-reload)
- `mysql/init/` — SQL run by MySQL on first container start (creates databases, not tables)
- `scripts/` — setup, init-db, health-check, reset-db helpers
- `helm/b1stack/` — Helm umbrella chart skeleton (stub, not production-ready)

## Services and Ports

| Service    | Port(s)   | Dev command          |
|-----------|-----------|----------------------|
| mysql     | 3306      | MySQL 8.0 image      |
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
docker compose up -d                          # start core services
docker compose --profile full up -d           # + lessonsapi + askapi
docker compose exec api npm run initdb        # create DB tables (first run)
docker compose logs -f api                    # tail api logs
docker compose restart b1admin               # pick up env var changes
./scripts/reset-db.sh                         # drop + recreate tables
```

## Submodule Workflow

- Do NOT commit changes to files inside `services/` — make PRs to ChurchApps upstream.
- To update a submodule to latest: `git submodule update --remote services/<Name>`
- Helm charts in `helm/b1stack/` are stubs — build out templates before using in production.
