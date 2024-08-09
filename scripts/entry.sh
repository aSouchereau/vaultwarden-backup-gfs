#!/bin/sh

function cleanup() {
    echo "Stopping cron"
    kill -TERM "$CRON_PID"

    echo "Shutting down..."
    exit 0
}

trap 'cleanup' SIGINT SIGTERM

echo "╦  ╦╦ ╦       ╔╗ ╔═╗╔═╗╦╔═╦ ╦╔═╗       ╔═╗╔═╗╔═╗";
echo "╚╗╔╝║║║  ───  ╠╩╗╠═╣║  ╠╩╗║ ║╠═╝  ───  ║ ╦╠╣ ╚═╗";
echo " ╚╝ ╚╩╝       ╚═╝╩ ╩╚═╝╩ ╩╚═╝╩         ╚═╝╚  ╚═╝";
echo "v1.1.1";


# populate output for dev testing
if [ "$APP_ENV" = "dev" ] && [ "$CREATE_DUMMY_FILES" = true ]; then
    cd /app/scripts/dev
    sh create_dummy_files.sh NUKEMYBACKUPS
fi

# load correct cron schedules depending on environment
if [ "$APP_ENV" = "dev" ]; then
    echo "Loading development crontab schedules"
    /usr/bin/crontab /crontab-dev.txt
else
    echo "Loading crontab schedules"
    /usr/bin/crontab /crontab.txt
fi

# check if database is reachable
DB_TYPE="${DB_TYPE:-"sqlite"}"
case "$DB_TYPE" in
    sqlite)
        echo "Checking sqlite database"
        if sqlite3 "${STAGING_DIR}/db.sqlite3" "pragma integrity_check;"; then
            echo ""
        else
            echo "[Warning]: database file failed initial integrity check"
        fi
        ;;
    mysql|mariadb)
        result=$(mysql --host $DB_HOST --port $DB_PORT \
            --user $DB_USER -p$DB_PASSWORD $DB_DATABASE -e "SELECT VERSION();")
            if [ $? -eq 0 ]; then
                echo "Database connection successful"
            else
                echo $result
                exit 1
            fi
        ;;
    *)
        echo "Invalid or unsupported database type \"$DB_TYPE\""
        exit 1
        ;;

esac


echo "Starting cron"
exec /usr/sbin/crond -f -l 8 &
CRON_PID=$!

while :; do
    sleep 1s
done