# B1Stack Agent Instructions

## Project Context
B1Stack orchestrates the ChurchApps B1 product suite for local Docker Compose development and Kubernetes (Helm) deployment. Application code lives in `services/` — managed by git-aggregator via `repos.yaml`.

## Agent Capabilities

### Docker & Local Dev
- Use `make` targets for all common operations (see `make help`)
- `make up` starts core services and polls until ready
- `make up-full` includes optional LessonsApi and AskApi
- `make init` creates DB tables on first run
- `make test` runs Playwright E2E tests against localhost

### Debugging
- VS Code/Cursor launch configs are in `.vscode/launch.json`
- "Attach to API (Docker)" for Node.js debugging via port 9229
- "Playwright: B1Admin/B1App" for E2E test debugging

### Helm / Kubernetes
- Chart is at `helm/b1stack/` — flat structure, no sub-charts
- All 5 services templated directly in `templates/` with `<svc>-` filename prefixes
- MySQL uses `public.ecr.aws/bitnami/mysql` (Bitnami removed Docker Hub tags)
- Always run `helm lint helm/b1stack/` after chart changes

### Testing
- Playwright configs in `services/B1Admin/` and `services/B1App/` support `BASE_URL` env var
- Default: `demo.b1.church` (upstream demo) — set `BASE_URL=http://localhost:3101` for local
- `make test` sets this automatically

## Important Constraints
- **Work in `services/`** via feature branches — see CONTRIBUTING.md for the git-aggregator workflow
- **Never commit secrets** — use `.env` file (gitignored)
- **Restart containers** (not just HMR) to pick up `REACT_APP_*` env var changes
- **Named volumes** (`api_node_modules`, etc.) prevent host `node_modules` shadowing
- **Sync repos**: `make aggregate` (runs `gitaggregate -c repos.yaml`)

## File Reference
| File | Purpose |
|------|---------|
| `Makefile` | DX shortcuts for all common tasks |
| `docker-compose.yml` | Service definitions, ports, volumes, env vars |
| `scripts/wait-ready.sh` | Post-up readiness polling with timeout |
| `scripts/health-check.sh` | One-shot health check of all services |
| `scripts/setup.sh` | First-time setup (aggregate repos, .env) |
| `scripts/init-db.sh` | Create DB tables via Api initdb |
| `scripts/reset-db.sh` | Drop + recreate all tables |
| `helm/b1stack/values.yaml` | Default Helm values |
| `CONTRIBUTING.md` | Contributor workflow guide |
| `ROADMAP.md` | Feature roadmap and issue triage |
