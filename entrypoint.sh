#!/usr/bin/env bash

set -euo pipefail

# Create a timestamp for versioning backups
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_DIR="backup_$TIMESTAMP"

# Dump the MySQL database
mydumper --host "$MYSQL_HOST" --user "$MYSQL_USER" --password "$MYSQL_PASSWORD" --port "$MYSQL_PORT" --database "$MYSQL_DATABASE" -C -c -o "$BACKUP_DIR"

# Configure rclone for Cloudflare R2
rclone config touch
cat <<EOF > ~/.config/rclone/rclone.conf
[remote]
type = s3
provider = Cloudflare
access_key_id = $R2_ACCESS_KEY_ID
secret_access_key = $R2_SECRET_ACCESS_KEY
endpoint = $R2_ENDPOINT
acl = private
EOF

# Sync the backup to R2 with the timestamped directory name
rclone sync "$BACKUP_DIR" remote:"$R2_BUCKET/$R2_PATH/$BACKUP_DIR"

# Remove backups older than 7 days from the R2 bucket
rclone delete --min-age 7d remote:"$R2_BUCKET/$R2_PATH"

# Clean up local backup folder
rm -rf "$BACKUP_DIR"
