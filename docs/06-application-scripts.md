# Working with Application Scripts

**Summary:** The Install and Start scripts are the core automation for your application. The Install script manages dependencies and setup, while the Start script controls the application lifecycle. Consider using start-stop-daemon and multiple processes when developing your application. These scripts also leverage environmental variables provided by app-manager to locate resources and maintain portability across different installation locations.

## Install Script

The Install script is responsible for setting up and tearing down your application's dependencies and environment. It is executed at specific points during the application lifecycle with different command-line arguments.

**Purpose**

-   Install application dependencies (IPK packages, Python packages, etc.)
-   Perform setup tasks during installation
-   Clean up dependencies during uninstallation
-   Execute post-installation tasks
-   Reinstall dependencies after firmware upgrades

**Script Requirements**

-   Must be executable (`chmod`` +x Install`)
-   Must be located at the top level of the application package
-   Must accept these command-line arguments:
    -   `install`: Install dependencies
    -   `postinstall`: Perform post-installation tasks
    -   `remove`: Remove dependencies
-   Must be idempotent: Running install/postinstall multiple times should be safe
-   Always runs as root user

**Template Structure**

The custom app template provides a complete Install script. Key sections include:

```bash
#!/bin/bash
# Environment setup
APP_DIR=${APP_DIR:-.}
APP_ID=${APP_ID:-666d78aa-8270-446f-88cb-04c799558476}

log() { logger -t "$APP_ID" -p user.notice "$@"; }

PROVISIONING_DIR="${APP_DIR}/provisioning"
P_MANIFEST="${PROVISIONING_DIR}/p_manifest.json"

do_install() {
    # Parse p_manifest.json and install IPK packages
}

do_postinstall() {
    # Additional post-install steps
}

do_remove() {
    # Cleanup on uninstall
}
```

**When the Install is Called**

**During Application Installation**

```
1. app-manager extracts the application package
2. app-manager executes: Install install
3. app-manager saves application metadata
4. app-manager executes: Install postinstall
5. app-manager starts application
```

**During Application Uninstallation**

```
1. app-manager stops application
2. app-manager executes: Install remove
3. app-manager deletes application directory
4. Deletes the application metadata from app-manager.json
```

**After Firmware Upgrade**

```
For each installed application:
1. app-manager executes: Install install
2. app-manager executes: Install postinstall
3. app-manager starts application
```

**Customizing the Install Script**

**Example: Installing Python Packages**

```bash
do_install() {
    log "Installing Python dependencies"
    pip3 install -r "${APP_DIR}/requirements.txt" || {
        log "ERROR: Failed to install Python packages"
        return 1
    }
    install_ipks
    return 0
}
```

**Example: Creating Directories**

```bash
do_postinstall() {
    log "Creating data directories"
    mkdir -p /var/persistent/${APP_NAME}/data || {
        log "ERROR: Failed to create data directory"
        return 1
    }
    chmod 755 /var/persistent/${APP_NAME}/data
    return 0
}
```

**Example: Custom Cleanup**

```bash
do_remove() {
    log "Removing application"
    remove_ipks
    rm -rf /var/persistent/${APP_NAME}/data
    rm -f /etc/${APP_NAME}.conf
    return 0
}
```

**Important Considerations**

-   **Idempotency:** The `install` and `postinstall` functions must handle being run multiple times. Check if packages are already installed before attempting installation.

-   **Error Handling:** Always check return codes and log errors clearly. Return non-zero on failure.

-   **Logging:** Use the `logger` command to write to system logs for debugging:
    ```bash
    logger -t "$APP_NAME" "Installation completed successfully"
    ```

-   **Dependency Management:** If using p_manifest.json, the default script handles IPK installation. You can extend this with additional dependencies.

-   **File Permissions:** Ensure created files and directories have appropriate permissions.

## Start Script

The Start script manages the lifecycle of your application processes. It starts, stops, and restarts your application in response to commands from app-manager.

**Purpose**

-   Start application processes
-   Stop application processes gracefully
-   Restart application
-   Reload configuration without full restart
-   Handle boot and shutdown scenarios

**Script Requirements**

-   Must be executable (`chmod`` +x Start`)
-   Must be located at the top level of the application package
-   Must accept these command-line arguments:
    -   `start`: Start the application
    -   `stop`: Stop the application
    -   `restart`: Stop then start the application
    -   `reload`: Reload configuration (optional)
