# Identifying Core Configuration Files

**Summary:** The three core configuration files work together to define your application: *manifest.json* provides metadata and installation preferences, *status.json* enables process monitoring and status reporting, and *p_manifest.json* declares system dependencies. Understanding these files is essential for creating properly configured custom applications.

## manifest.json

The manifest.json file is the primary configuration file for your custom application. It provides the app-manager with essential information about your application and controls installation behavior.

**Purpose**

-   Identifies the application with a unique name
-   Specifies version information
-   Provides descriptions for users and administrators
-   Controls installation location
-   Must be present at the top level of the package

**File Format**

-   Valid JSON format
-   All string values
-   Optional boolean flags for installation control

**Required Fields**

| **Field** | **Type** | **Description** |
| --- | --- | --- |
| AppName | String | Name of the application. Used for the installation directory name and display in UI and MultiTech Device Manager. Must be unique across installed applications. |
| AppVersion | String | Version identifier for the application. MultiTech Device Manager uses this to distinguish between versions. Follow semantic versioning practices. |
| AppDescription | String | Human-readable description of what the application does. Displayed in UI and MultiTech Device Manager. |
| AppVersionNotes | String | Release notes or changes for this specific version. Helps track what changed between versions. |


**Optional Fields**

| **Field** | **Type** | **Description** |
| --- | --- | --- |
| PersistentStorage | Boolean | When true, installs to /var/persistent. |


**Basic Example**

```json
{
  "AppName": "LoraSensor",
  "AppVersion": "1.0.0",
  "AppDescription": "Processes LoRa sensor data and forwards to cloud",
  "AppVersionNotes": "Initial release with basic functionality"
}
```

**Example with Installation Control**

```json
{
  "AppName": "CriticalApp",
  "AppVersion": "2.1.0",
  "AppDescription": "Critical system monitor",
  "AppVersionNotes": "Added email alerts",
  "PersistentStorage": true
}
```

**Best Practices**

-   Use semantic versioning (major.minor.patch) for AppVersion
-   Keep AppName short, descriptive, and unique
-   Provide meaningful AppVersionNotes for each release
-   Only set PersistentStorage true for applications that must survive firmware upgrades
-   Use PersistentStorage true for applications requiring significant storage

**Common Mistakes**

-   Invalid JSON syntax (missing commas, quotes, braces)
-   Using the same AppName as an existing application
-   Forgetting to update AppVersion when releasing updates

## status.json

The status.json file enables app-manager to monitor your application's processes and provide detailed status information to users through the web UI and MultiTech Device Manager.

**Purpose**

-   Track one or more process IDs (PIDs)
-   Provide custom status messages to users
-   Enable accurate "RUNNING" vs "FAILED" status determination
-   Manage multi-process applications and report status of all apps (mPower R.7.1.0+)

**File Format**

-   Valid JSON format
-   Updated by your application at runtime
-   Read by app-manager periodically

**Basic Structure (Single Process)**

```json
{
  "pid": 2374,
  "AppInfo": "Processing sensor data"
}
```

### Advanced Structure (Multiple Processes Tracking, R.7.1.0+)

When your application architecture uses multiple processes, tracking all PIDs in status.json is a way to tell app-manager about all the processes your application uses (for example, a main coordinator process and separate worker processes).

Only tracking one PID for the main coordinator process in status.json prevents app-manager from detecting when critical worker processes crash, delaying problem detection until you notice your application is not working correctly. The process to track multiple PIDs works as follows:

-   Your application (or Start script) must write the PID values to status.json. When you start each process, you capture its Process ID and write it to this file. The operating system (OS) assigns PID values when processes start, so you only need to record them.

-   If any process stops, the status immediately changes to "FAILED" and alerts you through the web UI and MultiTech Device Manager so you can take corrective action.

You should avoid using this feature when your application is a single process, when multiple processes are optional/non-critical, or when you have processes that intentionally start and stop. Use this feature when:

-   Your application involves multiple processes

-   Each process performs a critical function

-   Failure of any single process means the application isn't working correctly

-   You want immediate notification when any component fails

**Field Descriptions**

