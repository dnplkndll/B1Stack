#!/usr/bin/env bash
set -euo pipefail

echo "=== B1Stack Setup ==="

# 1. Check dependencies
echo ""
if ! command -v gitaggregate &>/dev/null; then
  echo "→ Installing git-aggregator..."
  pip install git-aggregator
else
  echo "→ git-aggregator found."
fi

# 2. Clone/update service repos via git-aggregator
echo ""
echo "→ Aggregating service repos (repos.yaml)..."
gitaggregate -c repos.yaml -j 5

# 3. Copy .env if not present
if [ ! -f .env ]; then
  echo "→ Copying .env.sample → .env"
  cp .env.sample .env
  echo "  Edit .env and set ENCRYPTION_KEY and JWT_SECRET before starting."
else
  echo "→ .env already exists, skipping."
fi

# 4. Check Docker
if ! docker info > /dev/null 2>&1; then
  echo ""
  echo "  Docker is not running. Start Docker Desktop and try again."
  exit 1
fi
echo "→ Docker is running."

echo ""
echo "=== Setup complete ==="
echo ""
echo "Next steps:"
echo "  1. Edit .env — set ENCRYPTION_KEY (exactly 24 chars) and JWT_SECRET"
echo "  2. make up        # start services + wait for healthy"
echo "  3. make init      # first run only — create DB tables"
echo ""
echo "Service URLs:"
echo "  B1Admin   → http://localhost:3101"
echo "  B1App     → http://localhost:3301"
echo "  Api       → http://localhost:8084"
echo "  Mailpit   → http://localhost:8025"
echo ""
