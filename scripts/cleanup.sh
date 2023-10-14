echo "Cleaning up expired backups"

OUTPUT_DIR2=/app/test_output

# Define retention periods in days
DAILY_RETENTION=7   # Keep daily backups for 7 days
WEEKLY_RETENTION=30  # Keep weekly backups for 30 days
MONTHLY_RETENTION=365 # Keep monthly backups for 1 year

function daily() {
    find "$OUTPUT_DIR2" -type f -name '*_data.tar' -mtime +$DAILY_RETENTION -exec rm {} \;
}