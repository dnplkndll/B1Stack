#!/usr/bin/env bash
set -euo pipefail

echo "=== B1Stack: Reset Database ==="
echo "⚠  This will DROP and recreate all tables. All data will be lost."
echo ""
read -p "Continue? [y/N] " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
  echo "Aborted."
  exit 1
fi

DIALECT="${DB_DIALECT:-mysql}"

if [[ "$DIALECT" == "postgres" || "$DIALECT" == "postgresql" || "$DIALECT" == "pg" ]]; then
  echo "→ Running reset-db (PostgreSQL)..."
  docker compose exec api DB_DIALECT=postgres npm run reset-db
  echo ""
  echo "→ Re-running initdb..."
  docker compose exec api DB_DIALECT=postgres npm run initdb
else
  echo "→ Running reset-db (MySQL)..."
  docker compose exec api npm run reset-db
  echo ""
  echo "→ Re-running initdb..."
  docker compose exec api npm run initdb
fi

echo ""
echo "=== Reset complete ==="
