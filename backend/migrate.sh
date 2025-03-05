#!/bin/bash
# migrate_db.sh
#
# This script dumps a PostgreSQL database from a source host and restores it
# to a destination host. It prompts for host, database name, user, and password.
# It uses a progress bar (via pv, if installed) or a simple spinner if pv isn’t available.

# Check required commands
command -v pg_dump >/dev/null 2>&1 || { echo >&2 "Error: pg_dump is not installed. Aborting."; exit 1; }
command -v psql >/dev/null 2>&1 || { echo >&2 "Error: psql is not installed. Aborting."; exit 1; }

# Spinner function for progress indication when pv is not available
spinner() {
    local pid=$1
    local delay=0.1
    local spinstr='|/-\'
    while kill -0 "$pid" 2>/dev/null; do
        for (( i=0; i<${#spinstr}; i++ )); do
            printf "\r[%c] Processing..." "${spinstr:$i:1}"
            sleep $delay
        done
    done
    printf "\rDone!            \n"
}

# Prompt for source database details
echo "Enter source database connection details:"
read -p "Source Host: " SRC_HOST
read -p "Source Database Name: " SRC_DB
read -p "Source User: " SRC_USER
read -s -p "Source Password: " SRC_PASSWORD
echo -e "\n"

# Prompt for destination database details
echo "Enter destination database connection details:"
read -p "Destination Host: " DEST_HOST
read -p "Destination Database Name: " DEST_DB
read -p "Destination User: " DEST_USER
read -s -p "Destination Password: " DEST_PASSWORD
echo -e "\n"

# Set dump file name
DUMP_FILE="dump.sql"

###################################
# Step 1: Dump the source database
###################################
echo "Starting database dump from source..."
if command -v pv >/dev/null 2>&1; then
    echo "Using pv for progress display."
    # Note: Without a known total size, pv will display a transfer rate and elapsed time.
    PGPASSWORD="$SRC_PASSWORD" pg_dump -h "$SRC_HOST" -U "$SRC_USER" "$SRC_DB" | pv > "$DUMP_FILE"
    DUMP_EXIT_CODE=${PIPESTATUS[0]}
else
    echo "pv not found; using spinner..."
    # Run pg_dump in background and show spinner
    PGPASSWORD="$SRC_PASSWORD" pg_dump -h "$SRC_HOST" -U "$SRC_USER" "$SRC_DB" > "$DUMP_FILE" &
    dump_pid=$!
    spinner $dump_pid
    wait $dump_pid
    DUMP_EXIT_CODE=$?
fi

if [ $DUMP_EXIT_CODE -ne 0 ]; then
    echo "Error: pg_dump failed with exit code $DUMP_EXIT_CODE"
    exit 1
fi
echo "Database dump completed successfully."
echo

######################################
# Step 2: Restore the dump to target
######################################
echo "Starting restore to destination database..."
if command -v pv >/dev/null 2>&1; then
    echo "Using pv for progress display."
    # Get the dump file size so that pv can show progress
    filesize=$(stat -c %s "$DUMP_FILE")
    pv -s "$filesize" "$DUMP_FILE" | PGPASSWORD="$DEST_PASSWORD" psql -h "$DEST_HOST" -U "$DEST_USER" "$DEST_DB"
    RESTORE_EXIT_CODE=${PIPESTATUS[1]}
else
    echo "pv not found; using spinner..."
    PGPASSWORD="$DEST_PASSWORD" psql -h "$DEST_HOST" -U "$DEST_USER" "$DEST_DB" < "$DUMP_FILE" &
    restore_pid=$!
    spinner $restore_pid
    wait $restore_pid
    RESTORE_EXIT_CODE=$?
fi

if [ $RESTORE_EXIT_CODE -ne 0 ]; then
    echo "Error: Restore failed with exit code $RESTORE_EXIT_CODE"
    exit 1
fi
echo "Database restore completed successfully."
echo

######################################
# Optional: Clean up the dump file
######################################
read -p "Do you want to remove the dump file ($DUMP_FILE)? (y/N): " REMOVE_DUMP
if [[ "$REMOVE_DUMP" =~ ^[Yy]$ ]]; then
    rm "$DUMP_FILE"
    echo "Dump file removed."
fi

echo "Database migration completed successfully."
