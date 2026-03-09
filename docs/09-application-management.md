# Application Management

**Summary:** Application management can be performed locally through three interfaces (command-line in app-manager for scripts and automation, Web UI for visual administration, and SMS commands for emergency remote access) and remotely through MultiTech Device Manager. Each option has strengths for different scenarios, and understanding all three provides maximum flexibility.

**Note:** As you work on your custom apps, the end goal is to install the app from MultiTech Device Manager. You can also install your app locally if you want to provision it yourself, then via Device Manager if you want to use any MultiTech services, including help with onboarding devices.

## Command-Line in App-Manager

The app-manager command-line utility is the primary interface for managing custom applications on the mPower device. Understanding its commands and options enables effective application management.

**Basic Command Structure**

**Common Commands**

**Install Application**

Example:

**Uninstall Application**

Example:

**Start Application**

**Stop Application**

**Restart Application**

**Check Application Status**

This displays all installed applications with their current status.

**Advanced Commands (R.7.1.0+)**

**List Installed Applications**

**Install Dependencies Only**

This runs the Install script without reinstalling the application, which is useful after firmware upgrades or for troubleshooting.

**Install Configuration**

Installing configurations is supported in MultiTech Device Manager, which is more efficient when you have multiple files versus installing configurations manually at the command line.

Example:

**Complete Options Reference (R.7.1.0+)**

**Command Examples**

Useful command examples:

**Install and Auto-Start**

**Install with MD5 Verification**

**Install Without Backup**

The install backs up existing app versions unless --noAppBackup. mPower devices have configuration options to enable/disable backups in the UI, so you can create backups through the device API, etc.

**Note:** Use cautiously, as this skips backing up the existing version before installing.

**Install from MultiTech Device Manager**

If \--appfile option is not provided, the app manager will treat the command as installation from MultiTech Device Manager.

In this case, the example would be the following:

App manager will try to download and validate the app, the id 12345678-90ab-cdef-1234-567890abcdef, and the version 1.2.3. It will check the md5 summ of the downloaded app and then install it.

**Understanding Command Behavior**

**Install Process**

-   Validates the app package
-   Stops existing version if present
-   Extracts new version to installation directory
-   Executes `Install ``install`
-   Saves application metadata
-   Executes `Install ``postinstall`
-   Starts application (if \--activate or by default)

**Remove Process**

-   Stops the application
-   Executes `Install remove`
-   Deletes entire application directory
-   Removes metadata

**Start/Stop Process**

-   Executes `Start ``start` or `Start stop`
-   Updates internal state
-   Notifies if requested

**Exit Codes**

App-manager returns standard exit codes:

-   **0**: Success
-   **Non-zero**: Error occurred

Check exit codes in scripts:

**Common Usage Patterns**

**Check if Application is Running**

**Restart All Applications**

## Web UI Management

The mPower web interface provides a graphical way to manage custom applications. This is often more convenient for administrators who prefer visual interfaces.

**Accessing the Apps Page**

1.  Log into your mPower device's web interface
2.  Navigate to **Apps** in the main menu
3.  View list of installed applications

**Apps Page Information**

For each installed application, the page displays:

-   **Name**: Application name from manifest.json
-   **Version**: Current version (hover to see version notes)
-   **Status**: Current state (RUNNING, STOPPED, FAILED, etc.)
-   **Info**: AppInfo message from status.json
-   **Description**: Application description (hover over name)
-   **Options**: Actions menu

**Available Actions**

**Start**

-   Click **Options** → **Start**
-   Starts a stopped application
-   Updates status immediately

**Stop**

-   Click **Options** → **Stop**
-   Stops a running application
-   Graceful shutdown via Start script

**Restart**

-   Click **Options** → **Restart**
-   Stops then starts the application
-   Useful for applying changes

**Uninstall**

-   Click **Options** → **Uninstall**
-   Prompts for confirmation
-   Removes application completely

**View Application Details (R.7.1.0+)**

-   Click **Options** → **View Application Details**
-   Opens popup window with comprehensive information:
    -   Application Name
    -   Application ID
    -   Application Version
    -   Extra Version (if available)
    -   Installation Location (Persistent/Flash)
    -   Application Status
    -   Application Description
    -   Version Notes
    -   Application Info
    -   Process Information:
        -   PID
        -   Running status
        -   Process name
        -   Command line

**Status Indicators**

The status field shows color-coded states:

-   **Green/RUNNING**: All processes running normally

-   **Yellow/STARTED**: Application started but status unknown (no status.json)

-   **Red/FAILED**: One or more processes not running

-   **Red/STOPPED**: Application stopped

-   **Red/INSTALL FAILED**: Installation encountered errors

-   **Red/START FAILED**: Application failed to start

**Multi-Line Status Display (R.7.1.0+)**

The AppInfo field supports line breaks (\\n), allowing multi-line status messages:

**Best Practices for Web UI**

-   **Use Descriptive AppInfo**: Provide meaningful status messages that help users understand application state

-   **Hover for Details**: Remember to hover over application name and version for additional information

-   **Check Details**: Use \"View Application Details\" for troubleshooting

-   **Verify After Actions**: Always check status after start/stop/restart operations

-   **Review Logs**: For issues, check system logs via command line

## SMS Commands (R.7.2.0+)

mPower R.7.2.0 introduces SMS-based application management, enabling remote control when network connectivity is limited or unavailable.

**Purpose**

-   Remote troubleshooting without network access
-   Emergency application management
-   Field maintenance scenarios
-   Automated monitoring systems

**SMS Command Format**

**Parameters**

-   **action**: One of `start`, `stop`, or `restart`
-   **app_identifier**: Either Application ID or Application Name (case-sensitive)

**Command Examples**

**Using Application ID**

**Using Application Name**

**For Application Names with Spaces**

**Configuration**

SMS application management must be explicitly enabled on the device before SMS commands will be accepted. This is a security feature to prevent unauthorized remote application control.

**Enabling Via Web UI**

1.  Log into the mPower device Web UI
2.  Navigate to **Setup** → **SMS**
3.  Enable SMS functionality (master switch for all SMS features)
4.  Enable the `#app` command (specific switch for application management)
5.  Click **Save and Apply** to save and apply your configuration

**SMS Responses**

**Success Responses**

-   `Application started`
-   `Application stopped`
-   `Application restarted`

**Error Responses**

All error responses are prefixed with `ERROR:`:

-   `ERROR: Application is not installed`
-   `ERROR: Incorrect arguments number`
-   `ERROR: Unsupported command`
-   `ERROR: Failed to process command`
-   `ERROR: Applications functionality is disabled`

**Security Considerations**

-   **Authentication**: SMS commands use the mPower device's SMS security settings
-   **Authorization**: Ensure only authorized numbers can send SMS commands
-   **Audit Trail**: All SMS commands are logged in system logs
-   **Enable Selectively**: Only enable #app command when needed

**Monitoring SMS Commands**

Check system logs for SMS command activity:

**Limitations**

-   **Network Dependent**: mPower device must have cellular connectivity
-   **Carrier Delays**: SMS delivery may be delayed
-   **No Status Response**: Commands don't return application status, only success/failure
-   **Limited Actions**: Only start, stop, and restart are supported (no install/uninstall)

**Best Practices**

-   **Test First**: Verify SMS functionality before relying on it
-   **Document Commands**: Keep a reference of exact application names/IDs
-   **Use Quotes**: Use quotes for application names with spaces
-   **Monitor Results**: Check mPower device logs or status after sending commands
-   **Have Backup**: Don't rely solely on SMS for critical operations
