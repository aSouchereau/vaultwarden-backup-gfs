#!/bin/sh

echo "╦  ╦╦ ╦       ╔╗ ╔═╗╔═╗╦╔═╦ ╦╔═╗       ╔═╗╔═╗╔═╗";
echo "╚╗╔╝║║║  ───  ╠╩╗╠═╣║  ╠╩╗║ ║╠═╝  ───  ║ ╦╠╣ ╚═╗";
echo " ╚╝ ╚╩╝       ╚═╝╩ ╩╚═╝╩ ╩╚═╝╩         ╚═╝╚  ╚═╝";


# populate output for dev testing
if [ "$APP_ENV" = "dev" ] && [ "$POPULATE_OUTPUT_ON_START" = true ]; then
    cd /app/scripts/dev
    sh populate_output.sh DELETEMYDATA
fi

# load correct cron schedules depending on environment
if [ "$APP_ENV" = "dev" ]; then
    echo "Loading development crontab schedules"
    /usr/bin/crontab /crontab-dev.txt
else
    echo "Loading crontab schedules"
    /usr/bin/crontab /crontab.txt
fi

# start cron
echo "Starting cron"
/usr/sbin/crond -f -l 8