#!/usr/bin/env bash
cd /app
source venv/bin/activate
# source .env
nohup gunicorn --bind 0.0.0.0:5000 --workers 4 server:app > gunicorn.log 2>&1 &
nohup nginx -g 'daemon off;' >> gunicorn.log 2>&1 &
tail -f gunicorn.log