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

echo "→ Running reset-db..."
docker compose exec api npm run reset-db

echo ""
echo "→ Re-running initdb..."
docker compose exec api npm run initdb

echo ""
echo "=== Reset complete ==="
