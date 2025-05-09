# Installation Guide for pfSense Authentication Monitoring

This guide provides detailed steps to install and configure the pfSense Authentication Monitoring System.

## Step 1: Access Your pfSense Shell

You can access the shell via:
- SSH connection to your pfSense
- Web interface: System > Advanced > Command Prompt
- Console access

## Step 2: Create the Scripts Directory

```bash
mkdir -p /root/Scripts
```

## Step 3: Create the Scripts

### Create check_pfsense_login.sh

```bash
vi /root/Scripts/check_pfsense_login.sh
```

Copy the content from `check_pfsense_login.sh` in this repository and paste it into the file.

### Create gotify_auth_alert.sh

```bash
vi /root/Scripts/gotify_auth_alert.sh
```

Copy the content from `gotify_auth_alert.sh` in this repository and paste it into the file.

## Step 4: Make the Scripts Executable

```bash
chmod +x /root/Scripts/check_pfsense_login.sh
chmod +x /root/Scripts/gotify_auth_alert.sh
```

## Step 5: Configure Gotify Settings

Edit the `gotify_auth_alert.sh` script:

```bash
vi /root/Scripts/gotify_auth_alert.sh
```

Update these variables with your Gotify server information:

```bash
# Gotify Configuration
GOTIFY_SERVER="http://your-gotify-server:8070"  # Your Gotify server address
GOTIFY_TOKEN="YourGotifyApplicationToken"       # Your application token
```

## Step 6: Configure pfSense Email Settings

1. Navigate to System > Advanced > Notifications
2. Configure the Email settings:
   - Notification E-Mail server: Your SMTP server
   - Port: Your SMTP port (usually 25, 465, or 587)
   - Authentication username: Your email username
   - Authentication password: Your email password
   - Notification E-Mail address: The email address to receive notifications
   - From E-Mail address: The sender email address

## Step 7: Set Up a Cron Job

1. Navigate to System > Cron
2. Click "Add" to create a new cron job
3. Fill in the following:
   - Command: `/root/Scripts/check_pfsense_login.sh`
   - Description: "Check Authentication Log"
   - Minute: `*/5` (every 5 minutes)
   - Hour, Day of Month, Month of Year, Day of Week: * (every value)
4. Click "Save"

## Step 8: Test the Setup

To test if everything is working correctly:

1. Try logging into your pfSense with a valid username and password
2. Wait for the cron job to run (or run the script manually)
3. Check if you receive notifications via:
   - Email (to the address configured in pfSense notifications)
   - Gotify (in your Gotify app/client)

## Troubleshooting

If notifications aren't working:

1. Check the system logs:
   ```bash
   tail -f /var/log/system.log | grep pfsense_auth_alert
   ```

2. Run the scripts manually to see any error output:
   ```bash
   /root/Scripts/check_pfsense_login.sh
   ```

3. Verify your Gotify server is accessible from pfSense:
   ```bash
   curl -v http://your-gotify-server:8070/version
   ```

4. Test the email configuration in pfSense:
   - Go to Diagnostics > Test Port
   - Enter your SMTP server and port
   - Click "Test" to verify connectivity
