#!/bin/bash
# migrate_spaces_to_s3.sh
#
# This script migrates files from a DigitalOcean Spaces bucket to an AWS S3 bucket.
# It prompts for all required credentials, builds a temporary rclone config file,
# and uses rclone’s built‑in progress display to show the migration progress.
#
# Requirements:
#   - rclone must be installed and available in the PATH.
#
# Usage:
#   ./migrate_spaces_to_s3.sh

# Check if rclone is installed
if ! command -v rclone >/dev/null 2>&1; then
    echo "Error: rclone is not installed. Please install rclone from https://rclone.org/downloads/ and try again."
    exit 1
fi

echo "=== DigitalOcean Spaces to AWS S3 Migration Script ==="
echo ""

# Prompt for DigitalOcean Spaces credentials and settings
read -p "Enter DigitalOcean Spaces Bucket Name: " DO_BUCKET
read -p "Enter DigitalOcean Spaces Endpoint URL (e.g., https://nyc3.digitaloceanspaces.com): " DO_ENDPOINT
read -p "Enter DigitalOcean Spaces Access Key: " DO_ACCESS_KEY
read -s -p "Enter DigitalOcean Spaces Secret Key: " DO_SECRET_KEY
echo -e "\n"

# Prompt for AWS S3 credentials and settings
read -p "Enter AWS S3 Bucket Name: " AWS_BUCKET
read -p "Enter AWS S3 Region (e.g., us-east-1): " AWS_REGION
read -p "Enter AWS S3 Access Key: " AWS_ACCESS_KEY
read -s -p "Enter AWS S3 Secret Key: " AWS_SECRET_KEY
read -s -p "Enter AWS Session Token Secret Key: " AWS_SESSION_TOKEN
echo -e "\n"

# Create a temporary rclone config file
TMP_RCLONE_CONFIG=$(mktemp /tmp/rclone_config.XXXXXX)
cat <<EOF > "$TMP_RCLONE_CONFIG"
[do]
type = s3
provider = DigitalOcean
env_auth = false
access_key_id = ${DO_ACCESS_KEY}
secret_access_key = ${DO_SECRET_KEY}
endpoint = ${DO_ENDPOINT}

[aws]
type = s3
provider = AWS
env_auth = false
access_key_id = ${AWS_ACCESS_KEY}
secret_access_key = ${AWS_SECRET_KEY}
aws_session_token = ${AWS_SESSION_TOKEN}
region = ${AWS_REGION}
EOF

echo "Temporary rclone config file created."

# Display the migration parameters
echo ""
echo "Migrating from DO Spaces bucket: ${DO_BUCKET}"
echo "          to AWS S3 bucket: ${AWS_BUCKET}"
echo ""

# Run the migration with rclone and display progress
echo "Starting migration. Please wait..."
rclone copy do:${DO_BUCKET} aws:${AWS_BUCKET} --config "$TMP_RCLONE_CONFIG" --progress

# Check for errors
if [ $? -ne 0 ]; then
    echo "Error: Migration encountered an issue."
    # Optionally, you could choose not to remove the temporary config on error for debugging.
    rm -f "$TMP_RCLONE_CONFIG"
    exit 1
fi

echo ""
echo "Migration completed successfully!"

# Clean up the temporary rclone config file
rm -f "$TMP_RCLONE_CONFIG"
echo "Temporary configuration file removed."
