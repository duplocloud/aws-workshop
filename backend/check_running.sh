#!/bin/bash
#
# check_gunicorn.sh
#
# This script checks if the gunicorn process is running.
# If not, it changes to /app and executes start.sh.

# Look for the exact gunicorn command using pgrep with the -f option.
if ! pgrep -f "/app/venv/bin/gunicorn --bind 0.0.0.0:5000 --workers 4 server:app" > /dev/null; then
    echo "$(date): Gunicorn is not running, starting it now..."
    cd /app && bash start.sh
else
    echo "$(date): Gunicorn is running."
fi