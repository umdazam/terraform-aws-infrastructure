#!/bin/bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
ENV_FILE="$PROJECT_ROOT/.env"
BACKUP_DIR="$PROJECT_ROOT/backups"
BACKUP_FILE=""

if [[ ! -f "$ENV_FILE" ]]; then
    echo "ERROR: .env file not found."
    exit 1
fi

set -a
source "$ENV_FILE"
set +a

: "${POSTGRES_DB:?POSTGRES_DB is not set}"
: "${POSTGRES_USER:?POSTGRES_USER is not set}"
: "${POSTGRES_PASSWORD:?POSTGRES_PASSWORD is not set}"

if ! command -v pg_dump >/dev/null 2>&1; then
    echo "ERROR: pg_dump is not installed."
    exit 1
fi

export PGPASSWORD="$POSTGRES_PASSWORD"
PGHOST="${PGHOST:-127.0.0.1}"
PGPORT="${PGPORT:-5432}"

umask 077
mkdir -p "$BACKUP_DIR"

TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
BACKUP_FILE="$(mktemp "$BACKUP_DIR/${POSTGRES_DB}_${TIMESTAMP}_XXXXXX.dump")"

cleanup() {
    STATUS=$?
    unset PGPASSWORD

    if [[ "$STATUS" -ne 0 && -n "$BACKUP_FILE" ]]; then
        rm -f "$BACKUP_FILE"
        echo "ERROR: Backup failed."
    fi
}

trap cleanup EXIT

echo "Starting backup of $POSTGRES_DB"

pg_dump \
    --host="$PGHOST" \
    --port="$PGPORT" \
    --username="$POSTGRES_USER" \
    --format=custom \
    --file="$BACKUP_FILE" \
    "$POSTGRES_DB"

echo "Backup completed successfully: $BACKUP_FILE"
