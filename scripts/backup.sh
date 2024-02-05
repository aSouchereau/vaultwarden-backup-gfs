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
    TMP_SQLITE_DB_FILENAME="${STAGING_DIR}/db.${NOW}.sqlite3"

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
    echo "creating sqlite online backup"
    sqlite3 "${DATA_DIR}/db.sqlite3" ".backup '${TMP_SQLITE_DB_FILENAME}'"
    echo "checking backup integrity"
    if sqlite3 "${TMP_SQLITE_DB_FILENAME}" "pragma integrity_check;"; then
        echo "sqlite online backup finished successfully"
    else
        echo "Backup canceled: database file failed integrity check"

        exit 1
    fi
}

function backup_files() {
    echo "creating copy of files"
    rsync --recursive --partial --exclude="icon_cache" --exclude="tmp" --exclude="db.sqlite3" --exclude="db.sqlite3-shm" --exclude="db.sqlite3-wal" "${DATA_DIR}/" "${STAGING_DIR}/"
    mv "${STAGING_DIR}/db.${NOW}.sqlite3" "${STAGING_DIR}/db.sqlite3"
}

function package() {
    echo "packaging backup"
    tar -cf "${OUTPUT_DIR}/${NOW}_vw-data.tar" -C "${STAGING_DIR}" .
    echo "backup process complete"
}

function cleanup() {
    echo "running cleanup"
    sh /app/scripts/cleanup.sh
}

init "$1"
clear_dir

backup_sqlite
backup_files

package
cleanup

echo