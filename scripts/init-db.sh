#!/usr/bin/env bash
set -euo pipefail

# Run after `docker compose up -d` on first start to create all DB tables.
# The MySQL init SQL only creates empty databases; this step creates the tables.

echo "=== B1Stack: Initialize database tables ==="
echo ""

echo "→ Running Api initdb (membership, attendance, content, giving, messaging, doing, reporting)..."
docker compose exec api npm run initdb

echo ""
echo "=== Database initialization complete ==="
echo ""
echo "To populate with demo data:"
echo "  docker compose exec api npx tsx tools/initdb.ts --demo-only"
