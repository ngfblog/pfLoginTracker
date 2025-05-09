# Configuration Guide

This document explains how to customize and extend the pfSense Authentication Monitoring System.

## Basic Configuration

### Gotify Settings

In `gotify_auth_alert.sh`, you can customize the Gotify notification:

```bash
# Gotify Configuration
GOTIFY_SERVER="http://your-gotify-server:8070"  # Your Gotify server address
GOTIFY_TOKEN="YourGotifyApplicationToken"       # Your application token
```

You can also adjust the notification priority (default is 5, which represents high priority):

```bash
RESPONSE=$(curl -X POST \
  -F "title=$TITLE" \
  -F "message=$MESSAGE" \
  -F "priority=5" \  # Change this value (1-10)
  # ...rest of the command
```

### Notification Frequency

By default, the cron job is set to run every 5 minutes. You can adjust this by changing the cron schedule:

- Every minute: `* * * * *`
- Every 10 minutes: `*/10 * * * *`
- Every hour: `0 * * * *`

## Advanced Customizations

### Adding GeoIP Information to Alerts

You can enhance the alerts with geographic information about the IP address by installing the GeoIP package and modifying the script. Add this to the `gotify_auth_alert.sh` script:

```bash
# Check if geoiplookup is available
if command -v geoiplookup >/dev/null 2>&1; then
    GEO_INFO=$(geoiplookup "$IP_ADDRESS" | awk -F ": " '{print $2}')
    MESSAGE="$MESSAGE
Location: $GEO_INFO"
fi
```

### Filtering Out Known IPs or Users

To avoid alerts for specific users or IPs (like your own administrative access), add this code to `check_pfsense_login.sh` before sending alerts:

```bash
# Whitelist of IPs and users that won't trigger alerts
WHITELIST_IPS="192.168.1.10 10.0.0.5"
WHITELIST_USERS="admin"

# Check if IP is in whitelist
is_ip_whitelisted() {
    for white_ip in $WHITELIST_IPS; do
        if [ "$white_ip" = "$1" ]; then
            return 0
        fi
    done
    return 1
}

# Check if user is in whitelist
is_user_whitelisted() {
    for white_user in $WHITELIST_USERS; do
        if [ "$white_user" = "$1" ]; then
            return 0
        fi
    done
    return 1
}

# Then in your processing loops, add:
if ! is_ip_whitelisted "$IP_ADDRESS" && ! is_user_whitelisted "$USERNAME"; then
    "$ALERT_SCRIPT" "$USERNAME" "$IP_ADDRESS" "Authentication Success"
fi
```

### Adding Multiple Notification Channels

You can extend the script to notify through additional channels like Telegram, Slack, or Discord by adding similar notification blocks in `gotify_auth_alert.sh`:

```bash
# Example for Telegram notifications
TELEGRAM_BOT_TOKEN="your-bot-token"
TELEGRAM_CHAT_ID="your-chat-id"

# Send to Telegram
curl -s -X POST \
    "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage" \
    -d chat_id="$TELEGRAM_CHAT_ID" \
    -d text="$TITLE

$MESSAGE" \
    -d parse_mode="Markdown" >/dev/null 2>&1
```

### Custom Alert Levels Based on Event Type

You can customize the alert priority based on the type of event:

```bash
# Set priority based on event type
if [ "$EVENT_TYPE" = "Authentication Failure" ]; then
    PRIORITY=8  # Higher priority for failures
else
    PRIORITY=5  # Normal priority for successes
fi

# Then use $PRIORITY in your Gotify API call
```

### Adding Rate Limiting for Alerts

To prevent alert flooding during brute force attacks, add rate limiting:

```bash
# Rate limiting for alerts
RATE_LIMIT_FILE="/var/tmp/auth_alert_ratelimit"
MAX_ALERTS=5
TIME_WINDOW=300  # 5 minutes

# Check if rate limit file exists and create it if not
if [ ! -f "$RATE_LIMIT_FILE" ]; then
    echo "0 0" > "$RATE_LIMIT_FILE"
fi

# Read rate limit data
read ALERT_COUNT TIMESTAMP < "$RATE_LIMIT_FILE"
CURRENT_TIME=$(date +%s)

# Reset counter if time window has passed
if [ $((CURRENT_TIME - TIMESTAMP)) -gt $TIME_WINDOW ]; then
    ALERT_COUNT=0
    TIMESTAMP=$CURRENT_TIME
fi

# Increment counter
ALERT_COUNT=$((ALERT_COUNT + 1))

# Update rate limit file
echo "$ALERT_COUNT $TIMESTAMP" > "$RATE_LIMIT_FILE"

# Check if we're over the limit
if [ $ALERT_COUNT -gt $MAX_ALERTS ]; then
    MESSAGE="ALERT: High volume of authentication events detected! $ALERT_COUNT events in the last 5 minutes.
    
$MESSAGE"
fi
```

## Performance Considerations

If you have a high-traffic system with many login attempts, consider optimizing the script:

1. Increase the checking interval (e.g., check every 15 minutes instead of 5)
2. Use more efficient grep patterns
3. Add rate limiting as shown above
4. Consider rotating or truncating the auth.log file regularly
