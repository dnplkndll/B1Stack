#!/usr/bin/env bash
set -euo pipefail

TIMEOUT=${WAIT_TIMEOUT:-120}
INTERVAL=3

NAMES=("Api" "B1Admin" "B1App")
URLS=("http://localhost:8084" "http://localhost:3101" "http://localhost:3301")

if [ "${1:-}" = "--full" ]; then
  NAMES=("Api" "B1Admin" "B1App" "LessonsApi" "AskApi")
  URLS=("http://localhost:8084/membership/churches" "http://localhost:3101" "http://localhost:3301" "http://localhost:8090" "http://localhost:8097")
fi

total=${#NAMES[@]}

echo "Waiting for services to become ready (timeout: ${TIMEOUT}s)..."

start=$SECONDS
all_ready=false

while [ $((SECONDS - start)) -lt "$TIMEOUT" ]; do
  ready=0
  i=0
  while [ $i -lt $total ]; do
    if curl -sf --max-time 3 "${URLS[$i]}" > /dev/null 2>&1; then
      ready=$((ready + 1))
    fi
    i=$((i + 1))
  done

  if [ "$ready" -eq "$total" ]; then
    all_ready=true
    break
  fi

  elapsed=$((SECONDS - start))
  printf "\r  [%3ds] %d/%d services ready..." "$elapsed" "$ready" "$total"
  sleep "$INTERVAL"
done

echo ""

if $all_ready; then
  echo ""
  i=0
  while [ $i -lt $total ]; do
    url="${URLS[$i]}"
    base=$(echo "$url" | sed 's|^\(https*://[^/]*\).*|\1|')
    echo "  * ${NAMES[$i]}  ->  $base"
    i=$((i + 1))
  done
  echo ""
  echo "All services ready."
else
  echo ""
  echo "Timed out after ${TIMEOUT}s. Status:"
  i=0
  while [ $i -lt $total ]; do
    if curl -sf --max-time 3 "${URLS[$i]}" > /dev/null 2>&1; then
      echo "  + ${NAMES[$i]} - ready"
    else
      echo "  - ${NAMES[$i]} - NOT ready"
    fi
    i=$((i + 1))
  done
  exit 1
fi
