#!/bin/sh

# For dev purposes only

# WARNING: This script will affect data in the output folder. Do not use it in production

# As a safety precaution, this script will only run when the global env variable TEST_LOCK is set to "unlocked", and the first argument passed set to "DELETEMYDATA".

OUTPUT_DIR=/app/output

function clear_output() {
    rm -rf "${OUTPUT_DIR}"
    mkdir -p "${OUTPUT_DIR}"
    mkdir "${OUTPUT_DIR}/daily"
    mkdir "${OUTPUT_DIR}/weekly"
    mkdir "${OUTPUT_DIR}/monthly"
}

if [ "$TEST_LOCK" = "unlocked" ] && [ "$1" = "DELETEMYDATA" ]; then
    clear_output

    while IFS= read -r filename; do
        touch "${OUTPUT_DIR}/daily/${filename}"
    done < "daily-filenames.txt"

    while IFS= read -r filename; do
        touch "${OUTPUT_DIR}/weekly/${filename}"
    done < "weekly-filenames.txt"

    while IFS= read -r filename; do
        touch "${OUTPUT_DIR}/monthly/${filename}"
    done < "monthly-filenames.txt"
else
    echo "Conditions not met, test script refuses to run. Check line 7 of /app/scripts/tests/cleanup_test.sh for details"
fi

