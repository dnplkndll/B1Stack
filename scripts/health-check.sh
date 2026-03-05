#!/usr/bin/env bash
set -euo pipefail

echo "=== B1Stack Health Check ==="
echo ""

check() {
  local name="$1"
  local url="$2"
  if curl -sf --max-time 5 "$url" > /dev/null 2>&1; then
    echo "  ✓ $name ($url)"
  else
    echo "  ✗ $name ($url) — not responding"
  fi
}

docker compose ps
echo ""

check "Api"     "http://localhost:8084/membership/churches"
check "B1Admin" "http://localhost:3101"
check "B1App"   "http://localhost:3301"

# Optional services (only if running)
if docker compose ps lessonsapi 2>/dev/null | grep -q "Up"; then
  check "LessonsApi" "http://localhost:8090"
fi
if docker compose ps askapi 2>/dev/null | grep -q "Up"; then
  check "AskApi" "http://localhost:8097"
fi
