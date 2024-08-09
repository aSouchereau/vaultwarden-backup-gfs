#!/bin/sh

##### Args
# 1. Backup type (GFS system) "daily", "weekly", "monthly"

function init() {
    export BACKUP_TYPE=$1

    # useful directories
    DATA_DIR=/vaultwarden/data
    STAGING_DIR=/vw-backups/staging
    export OUTPUT_DIR=/vw-backups/output/$BACKUP_TYPE

    export NOW="$(date "+%Y-%m-%d")"

    if [ ! -d "$OUTPUT_DIR" ] ; then
        mkdir -p "${OUTPUT_DIR}"
    fi

    printf -- '-%.0s' $(seq 52); echo ""
    echo "Running ${BACKUP_TYPE} backup at $(date)"
    printf -- '-%.0s' $(seq 52); echo ""
}

function clear_dir() {
    if [ -d "$STAGING_DIR" ] ; then
        echo "clearing staging directory"
        rm -rf "${STAGING_DIR}"
    fi
    if [ ! -d "$STAGING_DIR" ] ; then
        mkdir "${STAGING_DIR}"
    fi

}

function backup_sqlite() {
    echo "creating sqlite backup"
    sqlite3 "${DATA_DIR}/db.sqlite3" ".backup '${STAGING_DIR}/db.sqlite3'"
    echo "checking backup integrity"
    if sqlite3 "${STAGING_DIR}/db.sqlite3" "pragma integrity_check;"; then
        echo "sqlite backup finished successfully"
    else
        echo "Backup canceled: database file failed integrity check"

        exit 1
    fi
}

function backup_mysql() {
    mysqldump -h $DB_HOST -P $DB_PORT -u $DB_USER -p$DB_PASSWORD --lock-tables $DB_DATABASE > $STAGING_DIR/db.sql
    if [ $? -eq 0 ]; then
        echo "Database backup successful"
    else
        exit 1
    fi
}

function backup_files() {
    echo "creating copy of files"
    rsync --recursive --partial --exclude="icon_cache" --exclude="tmp" --exclude="db.sqlite3" --exclude="db.sqlite3-shm" --exclude="db.sqlite3-wal" "${DATA_DIR}/" "${STAGING_DIR}/"
}

function package() {
    echo "packaging backup"
    tar -cf "${OUTPUT_DIR}/${NOW}_vw-data.tar" -C "${STAGING_DIR}" .
}

function cleanup() {
    echo "running cleanup"
    sh /app/scripts/cleanup.sh
}

init "$1"
clear_dir

case "$DB_TYPE" in 
    sqlite)
        backup_sqlite
    ;;
    mysql|mariadb)
        backup_mysql
    ;;
    *)
      echo "[Error] Invalid database type. Skipping database backup..."
    ;;
esac

backup_files

package
cleanup

echo