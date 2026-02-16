#!/bin/bash

# Load the sensitive variables from the .env file
source .env

LOG=$LOG_PATH
DATE=$(date '+%Y-%m-%d %H:%M:%S')

echo "=== $DATE ===" >> $LOG

# 1. Ping website
if ! curl -s --head $WEBSITE_NAME | grep "200 OK" > /dev/null; then
    echo "Website not responding!" | tee -a $LOG | mail -s "ALERT: Website down" $EMAIL
    
    # 2. Check service_name.service on server
    if ! systemctl is-active --quiet $SERVICE_NAME.service; then
        echo "$SERVICE_NAME service on server is down!" | tee -a $LOG | mail -s "ALERT: $SERVICE_NAME.service down" $EMAIL
    fi
fi

# 3. Laptop checks
# CPU temp with sensors
TEMP=$(sensors | grep 'Package id 0:' | awk '{print $4}' | tr -d '+°C')
MAX_TEMP=80  # adjust to your safe threshold

if [ "$TEMP" -gt "$MAX_TEMP" ]; then
    echo "Laptop CPU temp too high: $TEMP°C" | tee -a $LOG | mail -s "ALERT: Laptop overheating" $EMAIL
fi

# service_name_2 service
if ! systemctl is-active --quiet $SERVICE_NAME_2.service; then
    echo "$SERVICE_NAME_2.service is down!" | tee -a $LOG | mail -s "ALERT: $SERVICE_NAME_2.service down" $EMAIL
fi

# 4. Daily OK report
if [ "$(date +%H:%M)" == "09:00" ]; then
    echo "All systems running fine at $DATE" | mail -s "Daily Monitoring Report" $EMAIL
fi