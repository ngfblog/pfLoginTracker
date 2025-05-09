#!/bin/sh

# Enhanced Alert Script for pfSense Authentication
# Place this file at: /root/Scripts/gotify_auth_alert.sh
# Make it executable with: chmod +x /root/Scripts/gotify_auth_alert.sh

# Gotify Configuration - Replace with your server details
GOTIFY_SERVER="http://your-gotify-server:8070"  # Your Gotify server address
GOTIFY_TOKEN="YourGotifyApplicationToken"       # Your application token

# Get authentication details from system
USERNAME="$1"
IP_ADDRESS="$2"
EVENT_TYPE="$3"  # For example: "Authentication Success" or "Authentication Failure"
HOSTNAME=$(hostname)

# Build message
TITLE="Security Alert from $HOSTNAME"
MESSAGE="Event: $EVENT_TYPE
User: $USERNAME
IP Address: $IP_ADDRESS
Time: $(date)"

# 1. Send notification to Gotify
FULL_URL="$GOTIFY_SERVER/message?token=$GOTIFY_TOKEN"
logger -t pfsense_auth_alert "Attempting to send to Gotify: $FULL_URL"

RESPONSE=$(curl -X POST \
  -F "title=$TITLE" \
  -F "message=$MESSAGE" \
  -F "priority=5" \
  --write-out "%{http_code}" \
  --silent \
  --output /tmp/gotify_response \
  --connect-timeout 10 \
  "$FULL_URL")

# Log the Gotify response
if [ "$RESPONSE" -eq 200 ]; then
    logger -t pfsense_auth_alert "Gotify notification sent successfully"
else
    logger -t pfsense_auth_alert "Failed to send Gotify notification. HTTP code: $RESPONSE"
    
    # Log more details for debugging
    if [ -f "/tmp/gotify_response" ]; then
        RESP_CONTENT=$(cat /tmp/gotify_response)
        logger -t pfsense_auth_alert "Response content: $RESP_CONTENT"
    fi
fi

# 2. Use pfSense's built-in notification system to send email
# Create a PHP script to send email via pfSense's notification system
PHP_SCRIPT=$(mktemp)
cat > "$PHP_SCRIPT" << 'EOF'
#!/usr/local/bin/php
<?php
require_once("config.inc");
require_once("notices.inc");
require_once("util.inc");

$event_type = $argv[1];
$username = $argv[2];
$ip_address = $argv[3];
$hostname = $argv[4];
$time = $argv[5];

$message = "Event Type: {$event_type}\n";
$message .= "User: {$username}\n";
$message .= "IP Address: {$ip_address}\n";
$message .= "System: {$hostname}\n";
$message .= "Time: {$time}\n";
$message .= "\nThis notification was generated automatically by the authentication monitoring system.";

// Create unique ID for notification
$id = "AuthAlert_" . time();
$subject = "SECURITY ALERT: {$event_type} on {$hostname}";

// Send notification (will use configured SMTP settings)
send_smtp_message($message, $subject, '', '', '', $error);
if ($error) {
    log_error("Failed to send email notification: " . $error);
} else {
    log_error("Email notification sent successfully using pfSense's notification system");
}

// Also add to notification system
notify_via_smtp($id, $subject, $message);
file_notice($id, $subject, $message, "Authentication Alert");
?>
EOF

# Make the script executable
chmod +x "$PHP_SCRIPT"

# Run the PHP script with the authentication details
logger -t pfsense_auth_alert "Attempting to send email via pfSense notification system"
/usr/local/bin/php "$PHP_SCRIPT" "$EVENT_TYPE" "$USERNAME" "$IP_ADDRESS" "$HOSTNAME" "$(date)" >/dev/null 2>&1

# Check if the script executed successfully
if [ $? -eq 0 ]; then
    logger -t pfsense_auth_alert "Email notification request sent to pfSense system"
else
    logger -t pfsense_auth_alert "Failed to execute PHP script for email notification"
fi

# Clean up
rm -f "$PHP_SCRIPT"
