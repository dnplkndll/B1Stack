#!/usr/bin/env bash
set -euo pipefail

echo "=== B1Stack Setup ==="

# 1. Init git submodules
echo ""
echo "→ Initializing git submodules..."
git submodule update --init --recursive

# 2. Copy .env if not present
if [ ! -f .env ]; then
  echo "→ Copying .env.sample → .env"
  cp .env.sample .env
  echo "  ⚠  Edit .env and set ENCRYPTION_KEY and JWT_SECRET before starting services."
else
  echo "→ .env already exists, skipping copy."
fi

# 3. Check Docker
if ! docker info > /dev/null 2>&1; then
  echo ""
  echo "  ✗ Docker is not running. Start Docker Desktop and try again."
  exit 1
fi
echo "→ Docker is running."

echo ""
echo "=== Setup complete ==="
echo ""
echo "Next steps:"
echo "  1. Edit .env and set ENCRYPTION_KEY (24 chars) and JWT_SECRET"
echo "  2. docker compose up -d"
echo "  3. ./scripts/init-db.sh     # first run only — creates all DB tables"
echo ""
echo "Service URLs:"
echo "  B1Admin  →  http://localhost:3101"
echo "  B1App    →  http://localhost:3301"
echo "  Api      →  http://localhost:8084"
echo ""
echo "Optional services (run with --profile full):"
echo "  LessonsApi  →  http://localhost:8090"
echo "  AskApi      →  http://localhost:8097"
