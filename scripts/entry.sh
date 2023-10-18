#!/bin/sh

# populate output for dev testing
if [ "$APP_ENV" = "dev" ] && [ "$POPULATE_OUTPUT_ON_START" = true ]; then
    cd /app/scripts/dev
    sh populate_output.sh DELETEMYDATA
fi

# start cron
/usr/sbin/crond -f -l 8