-   Must handle `--``initd` flag for boot/shutdown
-   Always runs as root user

**Template Structure**

```bash
#!/bin/bash
APP_ID="666d78aa-8270-446f-88cb-04c799558476"
DAEMON="${APP_DIR}/myapp.py"
DAEMON_ARGS=""
PIDFILE="${APP_DIR}/myapp.pid"

do_start() { ... }
do_stop()  { ... }
do_reload(){ ... }

case "$1" in
    start)   do_start ;;
    stop)    do_stop ;;
    restart) do_stop; sleep 2; do_start ;;
    reload)  do_reload ;;
esac
```

**When Start is Called**

**During Custom Application Startup**

```bash
app-manager --command start
```

This command is the same whether it is done manually or automatically during initialization of the mPower device or through the Web UI.

**When Stopping a Custom Application**

```bash
app-manager --command stop
```

**During Boot**

```
For each installed application:
app-manager executes: Start start --initd
```

**During Shutdown**

```
For each installed application:
app-manager executes: Start stop --initd
```

**Configuration Update**

```
app-manager executes: Start reload
```

**Restarting a Custom Application**

```bash
app-manager --command restart
```

## start-stop-daemon Utility

The template uses `start-stop-daemon`, a utility designed for managing daemon processes. This is an example in the template that may or may not meet your needs for managing your application. Depending on your application and its management requirements, you may decide to use monit or other means in Linux to manage your application.

**Key start-stop-daemon Commands**

