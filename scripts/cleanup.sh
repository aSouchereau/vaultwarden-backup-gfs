echo "Cleaning up expired backups"


# Define retention periods in days
DAILY_RETENTION=$(($DAILY_RETENTION * 86400))   # Keep daily backups for 30 days
WEEKLY_RETENTION=30  # Keep weekly backups for 30 days
MONTHLY_RETENTION=60 # Keep monthly backups for 60 days

if [ "$APP_ENV" = "dev" ]; then
    NOW=1697457600 # 2023-10-16 1200hr GMT
else
    NOW=$(date +%s) 
fi


# Remove daily backups older than the retention period
function daily() {
    cd "${OUTPUT_DIR}"
    retentionCutoff=$(date -u -d "@$((${NOW} - ${DAILY_RETENTION}))" +%s) # get the unix timestamp for exactly 30 days ago
    # retentionCutoff=$(date -u -d "@$(($(date +%s) - ${DAILY_RETENTION}))" +%s) # get the unix timestamp for exactly 30 days ago
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

# Remove weekly backups older than the retention period
function weekly() {
    cd "${OUTPUT_DIR}"
    echo ""
}

# Remove monthly backups older than the retention period
function monthly() {
    cd "${OUTPUT_DIR}"
    echo ""
}

case "$BACKUP_TYPE" in
    daily)
        daily
        ;;
    weekly)
        weekly
        ;;
    monthly)
        monthly
        ;;
    *)
        echo "Invalid backup type. Skipping cleanup"
        exit 1
        ;;
esac