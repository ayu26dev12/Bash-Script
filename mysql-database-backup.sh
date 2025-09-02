#!/bin/bash

# === Configuration ===
DB_HOST="public_ip"
DB_USER="username"
DB_NAME="database name"
DB_PASS="database password"  
S3_BUCKET="bucket_name"
DATE=$(date +%F-%H-%M-%S)
DUMP_PATH="/tmp/${DB_NAME}-${DATE}.sql"

# === Dump Database ===
mysqldump -h $DB_HOST -u $DB_USER -p$DB_PASS $DB_NAME > $DUMP_PATH

# === Upload to S3 ===
aws s3 cp $DUMP_PATH s3://$S3_BUCKET/folder_name/${DB_NAME}-${DATE}.sql

# === Clean Up Local File ===
rm -f $DUMP_PATH

# === Optional Logging ===
echo "[$(date)] Backup completed for $DB_NAME and uploaded to S3." >> /var/log/rds_backup.log
