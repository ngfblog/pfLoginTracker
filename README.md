# pfSense Authentication Monitoring System

A lightweight system for monitoring authentication events on pfSense firewalls with email and Gotify notifications.

## Overview

This project provides two shell scripts that work together to:

1. Monitor the pfSense authentication log file (`/var/log/auth.log`) for successful and failed login attempts
2. Send notifications via:
   - Email (using pfSense's built-in notification system)
   - [Gotify](https://gotify.net/) push notifications

## Features

- Track successful and failed login attempts
- Send email notifications using your pfSense SMTP settings
- Send push notifications via Gotify
- Keep track of processed log entries to avoid duplicate notifications
- Configurable for your environment

## Installation

### Prerequisites

- A pfSense firewall with shell access
- [Gotify](https://gotify.net/) server (optional but recommended)
- SMTP configuration set up in pfSense System > Advanced > Notifications

### Setup

1. Create a directory for the scripts:
   ```
   mkdir -p /root/Scripts
   ```

2. Create the `check_pfsense_login.sh` script:
   ```
   vi /root/Scripts/check_pfsense_login.sh
   ```
   Copy the contents from the file in this repository

3. Create the `gotify_auth_alert.sh` script:
   ```
   vi /root/Scripts/gotify_auth_alert.sh
   ```
   Copy the contents from the file in this repository

4. Make both scripts executable:
   ```
   chmod +x /root/Scripts/check_pfsense_login.sh
   chmod +x /root/Scripts/gotify_auth_alert.sh
   ```

5. Edit the `gotify_auth_alert.sh` script to update:
   - Your Gotify server address
   - Your Gotify application token

6. Set up a cron job to run the monitoring script periodically. Add the following to System > Cron:
   - Command: `/root/Scripts/check_pfsense_login.sh`
   - Schedule: `*/5 * * * *` (runs every 5 minutes)

## Configuration

### Gotify Configuration

In `gotify_auth_alert.sh`, update these variables:

```sh
# Gotify Configuration
GOTIFY_SERVER="http://your-gotify-server:8070"  # Your Gotify server address
GOTIFY_TOKEN="YourGotifyApplicationToken"       # Your application token
```

### Email Configuration

The script uses pfSense's built-in notification system, so make sure your SMTP settings are correctly configured in pfSense at:

System > Advanced > Notifications > E-Mail

## How It Works

1. `check_pfsense_login.sh` scans the auth.log file for new entries since the last check
2. When it finds a login event (success or failure), it extracts the username and IP address
3. It calls `gotify_auth_alert.sh` with these details
4. `gotify_auth_alert.sh` sends notifications to both Gotify and email

## Customizing

You can customize the scripts to:

- Change notification priorities
- Add geo-location information for IP addresses
- Filter out specific users or IP addresses
- Adjust the notification format

## Troubleshooting

Check the system logs for error messages:

```
tail -f /var/log/system.log | grep pfsense_auth_alert
```

## License

MIT License - See LICENSE file for details.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.
