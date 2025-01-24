# 1. Update apt and install OS-level dependencies
sudo apt-get update
sudo apt-get install -y \
    python3 \
    python3-venv \
    python3-pip \
    python3-dev \
    libpq-dev \
    build-essential \
    postgresql

# 2. Create and activate a virtual environment
cd /path/to/your/project
python3 -m venv venv
source venv/bin/activate

# 3. Upgrade pip/setuptools/wheel inside the venv
pip install --upgrade pip setuptools wheel

# 4. Install Python dependencies from requirements.txt
pip install -r requirements.txt
