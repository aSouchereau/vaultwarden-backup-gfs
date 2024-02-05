#!/bin/sh

##### Args
# 1. Backup type (GFS system) "daily", "weekly", "monthly"

function init() {
    export BACKUP_TYPE=$1

    # useful directories
    BACKUP_DIR=/vaultwarden/data
    INPUT_DIR=/app/input
    export OUTPUT_DIR=/app/output/$BACKUP_TYPE

    export NOW="$(date "+%Y-%m-%d")"
    TMP_SQLITE_DB_FILENAME="${INPUT_DIR}/db.${NOW}.sqlite3"

    if [ ! -d "$OUTPUT_DIR" ] ; then
        mkdir -p "${OUTPUT_DIR}"
    fi

    printf -- '-%.0s' $(seq 52); echo ""
    echo "Running ${BACKUP_TYPE} backup at $(date)"
    printf -- '-%.0s' $(seq 52); echo ""
}

function clear_dir() {
    if [ -d "$INPUT_DIR" ] ; then
        echo "removing previous input directory"
        rm -rf "${INPUT_DIR}"
    fi
    if [ ! -d "$INPUT_DIR" ] ; then
        mkdir "${INPUT_DIR}"
        echo "recreating input directory"
    fi

}

function backup_sqlite() {
    echo "creating sqlite online backup"
    sqlite3 "${BACKUP_DIR}/db.sqlite3" ".backup '${TMP_SQLITE_DB_FILENAME}'"
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
    rsync --recursive --partial --exclude="icon_cache" --exclude="tmp" --exclude="db.sqlite3" --exclude="db.sqlite3-shm" --exclude="db.sqlite3-wal" "${BACKUP_DIR}/" "${INPUT_DIR}/"
    mv "${INPUT_DIR}/db.${NOW}.sqlite3" "${INPUT_DIR}/db.sqlite3"
}

function package() {
    echo "packaging backup"
    tar -cf "${OUTPUT_DIR}/${NOW}_vw-data.tar" -C "${INPUT_DIR}" .
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