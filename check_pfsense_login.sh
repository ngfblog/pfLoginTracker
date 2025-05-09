#!/bin/sh

# Script to check pfSense auth log and send Gotify alerts
# Place this file at: /root/Scripts/check_pfsense_login.sh
# Make it executable with: chmod +x /root/Scripts/check_pfsense_login.sh

# Paths
AUTH_LOG="/var/log/auth.log"
SYSTEM_LOG="/var/log/system.log" # For sshguard logs
LAST_CHECK_FILE="/var/tmp/last_auth_check"
LAST_SSHGUARD_CHECK_FILE="/var/tmp/last_sshguard_check"
ALERT_SCRIPT="/root/Scripts/gotify_auth_alert.sh"

# Create the last check files if they don't exist
if [ ! -f "$LAST_CHECK_FILE" ]; then
    touch -t "$(date -v-1d +%Y%m%d%H%M.%S)" "$LAST_CHECK_FILE"
fi

if [ ! -f "$LAST_SSHGUARD_CHECK_FILE" ]; then
    touch -t "$(date -v-1d +%Y%m%d%H%M.%S)" "$LAST_SSHGUARD_CHECK_FILE"
fi

# Find new login attempts since last check
LAST_CHECK=$(stat -f %m "$LAST_CHECK_FILE")
LAST_SSHGUARD_CHECK=$(stat -f %m "$LAST_SSHGUARD_CHECK_FILE")
CURRENT_TIME=$(date +%s)

# Update the timestamp of the last check files
touch "$LAST_CHECK_FILE"
touch "$LAST_SSHGUARD_CHECK_FILE"

# Look for successful logins
grep -a "Successful login" "$AUTH_LOG" | while read -r line; do
    # Extract timestamp from log line
    LOG_DATE=$(echo "$line" | awk '{print $1,$2,$3}')
    LOG_TIME=$(date -j -f "%b %d %H:%M:%S" "$LOG_DATE" +%s 2>/dev/null)
    
    # Process only new entries
    if [ "$LOG_TIME" -ge "$LAST_CHECK" ]; then
        # Extract username and IP
        USERNAME=$(echo "$line" | grep -o "user '[^']*'" | sed "s/user '//;s/'//")
        IP_ADDRESS=$(echo "$line" | grep -o "from: [0-9.]*" | sed "s/from: //")
        
        # Send alert
        if [ -n "$USERNAME" ] && [ -n "$IP_ADDRESS" ]; then
            "$ALERT_SCRIPT" "$USERNAME" "$IP_ADDRESS" "Authentication Success"
        fi
    fi
done

# Look for failed logins
grep -a "authentication error" "$AUTH_LOG" | while read -r line; do
    # Extract timestamp from log line
    LOG_DATE=$(echo "$line" | awk '{print $1,$2,$3}')
    LOG_TIME=$(date -j -f "%b %d %H:%M:%S" "$LOG_DATE" +%s 2>/dev/null)
    
    # Process only new entries
    if [ "$LOG_TIME" -ge "$LAST_CHECK" ]; then
        # Extract username and IP
        USERNAME=$(echo "$line" | grep -o "user '[^']*'" | sed "s/user '//;s/'//")
        IP_ADDRESS=$(echo "$line" | grep -o "from [0-9.]*" | sed "s/from //")
        
        # Send alert
        if [ -n "$USERNAME" ] && [ -n "$IP_ADDRESS" ]; then
            "$ALERT_SCRIPT" "$USERNAME" "$IP_ADDRESS" "Authentication Failure"
        fi
    fi
done

# Look for sshguard blocked IPs
grep -a "sshguard.*Blocking" "$SYSTEM_LOG" | while read -r line; do
    # Extract timestamp from log line
    LOG_DATE=$(echo "$line" | awk '{print $1,$2,$3}')
    LOG_TIME=$(date -j -f "%b %d %H:%M:%S" "$LOG_DATE" +%s 2>/dev/null)
    
    # Process only new entries
    if [ "$LOG_TIME" -ge "$LAST_SSHGUARD_CHECK" ]; then
        # Extract IP address
        IP_ADDRESS=$(echo "$line" | grep -o "[0-9]\+\.[0-9]\+\.[0-9]\+\.[0-9]\+" | head -1)
        SERVICE="sshd"
        
        # Try to extract service information from the log
        if echo "$line" | grep -q "ssh\|sshd"; then
            SERVICE="sshd"
        elif echo "$line" | grep -q "ftp"; then
            SERVICE="ftpd"
        else
            # Extract service from between brackets if possible
            SERVICE_RAW=$(echo "$line" | grep -o "\[[^]]*\]" | head -1)
            if [ -n "$SERVICE_RAW" ]; then
                SERVICE=$(echo "$SERVICE_RAW" | tr -d '[]')
            fi
        fi
        
        # Send alert
        if [ -n "$IP_ADDRESS" ]; then
            "$ALERT_SCRIPT" "blocked" "$IP_ADDRESS" "SSHGuard Block" "$SERVICE"
        fi
    fi
done

# Look for sshguard released IPs
grep -a "sshguard.*Releasing" "$SYSTEM_LOG" | while read -r line; do
    # Extract timestamp from log line
    LOG_DATE=$(echo "$line" | awk '{print $1,$2,$3}')
    LOG_TIME=$(date -j -f "%b %d %H:%M:%S" "$LOG_DATE" +%s 2>/dev/null)
    
    # Process only new entries
    if [ "$LOG_TIME" -ge "$LAST_SSHGUARD_CHECK" ]; then
        # Extract IP address
        IP_ADDRESS=$(echo "$line" | grep -o "[0-9]\+\.[0-9]\+\.[0-9]\+\.[0-9]\+" | head -1)
        
        # Send alert
        if [ -n "$IP_ADDRESS" ]; then
            "$ALERT_SCRIPT" "released" "$IP_ADDRESS" "SSHGuard Release" "N/A"
        fi
    fi
done
