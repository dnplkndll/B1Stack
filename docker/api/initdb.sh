#!/bin/sh
# B1Stack database initialisation script.
# Runs all SQL scripts in tools/dbScripts/ against the bundled MySQL instance.
#
# Environment variables:
#   MYSQL_HOST     - MySQL hostname          (default: b1stack-mysql)
#   MYSQL_USER     - MySQL username          (default: b1stack)
#   MYSQL_PASSWORD - MySQL password          (required)
#   MYSQL_PORT     - MySQL port              (default: 3306)

set -e

HOST="${MYSQL_HOST:-b1stack-mysql}"
USER="${MYSQL_USER:-b1stack}"
PORT="${MYSQL_PORT:-3306}"

if [ -z "$MYSQL_PASSWORD" ]; then
  echo "ERROR: MYSQL_PASSWORD is required" >&2
  exit 1
fi

CMD="mysql -h $HOST -P $PORT -u $USER -p${MYSQL_PASSWORD}"

# Wait for MySQL to be ready (up to 5 minutes)
echo "Waiting for MySQL at $HOST:$PORT ..."
i=0
until $CMD -e "SELECT 1" >/dev/null 2>&1; do
  i=$((i + 1))
  if [ $i -ge 60 ]; then
    echo "ERROR: MySQL not ready after 5 minutes." >&2
    exit 1
  fi
  echo "  Not ready yet, retrying in 5s... ($i/60)"
  sleep 5
done
echo "MySQL is ready."

# Run SQL files for each module.
# --force continues on errors (handles FK ordering); tables are idempotent
# (DROP TABLE IF EXISTS + CREATE TABLE) so re-runs are safe.
for module in membership attendance content giving messaging doing reporting; do
  dir="/app/tools/dbScripts/$module"
  [ -d "$dir" ] || continue
  echo "Initialising module: $module"
  for sql_file in "$dir"/*.sql; do
    [ -f "$sql_file" ] || continue
    $CMD --force "$module" < "$sql_file" 2>&1 | grep -v "Warning" || true
  done
  echo "  done."
done

echo "Database initialisation complete."
