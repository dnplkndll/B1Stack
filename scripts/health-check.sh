#!/usr/bin/env bash
set -euo pipefail

# Source .env for port overrides (strip \r in case of Windows line endings)
if [ -f .env ]; then
  while IFS='=' read -r key value; do
    key=$(echo "$key" | tr -d '\r')
    value=$(echo "$value" | tr -d '\r')
    case "$key" in
      ''|\#*) continue ;;
    esac
    export "$key=$value"
  done < .env
fi

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

check "Api"     "http://localhost:8084"
check "B1Admin" "http://localhost:3101"
check "B1App"   "http://localhost:3301"
MAILPIT_PORT=${MAILPIT_UI_PORT:-8025}
check "Mailpit" "http://localhost:${MAILPIT_PORT}"

# Optional services (only if running)
if docker compose ps lessonsapi 2>/dev/null | grep -q "Up"; then
  check "LessonsApi" "http://localhost:8090"
fi
if docker compose ps askapi 2>/dev/null | grep -q "Up"; then
  check "AskApi" "http://localhost:8097"
fi