| **Field** | **Type** | **Description** |
| --- | --- | --- |
| pid | Integer or Array | Single PID for simple apps, or an array of process objects for multi-process apps. App-manager checks if these processes are running. |
| AppInfo | String | Custom status message (up to 160 characters). Displayed in the web UI and MultiTech Device Manager. Supports \\n for line breaks (R.7.1.0+). |


**For Multiple Process Objects**

| **Field** | **Type** | **Description** |
| --- | --- | --- |
| name | String | Human-readable process name (optional but recommended) |
| pid | Integer | Process ID to monitor |


**Advanced Structure Example**

```json
{
  "pid": [
    {
      "name": "main_process",
      "pid": 1234
    },
    {
      "name": "worker_process",
      "pid": 5678
    }
  ],
  "AppInfo": "Main process connected\nWorker processing queue\n5 items pending"
}
```

**Status Determination Logic**

**Single PID**

-   If process is running: Status shows "RUNNING"
-   If the process is not running: Status shows "FAILED"
-   If no status.json exists, the system cannot determine if the process is still running or has crashed: Status shows only "STARTED"/"STOPPED" (basic monitoring only)

**Multiple PIDs (R.7.1.0+)**

-   If ALL processes are running: Status shows "RUNNING"
-   If ANY process is not running: Status shows "FAILED"

### Using AppInfo Effectively

The AppInfo field allows your application to communicate its current state or errors to users. The status can contain any string up to 160 characters, but the system will truncate it to fit within this constraint if the string exceeds this limit. The AppInfo field also supports \\n for line breaks. The status appears in the web UI's for the mPower device and MultiTech Device Manager. Effective uses include:

-   Connection status: "Connected to server"
-   Processing statistics: "Processed 150 messages"
-   Error conditions: "ERROR: Configuration file missing"
-   Queue status: "5 items in queue"
-   Multi-line status (R.7.1.0+): "Line 1\\nLine 2\\nLine 3"

**Updating status.json from Your Application**

Your application should update status.json whenever:

-   It starts up (write initial PID and status)
-   Status changes meaningfully
-   Before exiting (optional, for clean shutdown messages)

**Python Example**

```python
import json
import os

def update_status(pid, message):
    status = {
        "pid": pid,
        "AppInfo": message
    }
    with open('status.json', 'w') as f:
        json.dump(status, f, indent=2)

# At startup
update_status(os.getpid(), "Application starting")
# During operation
update_status(os.getpid(), "Processing data")
```

**Bash Example**

```bash
#!/bin/bash
APP_PID=$$
STATUS_FILE="status.json"

update_status() {
    local message="$1"
    cat > "$STATUS_FILE" << EOF
{
  "pid": $APP_PID,
  "AppInfo": "$message"
}
EOF
}

# At startup
update_status "Application starting"
# During operation
update_status "Processing complete"
```

**Multi-Process Example (R.7.1.0+)**

```python
import json

def update_multi_status(processes, message):
    """
    processes: list of (name, pid) tuples
    message: status message
    """
    status = {
        "pid": [
            {"name": name, "pid": pid}
            for name, pid in processes
        ],
        "AppInfo": message
    }
    with open('status.json', 'w') as f:
        json.dump(status, f, indent=2)

# Track multiple processes
processes = [
    ("main", 1234),
    ("worker", 5678)
]
update_multi_status(processes, "All processes running\nQueue: 0 items")
```

**Best Practices**

-   Always write status.json when your application starts
-   Update AppInfo when meaningful state changes occur
-   Keep AppInfo messages concise and informative
-   Use \\n for multi-line messages to improve readability
-   For multi-process apps, give each process a descriptive name
-   Handle file write errors gracefully
-   Do not update status.json excessively

## p_manifest.json

The p_manifest.json file is a flexible manifest that lists dependencies and resources your application requires. While the template Install script is a working example of using this file to manage IPK (OpenEmbedded) packages, you can customize the Install script to handle other package formats or resources.

**Purpose**

-   Declare application dependencies and resources
-   Automate dependency installation during application setup
-   Ensure a consistent environment across deployments
-   Support dependency removal during uninstallation
-   Provide a structured way to track what your application needs

