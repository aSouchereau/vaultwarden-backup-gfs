function init() {

    # useful directories
    BACKUP_DIR=/vaultwarden/data
    INPUT_DIR=/app/input
    OUTPUT_DIR=/app/output

    if [ ! -d "$OUTPUT_DIR" ] ; then
        mkdir "${OUTPUT_DIR}"
    fi

    NOW="$(date "+%Y-%m-%d")"

    TMP_SQLITE_DB_FILENAME="${INPUT_DIR}/db.${NOW}.sqlite3"
}

function clear_dir() {
    # reset input directory for new backup
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
    sqlite3 "${BACKUP_DIR}/db.sqlite3" ".backup '${TMP_SQLITE_DB_FILENAME}'"
    if sqlite3 "${TMP_SQLITE_DB_FILENAME}" "pragma integrity_check;"; then
        echo "sqlite db file integrity ok"
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
}

function cleanup() {
    echo "running cleanup script"
    sh /app/scripts/cleanup.sh
}

init
clear_dir

backup_sqlite
backup_files

package
cleanup