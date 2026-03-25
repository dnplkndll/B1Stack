#!/bin/sh
# B1Stack database initialisation script.
# Applies DDL from tools/dbScripts/ (MySQL) or tools/dbScripts/pg/ (PostgreSQL).
# Loads stored procedures + demo data from tools/dbScripts/.
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
MODULES="membership attendance content giving messaging doing"

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
  BASECMD="psql -h $HOST -p $PORT -U $USER"

  echo "Waiting for PostgreSQL at $HOST:$PORT ..."
  i=0
  until $BASECMD -d $DATABASE -c "SELECT 1" >/dev/null 2>&1; do
    i=$((i + 1))
    if [ $i -ge 60 ]; then
      echo "ERROR: PostgreSQL not ready after 5 minutes." >&2
      exit 1
    fi
    echo "  Not ready yet, retrying in 5s... ($i/60)"
    sleep 5
  done
  echo "PostgreSQL is ready."

  for module in $MODULES; do
    echo "Initialising module: $module"

    # Ensure per-module database exists (mirrors MySQL layout)
    $BASECMD -d $DATABASE -c "SELECT 1 FROM pg_database WHERE datname = '$module'" | grep -q 1 || \
      $BASECMD -d $DATABASE -c "CREATE DATABASE $module OWNER $USER" 2>&1 | grep -v "NOTICE" || true

    CMD="$BASECMD -d $module"

    # Apply PG DDL files (CREATE TABLE statements)
    ddl_dir="/app/tools/dbScripts/pg/$module"
    if [ -d "$ddl_dir" ]; then
      for sql_file in "$ddl_dir"/*.sql; do
        [ -f "$sql_file" ] || continue
        base=$(basename "$sql_file")
        # Skip stored procedure files (loaded separately below)
        case "$base" in
          cleanup.sql|deleteForChurch.sql|updateConversationStats.sql) continue ;;
        esac
        echo "  DDL: $base"
        $CMD -f "$sql_file" 2>&1 | grep -v "NOTICE" || true
      done

      # Load PG stored functions
      for sql_file in "$ddl_dir"/*.sql; do
        [ -f "$sql_file" ] || continue
        base=$(basename "$sql_file")
        case "$base" in
          cleanup.sql|deleteForChurch.sql|updateConversationStats.sql)
            echo "  Function: $base"
            $CMD -f "$sql_file" 2>&1 | grep -v "NOTICE" || true
            ;;
        esac
      done
    fi

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

  for module in $MODULES; do
    echo "Initialising module: $module"
    # Ensure database exists
    $CMD -e "CREATE DATABASE IF NOT EXISTS \`$module\`" 2>&1 | grep -v "Warning" || true

    # Apply MySQL DDL files (CREATE TABLE statements)
    ddl_dir="/app/tools/dbScripts/$module"
    if [ -d "$ddl_dir" ]; then
      for sql_file in "$ddl_dir"/*.sql; do
        [ -f "$sql_file" ] || continue
        base=$(basename "$sql_file")
        # Skip stored procedure files and demo data (loaded separately)
        case "$base" in
          cleanup.sql|deleteForChurch.sql|updateConversationStats.sql|*demo*) continue ;;
        esac
        echo "  DDL: $base"
        $CMD --force "$module" < "$sql_file" 2>&1 | grep -v "Warning" || true
      done

      # Load stored procedures (MySQL only)
      for sql_file in "$ddl_dir"/*.sql; do
        [ -f "$sql_file" ] || continue
        base=$(basename "$sql_file")
        case "$base" in
          cleanup.sql|deleteForChurch.sql|updateConversationStats.sql)
            echo "  Procedure: $base"
            $CMD --force "$module" < "$sql_file" 2>&1 | grep -v "Warning" || true
            ;;
        esac
      done
    fi

    echo "  done."
  done
fi

echo "Database initialisation complete."
