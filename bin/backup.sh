#!/bin/bash
BACKUP_DIR="/home/labex/project/backup"
mkdir -p $BACKUP_DIR
DATE=$(date +%Y-%m-%d)
BACKUP_FILE="$BACKUP_DIR/logs_backup_$DATE.tar.gz"
sudo tar -czf $BACKUP_FILE /opt/catolica_market/data/ 2>/dev/null
sudo chown labex:labex $BACKUP_FILE
chmod 644 $BACKUP_FILE
echo "Log backup created: $BACKUP_FILE"
