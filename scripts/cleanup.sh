echo "cleaning up expired backups"

# Set default backup minimums
MIN_DAILY_BACKUPS="${MIN_DAILY_BACKUPS:-$DAILY_RETENTION}"
MIN_WEEKLY_BACKUPS="${MIN_WEEKLY_BACKUPS:-$WEEKLY_RETENTION}"
MIN_MONTHLY_BACKUPS="${MIN_MONTHLY_BACKUPS:-$MONTHLY_RETENTION}"

# Convert retention values from days to seconds so it can be easily compared to file timestamps
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
    excessFiles=$(find "$OUTPUT_DIR" -maxdepth 1 -type f -name '*-*-*_vw-data.tar' -exec basename {} \; | sort -r | tail -n +$((${2} + 1)))

    for file in $excessFiles; do
        fdate=$(echo $file | cut -d'_' -f1) # extract timestamp from filename
        fsec=$(date +%s --date=${fdate}) # convert filename timestamp into unix timestamp

        if [[ $fsec -lt $retentionCutoff ]]; then # remove file if timestamp older than retention cutoff
            echo "Removed: $file"
            rm $file
        fi
    done
}


case "$BACKUP_TYPE" in
    daily)
        cleanup "$DAILY_RETENTION" "$MIN_DAILY_BACKUPS"
        ;;
    weekly)
        cleanup "$WEEKLY_RETENTION" "$MIN_WEEKLY_BACKUPS"
        ;;
    monthly)
        cleanup "$MONTHLY_RETENTION" "$MIN_MONTHLY_BACKUPS"
        ;;
    *)
        echo "Invalid backup type. Skipping cleanup"
        exit 1
        ;;
esac