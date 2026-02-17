#!/bin/bash

# Load the sensitive variables from the .env file
source /home/monitoring/scripts/Monitor/.env

LOG="$LOG_PATH"
DATE=$(date '+%Y-%m-%d %H:%M:%S')

echo "=== $DATE ===" >> "$LOG"

# Initialize status report
STATUS_REPORT="Monitoring Report - $DATE\n\n"

# 1. Check website
WEBSITE_STATUS="✓ OK"
if ! curl -s --head $WEBSITE_NAME | grep "200 OK" > /dev/null; then
    WEBSITE_STATUS="✗ DOWN"
    echo "Website not responding!" | tee -a $LOG | mail -s "ALERT: Website down" $EMAIL
fi
STATUS_REPORT+="Website ($WEBSITE_NAME): $WEBSITE_STATUS\n"

# 2. Check laptop CPU temperature
TEMP=$(sensors | grep 'Package id 0:' | awk '{print $4}' | tr -d '+°C')
TEMP=${TEMP%.*}  # removes decimal part
MAX_TEMP=80  # adjust to your safe threshold

TEMP_STATUS="✓ Normal"
if [ "$TEMP" -gt "$MAX_TEMP" ]; then
    TEMP_STATUS="✗ HIGH"
    echo "Laptop CPU temp too high: $TEMP°C" | tee -a $LOG | mail -s "ALERT: Laptop overheating" $EMAIL
fi
STATUS_REPORT+="CPU Temperature: ${TEMP}°C ($TEMP_STATUS, Max: ${MAX_TEMP}°C)\n"

# 3. Check service
SERVICE_STATUS="✓ Active"
if ! systemctl is-active --quiet $SERVICE_NAME_2.service; then
    SERVICE_STATUS="✗ Inactive"
    echo "$SERVICE_NAME_2.service is down!" | tee -a $LOG | mail -s "ALERT: $SERVICE_NAME_2.service down" $EMAIL
fi
STATUS_REPORT+="Service ($SERVICE_NAME_2): $SERVICE_STATUS\n"

# Send summary if running between 09:00 and 09:10
CURRENT_HOUR=$(date +%H)
CURRENT_MIN=$(date +%M)
if [ "$CURRENT_HOUR" == "09" ] && [ "$CURRENT_MIN" -lt "10" ]; then
    echo -e "$STATUS_REPORT" | mail -s "Daily System Monitoring Report" $EMAIL
fi
