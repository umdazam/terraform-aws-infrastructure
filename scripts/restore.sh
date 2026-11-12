#!/bin/bash
set -Eeuo pipefail

# Project paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
ENV_FILE="$PROJECT_ROOT/.env"

# Validate arguments
if [[ $# -lt 1 || $# -gt 2 ]]; then
    echo "Usage: $0 <backup-file> [new-database-name]"
    exit 1
fi

BACKUP_FILE="$1"

# Check backup file
if [[ ! -f "$BACKUP_FILE" ]]; then
    echo "ERROR: Backup file not found: $BACKUP_FILE"
    exit 1
fi

# Check environment file
if [[ ! -f "$ENV_FILE" ]]; then
    echo "ERROR: .env file not found."
    exit 1
fi

# Load database configuration
set -a
source "$ENV_FILE"
set +a

: "${POSTGRES_DB:?POSTGRES_DB is not set}"
: "${POSTGRES_USER:?POSTGRES_USER is not set}"
: "${POSTGRES_PASSWORD:?POSTGRES_PASSWORD is not set}"

# Select restore database
RESTORE_DB="${2:-${POSTGRES_DB}_restore_test}"

# Validate database name
if [[ ! "$RESTORE_DB" =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]]; then
    echo "ERROR: Invalid database name: $RESTORE_DB"
    exit 1
fi

# Check PostgreSQL client tools
for cmd in psql createdb dropdb pg_restore; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo "ERROR: $cmd is not installed."
        exit 1
    fi
done

# Database connection settings
export PGPASSWORD="$POSTGRES_PASSWORD"
PGHOST="${PGHOST:-127.0.0.1}"
PGPORT="${PGPORT:-5432}"

DB_CREATED=false

# Cleanup incomplete database on failure
cleanup() {
    STATUS=$?

    if [[ "$STATUS" -ne 0 && "$DB_CREATED" == true ]]; then
        echo "Restore failed. Removing incomplete database..."

        dropdb \
            --host="$PGHOST" \
            --port="$PGPORT" \
            --username="$POSTGRES_USER" \
            "$RESTORE_DB" 2>/dev/null || true
    fi

    unset PGPASSWORD
}

trap cleanup EXIT

# Check whether database already exists
EXISTS="$(psql \
    --host="$PGHOST" \
    --port="$PGPORT" \
    --username="$POSTGRES_USER" \
    --dbname=postgres \
    --no-align \
    --tuples-only \
    --command="SELECT 1 FROM pg_database WHERE datname = '$RESTORE_DB';")"

if [[ "$EXISTS" == "1" ]]; then
    echo "ERROR: Database '$RESTORE_DB' already exists."
    echo "Choose another database name."
    exit 1
fi

# Validate backup archive
echo "Validating backup archive..."
pg_restore --list "$BACKUP_FILE" >/dev/null

# Create fresh database
echo "Creating database: $RESTORE_DB"

createdb \
    --host="$PGHOST" \
    --port="$PGPORT" \
    --username="$POSTGRES_USER" \
    --owner="$POSTGRES_USER" \
    --template=template0 \
    "$RESTORE_DB"

DB_CREATED=true

# Restore database backup
echo "Restoring backup into $RESTORE_DB..."

pg_restore \
    --host="$PGHOST" \
    --port="$PGPORT" \
    --username="$POSTGRES_USER" \
    --dbname="$RESTORE_DB" \
    --no-owner \
    --exit-on-error \
    "$BACKUP_FILE"

# Verify restored tables and records
echo "Verifying restored database..."

psql \
    --host="$PGHOST" \
    --port="$PGPORT" \
    --username="$POSTGRES_USER" \
    --dbname="$RESTORE_DB" \
    --set=ON_ERROR_STOP=1 \
    --command="
        SELECT
            to_regclass('public.hotel_bookings') AS hotel_bookings_table,
            to_regclass('public.booking_events') AS booking_events_table;

        SELECT COUNT(*) AS hotel_bookings_count
        FROM hotel_bookings;

        SELECT COUNT(*) AS booking_events_count
        FROM booking_events;
    "

DB_CREATED=false

echo "Restore completed and verification succeeded."
echo "Restored database: $RESTORE_DB"
