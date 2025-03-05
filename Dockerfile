# Start from an official Ubuntu base image (you can use Debian or another base if you prefer)
FROM ubuntu:latest

# Suppress apt-get prompts and configure environment
ENV DEBIAN_FRONTEND=noninteractive
ENV DEBCONF_NONINTERACTIVE_SEEN=true

# Update package list and install required packages
RUN apt-get update && apt-get install -y \
    python3 \
    python3-venv \
    python3-pip \
    python3-dev \
    libpq-dev \
    build-essential \
    postgresql \
    nginx \
 && rm -rf /var/lib/apt/lists/*

# Set the working directory inside the container
WORKDIR /app

# Copy your project files into the container (including requirements.txt)
# If your Flask app code lives in the same directory, this will copy it all.
COPY . /app

# Create and activate a Python virtual environment, then install Python dependencies
RUN python3 -m venv venv \
 && . venv/bin/activate \
 && pip install --upgrade pip setuptools wheel \
 && pip install -r requirements.txt

# Create a minimal Nginx server block to proxy to Flask on port 5000
RUN printf 'server {\n\
    listen 80;\n\
    server_name _;\n\
    client_max_body_size 50M;\n\
\n\
    location / {\n\
        proxy_pass http://127.0.0.1:5000;\n\
        proxy_set_header Host $host;\n\
        proxy_set_header X-Real-IP $remote_addr;\n\
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;\n\
    }\n\
}\n' > /etc/nginx/sites-available/flask_app


# Enable the new site and remove the default
RUN rm -f /etc/nginx/sites-enabled/default \
 && ln -sfn /etc/nginx/sites-available/flask_app /etc/nginx/sites-enabled/flask_app \
 && nginx -t \ 
 && chmod +x start.sh

# Expose port 80 (for Nginx) and port 5000 (for Flask), if you want to access them directly
EXPOSE 80
EXPOSE 5000

# CMD to:
# 1. Start PostgreSQL in the background
# 2. Activate your virtual env, run Flask on port 5000, also in the background
# 3. Keep nginx in the foreground (daemon off) so the container stays alive
ENTRYPOINT /app/start.sh
