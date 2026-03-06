.PHONY: up up-full down logs init reset health test test-e2e demo-data \
       shell-api shell-db wait setup aggregate mail help

COMPOSE := docker compose
COMPOSE_FULL := docker compose --profile full

##@ Core
up: ## Start core services (mysql, api, b1admin, b1app)
	$(COMPOSE) up -d
	@./scripts/wait-ready.sh

up-full: ## Start all services including lessonsapi and askapi
	$(COMPOSE_FULL) up -d
	@./scripts/wait-ready.sh --full

down: ## Stop all services
	$(COMPOSE_FULL) down

logs: ## Tail logs for all running services
	$(COMPOSE) logs -f

##@ Repos
aggregate: ## Pull/merge service repos from upstream + fork branches (repos.yaml)
	gitaggregate -c repos.yaml -j 5

setup: ## First-time setup (aggregate repos, .env, Docker check)
	./scripts/setup.sh

##@ Database
init: ## Create DB tables (first run only)
	$(COMPOSE) exec api npm run initdb

reset: ## Drop and recreate all tables (destroys data)
	./scripts/reset-db.sh

demo-data: ## Load demo/seed data
	$(COMPOSE) exec api npx tsx tools/initdb.ts --demo-only

##@ Health & Testing
health: ## Run health check against all services
	./scripts/health-check.sh

wait: ## Poll services until ready (called automatically by `up`)
	./scripts/wait-ready.sh

test: ## Run Playwright E2E tests against localhost
	$(MAKE) test-e2e

test-e2e: ## Run Playwright E2E tests (B1Admin + B1App)
	cd services/B1Admin && BASE_URL=http://localhost:3101 npx playwright test
	cd services/B1App && BASE_URL=http://localhost:3301 npx playwright test

##@ Shell Access
shell-api: ## Open a shell in the API container
	$(COMPOSE) exec api sh

shell-db: ## Open a MySQL shell
	$(COMPOSE) exec mysql mysql -u root -p$${MYSQL_ROOT_PASSWORD:-b1stack_root}

##@ Email
mail: ## Open Mailpit web UI (local email catcher)
	$(eval MAILPIT_PORT := $(or $(MAILPIT_UI_PORT),8025))
	@echo "Opening Mailpit at http://localhost:$(MAILPIT_PORT)"
	@open http://localhost:$(MAILPIT_PORT) 2>/dev/null || xdg-open http://localhost:$(MAILPIT_PORT) 2>/dev/null || echo "Visit http://localhost:$(MAILPIT_PORT)"

##@ Help
help: ## Show this help
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) }' $(MAKEFILE_LIST)

.DEFAULT_GOAL := help