This is an example of commands to use with the start-stop-daemon utility. Refer to [Linux documentation online](https://man7.org/linux/man-pages/man8/start-stop-daemon.8.html) for more options you can use with these commands.

  -----------------------------------------------------------------------
  **Option**              **Description**
  ----------------------- -----------------------------------------------
  \--start                Start a process

  \--stop                 Stop a process

  \--background           Run the process in the background

  \--make-pidfile         Create PID file

  \--pidfile FILE         Specify PID file location

  \--exec PROGRAM         Program to execute

  \--retry TIMEOUT        How long to wait for the process to stop
  -----------------------------------------------------------------------

**start-stop-daemon --help output**

```
Usage: start-stop-daemon [...]
  -S, --start        Start a program
  -K, --stop         Stop a program
  -T, --status       Get the program status
  -H, --help         Print help information
  -V, --version      Print version
```

**Customizing for Different Languages**

**Python Application**

```bash
NAME="MyPythonApp"
DAEMON="/usr/bin/python3"
DAEMON_ARGS="${APP_DIR}/myapp.py --config ${CONFIG_DIR}/app.conf"
PIDFILE="${APP_DIR}/myapp.pid"
```

**Bash Script**

```bash
NAME="MyBashApp"
DAEMON="/bin/bash"
DAEMON_ARGS="${APP_DIR}/myapp.sh"
PIDFILE="${APP_DIR}/myapp.pid"
```

**Compiled Binary**

```bash
NAME="MyCompiledApp"
DAEMON="${APP_DIR}/myapp"
DAEMON_ARGS="--port 8080 --log-level debug"
PIDFILE="${APP_DIR}/myapp.pid"
```

## Multiple Processes

For applications that start multiple processes, you have several implementation options. The approach you choose depends on your application's architecture and requirements.

**Limitations of start-stop-daemon**

The start-stop-daemon utility is designed for managing daemon processes (services that detach from the controlling terminal and run in the background). While it works well for many use cases, it has limitations that you should understand:

-   **Failure states are poorly defined**: It is not always possible to get an accurate exit status when processes fail to start

-   **No automatic restart**: Does not provide built-in mechanisms for automatically restarting failed processes

-   **PID file race conditions**: If a process dies and its PID is quickly reused by another process, start-stop-daemon might send signals to the wrong process

-   **PID file security**: The application must handle PID files securely, including proper cleanup and locking

-   **Daemonization requirements**: Designed for processes that daemonize themselves (fork into background)

-   **Script interpreter issues**: The \--exec option can fail with interpreted scripts (Bash, Python) because start-stop-daemon checks the process name against the script's interpreter rather than the script itself, making it difficult to start and stop specific script-based services reliably

**When to Use start-stop-daemon**

-   Traditional daemon processes written in C/C++

-   Processes that properly daemonize themselves

-   Simple single-process applications

-   Applications where systemd is not available

**Alternative Approach - Direct Process Management**

For interpreted scripts and more complex scenarios, consider managing processes directly. Some advantages of direct process management are:

-   **Full control**: Complete control over process lifecycle

-   **Better error handling**: Can check if processes actually started

-   **Graceful shutdown**: Implements proper SIGTERM → wait → SIGKILL sequence

-   **Works with scripts**: No interpreter name conflicts

-   **Status verification**: Can verify all processes before reporting success

-   **Logging**: Each process can have its own log file

For an example of managing processes directly, see [Appendix C](#appendix-c-direct-process-management-example).

**When to Use Each Approach**

  --------------------------------------------------------------------------------------
  **Scenario**                            **Recommended Approach**
  --------------------------------------- ----------------------------------------------
  Single compiled binary daemon           start-stop-daemon

  Python/Bash script applications         Direct process management

  Multiple processes                      Direct process management

  Need automatic restart on failure       External process supervisor (monit, systemd)

  Complex process dependencies            Direct process management with health checks

  Simple daemon that backgrounds itself   start-stop-daemon
  --------------------------------------------------------------------------------------

**Using start-stop-daemon**

If you choose to use start-stop-daemon despite its limitations, here's the approach:

**Note**: This approach works best with compiled binaries. For Python or Bash scripts, use the direct process management approach shown in [Appendix C](#appendix-c-direct-process-management-example).

**Implementing Reload**

The `reload` command is used when configuration files are updated via MultiTech Device Manager:

**The \--initd Flag**

The \--initd flag indicates the script is being called by the /etc/init.d/customapp initialization script during device boot or shutdown, rather than being executed manually by a user or through app-manager. This flag helps your application distinguish between automated system startup and manual/remote control. Also consider the following:

-   The flag is set by /etc/init.d/customapp during boot/shutdown sequences

-   You can technically use it in other contexts, but this is not recommended

-   Using \--initd outside of the customapp init script may cause unexpected behavior

-   When you see this flag, your application is starting as part of the system boot process

You may want special behavior during system boot:

**Best Practices**

-   **Always update status.json** after starting processes to enable proper monitoring
-   **Use graceful shutdown** with SIGTERM before SIGKILL
-   **Log all actions** using the logger for debugging
-   **Check if already running** before starting
-   **Clean up PID files** after stopping
-   **Handle errors gracefully** and return appropriate exit codes
-   **Test restart behavior** to ensure clean transitions

**Common Mistakes**

-   Forgetting to make the script executable
-   Not updating status.json with the correct PID
-   Not handling the case where the process is already running
-   Using hardcoded paths instead of environment variables
-   Not providing appropriate timeout values for process shutdown

## Environmental Variables

When app-manager executes the Install and Start scripts, it sets several environment variables that provide context and paths for your application. Understanding and using these variables makes your scripts more portable and maintainable.

**Available Environment Variables (R.7.1.0+)**

  -------------------------------------------------------------------------------------------
  **Variable**   **Description**                                   **Example Value**
  -------------- ------------------------------------------------- --------------------------
  APP_DIR        Full path to application installation directory   /var/config/MyApp

  CONFIG_DIR     Full path to application config directory         /var/config/MyApp/config

  APP_ID         Application ID from MultiTech Device Manager      611d1dde31eddd056018b8bf
  -------------------------------------------------------------------------------------------

**Using Environment Variables**

View [Appendix D](#appendix-d-environment-variables-reference) for an environmental variables reference.

**In Start Script**

**Passing Variables to Your Application**

```bash
# In Start script
do_start() {
    # Export variables for the application
    export MY_APP_DIR="$APP_DIR"
    export MY_CONFIG="$CONFIG_DIR/app.conf"
    export MY_APP_ID="$APP_ID"

    start-stop-daemon --start \
        --exec "$DAEMON" \
        -- $DAEMON_ARGS
}
```

You can pass environment variables to your application:

**Accessing in Python**

**Default Values**

Always provide default values in case environment variables are not set:

**Best Practices**

-   **Always use APP_DIR** instead of hardcoding paths
-   **Use CONFIG_DIR** for configuration files that may be updated via MultiTech Device Manager
-   **Provide defaults** for all environment variables
-   **Export variables** if your application needs access to them
-   **Document** which environment variables your application expects
-   **Test** scripts with and without environment variables set
