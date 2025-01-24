#!/usr/bin/env bash

# Exit script on any error
set -e

# 1. Update and install system-level dependencies
sudo apt-get update
sudo apt-get install -y \
    python3 \
    python3-venv \
    python3-pip \
    python3-dev \
    libpq-dev \
    build-essential \
    postgresql \
    nginx

# 2. Create project directory (if you haven’t already)
PROJECT_DIR="./"
sudo chown "$USER:$USER" "$PROJECT_DIR"
python3 -m venv venv
source venv/bin/activate

# 5. Upgrade pip, setuptools, and wheel
pip install --upgrade pip setuptools wheel

# 6. Install Python dependencies
pip install -r requirements.txt

# 7. Create a minimal Nginx server block config
#    This config proxies all traffic from port 80 to localhost:5000.
#    If you have an existing domain, replace `server_name _;` with `server_name example.com;`
NGINX_CONF="/etc/nginx/sites-available/flask_app"
sudo bash -c "cat > $NGINX_CONF" <<EOF
server {
    listen 80;
    server_name _;  # or your domain/IP

    location / {
        proxy_pass http://127.0.0.1:5000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }
}
EOF

# 8. Enable the new site and disable the default site
sudo rm -f /etc/nginx/sites-enabled/default
sudo ln -sfn "$NGINX_CONF" /etc/nginx/sites-enabled/flask_app

# 9. Test Nginx config and reload
sudo nginx -t
sudo systemctl restart nginx
