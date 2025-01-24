source venv/bin/activate
source .env
gunicorn --bind 0.0.0.0:5000 --workers 4 server:app