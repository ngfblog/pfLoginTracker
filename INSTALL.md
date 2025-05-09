# Coding Standards for pfLoginTracker

This document outlines coding standards and best practices for the pfLoginTracker project, which monitors authentication events on pfSense firewalls.

## 1. Shell Script Standards

### 1.1 Script Header
All shell scripts should include:
- Shebang line (`#!/bin/sh`)
- Brief description of what the script does
- Installation path information
- Execution permission requirements

Example:
```sh
#!/bin/sh

# Script to check pfSense auth log and send alerts
# Place this file at: /root/Scripts/check_pfsense_login.sh
# Make it executable with: chmod +x /root/Scripts/check_pfsense_login.sh
```

### 1.2 Variables
- Use uppercase for global constants and configuration variables
- Use lowercase for local variables
- Group related variables together with comments
- Always include default values where appropriate

Example:
```sh
# Paths
AUTH_LOG="/var/log/auth.log"
LAST_CHECK_FILE="/var/tmp/last_auth_check"
```

### 1.3 Error Handling
- Always check for errors after critical operations
- Log error messages with appropriate context
- Use conditional checks for file existence before operations

Example:
```sh
if [ ! -f "$LAST_CHECK_FILE" ]; then
    touch -t "$(date -v-1d +%Y%m%d%H%M.%S)" "$LAST_CHECK_FILE"
fi
```

### 1.4 Logging
- Use the pfSense logging system (logger command) for all significant events
- Include a specific tag for easy filtering (e.g., `pfsense_auth_alert`)
- Log both successful operations and failures

Example:
```sh
logger -t pfsense_auth_alert "Gotify notification sent successfully"
```

### 1.5 Comments
- Add comments for complex logic sections
- Document expected input/output for functions
- Include explanations for non-obvious commands or regex patterns

## 2. Notification Standards

### 2.1 Alert Categories
Use consistent event type names for categorizing alerts:
- "Authentication Success"
- "Authentication Failure"
- "SSH Connection"
- "SSHGuard Block"

### 2.2 Alert Format
Maintain consistent alert formatting across all notification methods:
- Clear title that includes source system
- Event type first
- User information when available
- IP address
- Timestamp

Example:
```
Event: Authentication Success
User: admin
IP Address: 192.168.1.100
Time: Wed May 8 15:30:45 EDT 2025
```

### 2.3 Notification Priority
- Use consistent priority levels across notification systems
- Assign higher priority (5) for security-related alerts

## 3. Security Standards

### 3.1 Sensitive Information
- Never hardcode sensitive information (passwords, tokens) directly in scripts
- Consider using environment variables or configuration files with restricted permissions
- Mask sensitive information in logs

### 3.2 Script Permissions
- Set appropriate permissions for all scripts (`chmod +x`)
- Ensure temporary files are created with restricted permissions
- Clean up temporary files after use

Example:
```sh
# Clean up
rm -f "$PHP_SCRIPT"
```

### 3.3 Input Validation
- Validate all user inputs and log entries before processing
- Use pattern matching to ensure data fits expected formats
- Implement proper quoting and escaping for variables used in commands

## 4. Performance Standards

### 4.1 Resource Usage
- Minimize unnecessary disk I/O operations
- Use efficient text processing commands (grep, sed, awk)
- Set appropriate timeouts for network operations

Example:
```sh
curl -X POST \
  [...options...] \
  --connect-timeout 10 \
  "$FULL_URL"
```

### 4.2 Execution Frequency
- Run monitoring scripts at appropriate intervals (e.g., every 5 minutes)
- Implement efficient timestamp tracking to avoid reprocessing old entries
- Use incremental processing rather than scanning entire log files

## 5. Documentation Standards

### 5.1 README Structure
README.md files should include:
- Project title and concise description
- Overview of functionality
- List of features
- Installation instructions
- Configuration details
- Usage examples
- Troubleshooting tips
- License information

### 5.2 Implementation Documentation
- Document the monitoring strategy for different authentication events
- Explain how SSHGuard integration works
- Detail the notification flow from event detection to alert delivery

### 5.3 Configuration Documentation
- Document all configurable parameters
- Provide examples of common customizations
- Include information about dependent services (Gotify, SMTP)

## 6. Code Organization

### 6.1 Script Structure
Organize scripts in a logical flow:
1. Configuration variables
2. Helper functions
3. Main processing logic
4. Cleanup operations

### 6.2 Function Design
- Create functions for repeatable operations
- Keep functions focused on single responsibilities
- Use meaningful function names that describe their purpose

### 6.3 Directory Structure
Maintain a consistent directory structure:
```
/root/Scripts/
  ├── check_pfsense_login.sh    # Main monitoring script
  └── gotify_auth_alert.sh      # Alert delivery script
```

## 7. Testing and Validation

### 7.1 Manual Testing
- Test with valid authentication events
- Test with failed authentication attempts
- Test with SSH connections
- Test with SSHGuard blocking events

### 7.2 Error Condition Testing
- Test with unavailable Gotify server
- Test with misconfigured email settings
- Test with invalid log entries

### 7.3 Validation Methods
- Check system logs for expected entries
- Verify notifications are received through all configured channels
- Confirm timestamp tracking prevents duplicate notifications

## 8. Version Control

### 8.1 Commit Messages
- Use clear, descriptive commit messages
- Reference issue numbers when applicable
- Separate subject from body with a blank line

Example:
```
Add SSH connection monitoring

- Added detection for SSH connection attempts
- Implemented SSHGuard block notifications
- Updated documentation to reflect new features
```

### 8.2 Branch Management
- Use feature branches for new functionality
- Create bugfix branches for critical issues
- Merge only tested and reviewed code to main branch

## 9. Maintenance

### 9.1 Log Rotation
- Ensure log files are properly rotated
- Handle situations where log files may be truncated
- Implement robust timestamp tracking between script executions

### 9.2 Updating
- Document the update process for scripts
- Maintain backward compatibility when possible
- Include version information in script headers

## 10. SSH and SSHGuard Standards

### 10.1 SSH Event Detection
- Monitor both successful and failed SSH connections
- Extract relevant information (username, IP, timestamp)
- Categorize events consistently

### 10.2 SSHGuard Integration
- Monitor SSHGuard blocking actions
- Include block reason in notifications when available
- Provide guidance for reviewing blocked IPs

By following these standards, the pfLoginTracker project will maintain consistency, reliability, and security across all its components.
