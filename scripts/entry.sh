#!/bin/sh

# populate output for dev testing
cd /app/scripts/tests
sh cleanup_test.sh DELETEMYDATA

# start cron
/usr/sbin/crond -f -l 8