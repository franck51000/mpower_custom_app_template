# Using Advanced Features

**Summary:** Advanced features enhance application capabilities beyond basic functionality. Multiple process support enables complex architectures, system logging provides centralized monitoring, web UI notifications offer immediate feedback, and version management allows detailed tracking. These features are optional but recommended for production applications.

## Multiple Process Support (R.7.1.0+)

Many applications require multiple processes working together. mPower R.7.1.0+ provides enhanced support for tracking and monitoring multi-process applications. See more on [handling multiple processes](#multiple-processes).

**Configuring Multiple Process Tracking**

Update status.json to use the array format:

**Status Logic**

For multi-process applications:

-   **RUNNING**: Shown only if ALL processes are running
-   **FAILED**: Shown if ANY process is not running

This strict checking ensures you're alerted when any component fails.

**Python Example - Process Manager**

`        `\
`      ``  `

**Viewing Process Details**

The web UI \"View Application Details\" shows comprehensive process information:

-   Process name

-   PID

-   Running status (✓ or ✗)

-   Command line (if available)

**Best Practices**

-   **Descriptive Names**: Use clear process names (not just \"worker1\")

-   **Ordered Shutdown**: Stop dependent processes first (workers before main)

-   **Graceful Starts**: Add delays between process starts if needed

-   **Health Monitoring**: Regularly check process status and restart if needed

-   **Update Status**: Keep status.json current with actual PIDs

**Note:** Using descriptive, clear process names is important for tracking interpreted scripts like Python and their processes and subprocesses with [multiple PIDs](#multiple-processes). Be aware, however, that the \--exec option can fail with interpreted scripts because start-stop-daemon checks the process name against the scripts interpreter rather than the script itself. This makes it difficult to start and stop specific script-based services reliably.

## System Logging

Integrating with the system logging facility allows your application to participate in centralized logging, making troubleshooting and monitoring easier.

**Using logger Command**

The `logger` command writes messages to syslog:

**Logger Options**

  -----------------------------------------------------------------------
  **Option**              **Description**
  ----------------------- -----------------------------------------------
  -t TAG                  Set log tag (application name)

  -p PRIORITY             Set priority (facility.level)

  -s                      See logger man page
  -----------------------------------------------------------------------

**Priority Levels**

Common combinations:

-   `user.info` - Informational messages
-   `user.notice` - Normal but significant
-   `user.warning` - Warning conditions
-   `user.error` - Error conditions

**In Bash Scripts**

**In Python:**

**In C**

**Viewing Logs**

**Best Practices**

-   **Consistent Tagging**: Always use the same tag (application name)
-   **Appropriate Levels**: Use correct priority levels for message severity
-   **Structured Messages**: Include context (operation, user, resource)
-   **Avoid Spam**: Don't log every trivial event
-   **Log Rotation**: System handles rotation automatically

## Web UI Notifications

Custom applications can display notifications in the mPower web UI, providing immediate feedback to administrators about important events.

**Using notify_system**

The `notify_system` command displays notifications in the web UI:

**Notification Types**

-   **INFO**: Informational messages (blue)
-   **WARNING**: Warning conditions (yellow)
-   **ERROR**: Error conditions (red)

**Helper Functions**

Create wrapper functions for easier use:

**When to Use Notifications**

Good use cases:

-   Application start/stop events
-   Configuration changes applied
-   Critical errors that require attention
-   Major state transitions

Avoid for:

-   Routine operations
-   Frequent events (every second)
-   Debugging messages
-   Verbose status updates

**Viewing Notifications**

Notifications appear in the web UI:

-   Top of the page as banner notifications
-   In the notifications area
-   Automatically dismissed after timeout (for INFO)
-   Require dismissal (for WARNING/ERROR)

## Version Management (R.7.1.0+)

mPower R.7.1.0+ introduces enhanced version tracking with support for supplementary version identifiers.

**Purpose**

The extra version allows tracking:

-   Build numbers
-   Branch identifiers
-   Release candidates
-   Development versions
-   Custom versioning schemes

**Display**

Extra versions appear in the web UI alongside the main version:

**Use Cases**

**Build Tracking**

**Branch Identification**

**Release Candidates**

**Automated Build Systems**

Integrate with CI/CD:

Result:
