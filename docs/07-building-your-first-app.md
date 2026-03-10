# Building Your First Application

**Summary:** These examples demonstrate the complete workflow for creating custom applications in different languages. Each example follows the same basic pattern: create a directory structure, configure manifest.json, customize scripts, implement application logic, and package. Use these as templates for your own applications.

This section provides complete, working examples of custom applications in different languages. Each example demonstrates the minimal required structure and can serve as a starting point for your own applications.

## Bash Script Example

This example creates a simple application that queries the LoRa network server for mPower device information and writes it to a timestamped file.

**Step 1: Create Application Directory**

```bash
$ mkdir -p BashExampleApp/src
$ cd BashExampleApp/src
```

**Step 2: Copy Template Files**

Assuming you have the custom app template in your home directory:

```bash
$ cp ~/mpower_custom_app_template/src/manifest.json.basic.example ./manifest.json
$ cp ~/mpower_custom_app_template/src/Install .
$ cp ~/mpower_custom_app_template/src/Start .
```

**Step 3: Edit manifest.json**

Create your manifest.json with this content:

```json
{
  "AppName": "BashExampleApp",
  "AppVersion": "0.0.1",
  "AppDescription": "Example mPower application runs a Bash script",
  "AppVersionNotes": "First Version",
  "PersistentStorage": true
}
```

**Step 4: Edit Start Script**

Update these variables in the Start script:

```bash
NAME="BashExampleApp"
DAEMON="${APP_DIR}/BashExampleApp.sh"
DAEMON_DEBUG_ARGS=""
DAEMON_ARGS="${DAEMON_DEBUG_ARGS}"
```

**Step 5: Create BashExampleApp.sh**

Create your application script:

```bash
#!/bin/bash
PID=$$
remaining=10000
logwarn() { logger -s -p warning -t "BashExampleApp" "warn: $*" 1>&2 ;}
while [[ "$remaining" -ge 1 ]]
do
  logwarn "Countdown: $remaining. Pwd=$(pwd)"
  echo "{"pid":$PID,"AppInfo":"Pid: $PID, countdown: $remaining seconds"}" > ./status.json
  ((remaining--))
  sleep 1
done
```

Make it executable:

```bash
$ chmod +x BashExampleApp.sh
```

**Step 6: Package and Install**

Create the package:

```bash
$ tar --hard-dereference -hczf BashExampleApp_0_0_1.tgz manifest.json Install Start BashExampleApp.sh
```

Copy to mPower device and install:

```bash
# Copy tarball to the device /tmp/ dir
$ scp BashExampleApp_0_0_1.tgz admin@<ip_address>:/tmp/
# SSH into the device as admin user
$ ssh admin@<ip_address>
# Switch to root user
$ sudo -s
# Install the app
$ app-manager --command install --appid 9dad30bf-8917-4fde-8f86-6b7d2216b130 --appfile /tmp/BashExampleApp_0_0_1.tgz
```

**Expected Result**

-   Application installs to /var/persistent/BashExampleApp/
-   Script runs and creates mPower device list file
-   Check status: `app-``manager --command`` status`

## Python3 Script Example

This example creates a Python application that demonstrates proper status.json usage and configuration file handling.

**Step 1: Create Application Directory**

```bash
$ mkdir -p Python3ExampleApp/src
$ cd Python3ExampleApp/src
```

**Step 2: Copy Template Files**

```bash
$ cp ~/mpower_custom_app_template/src/manifest.json.basic.example ./manifest.json
$ cp ~/mpower_custom_app_template/src/Install .
$ cp ~/mpower_custom_app_template/src/Start .
$ cp ~/mpower_custom_app_template/src/status.json .
```

**Step 3: Edit manifest.json**

```json
{
  "AppName": "Python3ExampleApp",
  "AppVersion": "0.0.1",
  "AppDescription": "Example mPower application runs a python script",
  "AppVersionNotes": "First Version",
  "PersistentStorage": true
}
```

**Step 4: Edit Start Script**

Update these variables:

```bash
NAME="Python3ExampleApp"
DAEMON="/usr/bin/python3"
DAEMON_ARGS="${APP_DIR}/Python3ExampleApp.py"
DAEMON_DEBUG_ARGS=""
```

**Step 5: Create Python3ExampleApp.py**

Create your Python application:

```python
#!/usr/bin/env python3
"""Python3ExampleApp.py - Example mPower custom application"""

import os, sys, json, time, signal, logging

logging.basicConfig(level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s')
logger = logging.getLogger('Python3ExampleApp')

running = True

def signal_handler(signum, frame):
    global running
    running = False

def update_status(message):
    status = {"pid": os.getpid(), "AppInfo": message}
    with open('status.json', 'w') as f:
        json.dump(status, f, indent=2)

def main():
    global running
    signal.signal(signal.SIGTERM, signal_handler)
    signal.signal(signal.SIGINT, signal_handler)

    logger.info("Python3ExampleApp starting")
    update_status("Application starting")

    counter = 0
    while running:
        counter += 1
        update_status(f"Running - Counter: {counter}")
        time.sleep(10)

    update_status("Application stopped")
    logger.info("Python3ExampleApp stopped")

if __name__ == "__main__":
    main()
```

Make it executable:

```bash
$ chmod +x Python3ExampleApp.py
```

**Step 6: Package Application**

```bash
$ tar --hard-dereference -hczf Python3ExampleApp_0_0_1.tgz manifest.json Install Start status.json Python3ExampleApp.py
```

**Step 7: Install and Verify**

```bash
$ scp Python3ExampleApp_0_0_1.tgz admin@<device_ip>:/tmp/
$ ssh admin@<device_ip>
$ sudo -s
$ app-manager --command install --appid 9dad30bf-8917-4fde-8f86-6b7d2216b130 --appfile /tmp/Python3ExampleApp_0_0_1.tgz
$ app-manager --command status
```

**Expected Result**

-   Application starts and updates status every 10 seconds
-   Status shows the current counter value
-   Application handles SIGTERM gracefully
