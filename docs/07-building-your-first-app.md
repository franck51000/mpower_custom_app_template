# Building Your First Application

**Summary:** These examples demonstrate the complete workflow for creating custom applications in different languages. Each example follows the same basic pattern: create a directory structure, configure manifest.json, customize scripts, implement application logic, and package. Use these as templates for your own applications.

This section provides complete, working examples of custom applications in different languages. Each example demonstrates the minimal required structure and can serve as a starting point for your own applications.

## Bash Script Example

This example creates a simple application that queries the LoRa network server for mPower device information and writes it to a timestamped file.

**Step 1: Create Application Directory**

**Step 2: Copy Template Files**

Assuming you have the custom app template in your home directory:

**Step 3: Edit manifest.json**

Create your manifest.json with this content:

**Step 4: Edit Start Script**

Update these variables in the Start script:

**Step 5: Create BashExampleApp.sh**

Create your application script:

Make it executable:

**Step 6: Package and Install**

Create the package:

Copy to mPower device and install:

**Expected Result**

-   Application installs to /var/persistent/BashExampleApp/
-   Script runs and creates mPower device list file
-   Check status: `app-``manager --command`` status`

## Python3 Script Example

This example creates a Python application that demonstrates proper status.json usage and configuration file handling.

**Step 1: Create Application Directory**

**Step 2: Copy Template Files**

**Step 3: Edit manifest.json**

**Step 4: Edit Start Script**

Update these variables:

**Step 5: Create Python3ExampleApp.py**

Create your Python application:

Make it executable:

**Step 6: Package Application**

**Step 7: Install and Verify**

**Expected Result**

-   Application starts and updates status every 10 seconds
-   Status shows the current counter value
-   Application handles SIGTERM gracefully
