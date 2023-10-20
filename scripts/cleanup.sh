echo "Cleaning up expired backups"


# Convert retention values from days to seconds (originals defined in docker-compose/docker run)
DAILY_RETENTION=$(($DAILY_RETENTION * 86400))
WEEKLY_RETENTION=$(($WEEKLY_RETENTION * 604800))
MONTHLY_RETENTION=$(($MONTHLY_RETENTION * 2678400))

# Set current date to fixed past date so I dont have to keep updating list of filenames for dev environments
if [ "$APP_ENV" = "dev" ]; then
    NOW=1697457600 # 2023-10-16 1200hr GMT
else
    NOW=$(date +%s) 
fi


# Remove backups older than the retention period
function cleanup() {
    cd "${OUTPUT_DIR}"
    retentionCutoff=$(date -u -d "@$((${NOW} - ${1} ))" +%s) # get epoch time for cutoff date of provided retention period
    echo "${retentionCutoff}"
    for file in *-*-*_vw-data.tar; do
        fdate=$(echo $file | cut -d'_' -f1) # extract timestamp from filename
        echo "fdate: ${fdate}"
        fsec=$(date +%s --date=${fdate}) # convert filename timestamp into unix timestamp
        echo "fsec: ${fsec}"
        if [[ $fsec -lt $retentionCutoff ]]; then # remove file if timestamp older than retention cutoff
            echo "rm $file"
        fi
    done
}


case "$BACKUP_TYPE" in
    daily)
        cleanup "$DAILY_RETENTION"
        ;;
    weekly)
        cleanup "$WEEKLY_RETENTION"
        ;;
    monthly)
        cleanup "$MONTHLY_RETENTION"
        ;;
    *)
        echo "Invalid backup type. Skipping cleanup"
        exit 1
        ;;
esac