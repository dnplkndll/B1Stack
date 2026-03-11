#!/bin/sh
# B1Stack database initialisation script.
# Runs all SQL scripts in tools/dbScripts/ against the bundled database instance.
#
# Supports both MySQL and PostgreSQL based on DB_DIALECT env var.
#
# MySQL environment variables:
#   MYSQL_HOST     - MySQL hostname          (default: b1stack-mysql)
#   MYSQL_USER     - MySQL username          (default: b1stack)
#   MYSQL_PASSWORD - MySQL password          (required for MySQL)
#   MYSQL_PORT     - MySQL port              (default: 3306)
#
# PostgreSQL environment variables:
#   PG_HOST        - PostgreSQL hostname     (default: b1stack-pg)
#   PG_USER        - PostgreSQL username     (default: b1stack)
#   PG_PASSWORD    - PostgreSQL password     (required for PostgreSQL)
#   PG_PORT        - PostgreSQL port         (default: 5432)
#   PG_DATABASE    - PostgreSQL database     (default: b1stack)

set -e

DIALECT="${DB_DIALECT:-mysql}"

if [ "$DIALECT" = "postgres" ] || [ "$DIALECT" = "postgresql" ] || [ "$DIALECT" = "pg" ]; then
  # ─── PostgreSQL mode ─────────────────────────────────────────────────────
  HOST="${PG_HOST:-b1stack-pg}"
  USER="${PG_USER:-b1stack}"
  PORT="${PG_PORT:-5432}"
  DATABASE="${PG_DATABASE:-b1stack}"

  if [ -z "$PG_PASSWORD" ]; then
    echo "ERROR: PG_PASSWORD is required" >&2
    exit 1
  fi

  export PGPASSWORD="$PG_PASSWORD"
  CMD="psql -h $HOST -p $PORT -U $USER -d $DATABASE"

  echo "Waiting for PostgreSQL at $HOST:$PORT ..."
  i=0
  until $CMD -c "SELECT 1" >/dev/null 2>&1; do
    i=$((i + 1))
    if [ $i -ge 60 ]; then
      echo "ERROR: PostgreSQL not ready after 5 minutes." >&2
      exit 1
    fi
    echo "  Not ready yet, retrying in 5s... ($i/60)"
    sleep 5
  done
  echo "PostgreSQL is ready."

  for module in membership attendance content giving messaging doing reporting; do
    dir="/app/tools/dbScripts/$module"
    [ -d "$dir" ] || continue
    echo "Initialising module: $module"
    # Ensure schema exists and set search_path
    $CMD -c "CREATE SCHEMA IF NOT EXISTS $module" 2>/dev/null || true
    for sql_file in "$dir"/*.sql; do
      [ -f "$sql_file" ] || continue
      # Skip MySQL stored procedure files on PG
      if grep -qi "DELIMITER\|CREATE PROCEDURE\|CREATE DEFINER" "$sql_file" 2>/dev/null; then
        echo "  Skipping MySQL procedure: $(basename "$sql_file")"
        continue
      fi
      PGOPTIONS="-c search_path=$module,public" $CMD -f "$sql_file" 2>&1 | grep -v "NOTICE" || true
    done
    echo "  done."
  done

else
  # ─── MySQL mode (default) ───────────────────────────────────────────────
  HOST="${MYSQL_HOST:-b1stack-mysql}"
  USER="${MYSQL_USER:-b1stack}"
  PORT="${MYSQL_PORT:-3306}"

  if [ -z "$MYSQL_PASSWORD" ]; then
    echo "ERROR: MYSQL_PASSWORD is required" >&2
    exit 1
  fi

  CMD="mysql -h $HOST -P $PORT -u $USER -p${MYSQL_PASSWORD} --ssl=0"

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
fi

echo "Database initialisation complete."