**Flexibility**

The p_manifest.json format and Install script are templates you can adapt to your needs. While mPower devices use IPK packages by default, you can modify the Install script to handle:

-   RPM packages (if rpm utilities are installed)

-   Debian packages (if dpkg utilities are installed)

-   Tar archives or zip files

-   Downloaded resources from the internet

-   Custom installation procedures

**Note:** mPower devices do not support .rpm or .deb by default, but with an update via a package, the system can install the appropriate utilities. The "type" field identifies the package type.

The core concept is that p_manifest.json serves as a structured inventory of required components, while the Install script defines the process for installing them, like automatically deploying packages during application setup.

**Location**

-   Must be placed in the `provisioning/` directory
-   Accompanies IPK files in the same directory

**File Format**

**Field Descriptions**

| **Field** | **Type** | **Description** |
| --- | --- | --- |
| pkgs | Array | An array of package objects to install |
| FileName | String | Name of the file (IPK, etc.) in the provisioning directory |
| type | String | Package type. Currently, only "ipk" is supported, but you can modify the Install script to handle other package types |
| PkgName | String | Actual package name (from the IPK control file, etc.) that is used to check if the package is already installed |


**Complete Example**

```json
{
  "pkgs": [
    {
      "FileName": "python3-requests_2.25.1.ipk",
      "type": "ipk",
      "PkgName": "python3-requests"
    },
    {
      "FileName": "libmosquitto1_1.6.12.ipk",
      "type": "ipk",
      "PkgName": "libmosquitto1"
    }
  ]
}
```

### How Dependencies Are Installed via the Default Install Script Template

The default Install script template processes p_manifest.json as follows:

-   During installation (`Install ``install`)

    -   Reads p_manifest.json
    -   Installs each IPK using `opkg`` install --force-depends`
    -   Logs success or failure for each package

-   During uninstallation (`Install remove`)

    -   Reads p_manifest.json
    -   Removes each package using `opkg`` remove --force-depends`
    -   Continues even if removal fails

**Directory Structure Example**

```
MyApplication/
├── manifest.json
├── Install
├── Start
├── provisioning/
│   ├── p_manifest.json
│   ├── python3-requests_2.25.1.ipk
│   └── libmosquitto1_1.6.12.ipk
└── myapp.py
```

**Important: \--force-depends Behavior**

The default Install script uses `--force-``depends` when installing and removing packages. This flag tells opkg to:

-   Install packages even if dependencies are missing
-   Remove packages even if other packages depend on them

**WARNING:** If your application updates base system packages or libraries, you must modify the Install script to remove the `--force-``depends` flag. Removing system libraries with `--force-``depends` can break other applications or system services.

### When to Modify the Install Script

If your p_manifest.json includes:

-   System libraries (libc, libstdc++, etc.)
-   Core utilities
-   Packages that other applications depend on

Then modify the Install script variables:

```bash
# Change from:
OPKG_CMD_PREFIX="opkg install --force-depends"
OPKG_CMD_PREFIX_R="opkg remove --force-depends"
# To:
OPKG_CMD_PREFIX="opkg install"
OPKG_CMD_PREFIX_R="opkg remove"
```

### Creating IPK Packages

If you need to create custom IPK packages for your dependencies:

-   Use the Yocto build system to create proper IPK packages
-   Ensure the package name in the IPK control file matches the PkgName field
-   Test installation manually before including in p_manifest.json
-   Refer to mLinux Yocto documentation for detailed build instructions

**Best Practices**

-   Only include packages your application requires
-   Use specific package versions when possible
-   Test dependency installation on a clean mPower device, which is a device:
    -   With factory default settings or recently updated firmware
    -   Without other custom applications or manually installed packages that might mask missing dependencies
-   Document any custom IPK packages you create
-   Consider package size when choosing dependencies
-   Verify PkgName matches the actual package name in the IPK

**If Your Application Has No Dependencies**

If your application doesn't require additional packages:

-   Remove the `provisioning/` directory entirely, OR
-   Remove the IPK entries from p_manifest.json, leaving an empty array:
