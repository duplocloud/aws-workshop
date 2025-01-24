source venv/bin/activate
source .env
nohup gunicorn --bind 0.0.0.0:5000 --workers 4 server:app > gunicorn.log 2>&1 &