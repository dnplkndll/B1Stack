# Contributing to B1Stack

B1Stack orchestrates the [ChurchApps](https://github.com/ChurchApps) B1 product suite for local development and Kubernetes deployment. This guide covers how to go from clone to pull request.

## Prerequisites

- **Docker Desktop** (macOS/Windows) or Docker Engine + Compose (Linux)
- **Python 3.10+** with pip (for git-aggregator)
- **Node.js 22+** (only for running Playwright E2E tests on your host — Docker handles everything else)

## Getting Started

```bash
# 1. Clone
git clone https://github.com/dnplkndll/B1Stack.git
cd B1Stack

# 2. First-time setup — aggregates service repos, creates .env
make setup

# 3. Edit .env — set ENCRYPTION_KEY (exactly 24 chars) and JWT_SECRET

# 4. Start the stack
make up             # starts mysql, api, b1admin, b1app + waits for ready

# 5. Initialize database tables (first run only)
make init
```

See `make help` for all available targets.

## Repository Layout

```
B1Stack/
  repos.yaml      # git-aggregator config — service repos, remotes, merge strategy
  services/       # cloned service repos (gitignored, managed by gitaggregate)
    Api/           → ChurchApps/Api + dnplkndll/Api patches
    B1Admin/       → ChurchApps/B1Admin + dnplkndll/B1Admin patches
    B1App/         → ChurchApps/B1App + dnplkndll/B1App patches
    LessonsApi/    → ChurchApps/LessonsApi (upstream only)
    AskApi/        → ChurchApps/AskApi (upstream only)
  docker/         # Dockerfiles for each service
  mysql/init/     # SQL scripts run on first MySQL start
  scripts/        # setup, init-db, health-check, reset-db, wait-ready
  helm/b1stack/   # Helm umbrella chart
  .vscode/        # Recommended extensions + debug configs
```

## Service Repo Workflow (git-aggregator)

Service repos are managed by [git-aggregator](https://github.com/acsone/git-aggregator) via `repos.yaml`. The `services/` directory is gitignored — repos are cloned and merged locally.

Each `repos.yaml` entry declares remotes and an ordered list of merges. git-aggregator clones the repo, sets up all remotes, then builds a consolidated branch by merging each ref in order:

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

### To fix a bug or add a feature in a service:

1. `cd services/<Name>` and create a feature branch off `main`
2. Make your changes and commit
3. Push to the fork: `git push origin feat/my-change`
4. Add the branch to `repos.yaml` merges list
5. Run `make aggregate` to verify the merge applies cleanly
6. Test locally with `make test`
7. Open a PR on the fork (`dnplkndll/<Name>`) for team review
8. Once approved, open an upstream PR: `dnplkndll/<Name>` → `ChurchApps/<Name>`
9. After upstream merges, remove the branch from `repos.yaml` merges list

### Pulling upstream changes

```bash
make aggregate    # re-runs gitaggregate — fetches upstream + re-merges
```

### Remotes inside service repos

After `make aggregate`, each service repo has:
- `origin` — our fork (`dnplkndll/*`), for pushing feature branches
- `upstream` — ChurchApps original, fetched automatically

## Branch Naming

| Pattern | Use |
|---------|-----|
| `main` | Stable, deployable |
| `feat/<short-desc>` | New feature or enhancement |
| `fix/<short-desc>` | Bug fix |
| `chore/<short-desc>` | Maintenance, CI, docs |
| `dx/<short-desc>` | Developer experience improvements |

## Running Tests

```bash
make test        # runs Playwright E2E (B1Admin + B1App vs localhost)
make test-e2e    # same as above
```

Or run E2E individually (requires one-time host setup):

```bash
# First time only — install deps and browsers
cd services/B1Admin && npm install && npx playwright install --with-deps chromium
cd services/B1App   && npm install && npx playwright install --with-deps chromium

# Run tests
cd services/B1Admin && BASE_URL=http://localhost:3101 npx playwright test
cd services/B1App   && BASE_URL=http://localhost:3301 npx playwright test
```

Use `--headed` for visual debugging, or use the VS Code Playwright launch configs.

## Local Email Testing (Mailpit)

All outbound emails from the API are caught by [Mailpit](https://mailpit.axe.email/) in local dev — no emails escape to real inboxes.

```bash
make mail    # opens Mailpit web UI at http://localhost:8025
```

Trigger a password reset or user registration, then check Mailpit to inspect the email.

## Testing Against Docker Stack vs Staging

- **Local**: `make test` runs against your Docker Compose stack automatically
- **Staging/Demo**: Omit `BASE_URL` — tests hit upstream defaults:
  - B1Admin: `https://demo.b1.church`
  - B1App: `https://grace.demo.b1.church`

## Pull Request Guidelines

1. **One concern per PR** — don't mix features, bug fixes, and refactors
2. **Test locally** — run `make health` and `make test` before opening
3. **Describe the change** — what, why, and how to test
4. **Screenshots** for UI changes
5. **Helm changes** — run `helm lint helm/b1stack/` before opening

## Debugging

### API (Node.js attach via Docker)

1. Add `--inspect=0.0.0.0:9229` to the API's dev command in `docker/api/Dockerfile`
2. Expose port `9229` in `docker-compose.yml`
3. Use the "Attach to API (Docker)" VS Code launch config

### Database

```bash
make shell-db    # opens a MySQL shell as root
```

### Container Shell

```bash
make shell-api   # opens sh in the API container
```

## Related Documents

- [ROADMAP.md](ROADMAP.md) — prioritized feature roadmap and competitive gaps
- [CLAUDE.md](CLAUDE.md) — AI assistant context for this repo
- [README.md](README.md) — project overview and quick start
