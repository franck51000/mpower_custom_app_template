# Packaging and Deploying

**Summary:** Packaging requires careful attention to structure, permissions, and line endings. Manual installation is useful for development and testing, while MultiTech Device Manager provides scalable deployment for production fleets. Understanding both approaches allows efficient development and reliable production deployments.

## Package Creation

Creating a proper application package is critical for successful installation. The package must be a gzipped tar file (.tar.gz or .tgz) with the correct structure.

**Package Requirements**

-   **File format:** gzipped tar archive (.tar.gz or .tgz)
-   **Structure:** All required files at the top level
-   **Permissions:** Install and Start scripts must be executable
-   **Line endings:** All script files used in the app must use UNIX (LF) line endings
-   **Filename:** Can be any name (doesn't need to match AppName)

`Check permissions before packaging`

**Creating the Package (Linux/Mac)**

Navigate to your application source directory and create the archive:

**Important tar Options**

  -----------------------------------------------------------------------
  **Option**            **Purpose**
  --------------------- -------------------------------------------------
  \--hard-dereference   Follow symbolic links and include actual files

  -h                    Follow symbolic links (short form)

  -c                    Create a new archive

  -z                    Compress with gzip

  -f                    Specify filename

  \*                    Include all files in the current directory
  -----------------------------------------------------------------------

**Verifying Package Contents**

Before deploying, verify your package structure:

Expected output:

**Common Packaging Mistakes**

-   **Extra directory level**

```{=html}
<!-- -->
```
-   **Solution:** Always cd into the source directory before creating the tar

```{=html}
<!-- -->
```
-   **Windows line endings**

-   **Missing required files**

**Creating Package (Windows with Git Bash or WSL)**

If developing on Windows, use Git Bash or WSL to create the package with proper line endings and permissions:

**Automated Packaging Script**

Create a script to automate packaging with verification:

## Manual Installation

Manual installation is useful for development and testing before deploying to production via MultiTech Device Manager.

**Prerequisites**

-   SSH access to the mPower device
-   Application package file (.tgz)

**Installation Steps**

**Step 1: Copy Package to mPower Device**

**Step 2: SSH to mPower Device**

**Step 4: Switch to root user**

**Step 3: Install Application**

The installation process

-   Validates the package
-   Extracts to the installation directory
-   Runs the Install script with the `install` argument
-   Runs the Install script with the `postinstall` argument
-   Starts the application via the Start script
-   Registers with app-manager

**Step 4: Verify Installation**

Expected output:

**Checking Installation Location**

**Viewing Logs**

**Uninstalling Manually Installed Apps**

Before deploying via MultiTech Device Manager, you must uninstall manually installed versions:

**Via Web UI**

-   Navigate to the Apps page
-   Find your application
-   Click **Uninstall**

**Via Command Line**

**Development Workflow**

For iterative development, use this workflow:

**Utility Scripts**

Download the [custom app SDK template](https://github.com/MultiTech-FAE/mpower_custom_app_template), which includes template files and utility scripts. Extract this to a working directory on your development machine.

## MultiTech Device Manager Deployment

MultiTech Device Manager provides cloud-based centralized management for deploying and managing custom applications across fleets of devices. Using Device Manager is the recommended approach for production deployments, especially when using MultiTech's cloud or onboarding services.

**Why Use Device Manager**

Cloud-first deployment offers significant advantages:

-   **Scalability**: Deploy to hundreds or thousands of devices simultaneously

-   **Centralized Control**: Manage all devices from a single web interface

-   **Scheduled Deployments**: Queue installations for specific times or device check-ins

-   **Version Management**: Track which versions are deployed where

-   **Configuration Management**: Update configuration files without full reinstalls

-   **Monitoring**: View application status across your entire fleet

-   **Audit Trail**: Complete history of all deployment actions

-   **Remote Access**: Manage devices regardless of physical location

**Prerequisites**

-   MultiTech Device Manager account with appropriate permissions

-   Devices registered and checking into Device Manager

-   Application package prepared and tested locally

-   Understanding of your deployment strategy (staged rollout vs. fleet-wide)

**Deployment Workflow in MultiTech Device Manager**

**Step 1: Upload Application to Device Manager**

1.  Log into MultiTech Device Manager web interface

2.  Navigate to the **Developer** page

3.  Click **Upload Application**

4.  Select your application package (.tgz file)

5.  Device Manager extracts and validates manifest.json

6.  Review application details:

    a.  AppName

    b.  AppVersion

    c.  AppDescription

    d.  AppVersionNotes

7.  Confirm and complete upload

The application is now available in Device Manager's application repository and can be deployed to any registered device.

**Step 2: Deploy to Devices**

1.  Navigate to the **Devices** page

2.  Select target device(s):

    a.  Single device for testing

    b.  Small group for staged rollout

    c.  Multiple devices for fleet-wide deployment

3.  Click **Schedule Action**

4.  Select **Install App**

5.  Choose your application from the dropdown list

6.  Select version (if multiple versions uploaded)

7.  (Optional) Select configuration file to install with application

8.  Choose deployment timing:

    a.  **Immediate**: Install on next device check-in

    b.  **Scheduled**: Install at specific date/time

9.  Review and confirm

**Step 3: Monitor Deployment**

1.  View **Scheduled Actions** to track pending installations

2.  Devices check in periodically (typically every 15 minutes)

3.  On check-in, devices:

    a.  Receive deployment command

    b.  Download application package

    c.  Verify package integrity (MD5 checksum)

    d.  Install application

    e.  Report installation status back to Device Manager

4.  Monitor progress in device details page

5.  Check **Installed Apps** section for each device

**Step 4: Verify Installation**

1.  Navigate to individual device details

2.  View **Installed Apps** section showing:

    a.  Application name

    b.  Installed version

    c.  Current status (RUNNING, STOPPED, FAILED)

    d.  AppInfo message

    e.  Last update time

3.  Verify status is RUNNING and AppInfo shows expected state

**Cloud-Based Installation Process**

When Device Manager triggers an installation, app-manager on the device performs a cloud install rather than a local file install:

Note: No \--appfile option is provided. This tells app-manager to:

1.  Contact Device Manager cloud servers

2.  Download application package for the specified AppID and version

3.  Verify MD5 checksum of downloaded package

4.  Install if checksum matches

5.  Report results back to Device Manager

**Managing Applications via Device Manager:**

**Update Application Version:**

1.  Upload new version to Device Manager

2.  Navigate to **Devices** page

3.  Select target device(s)

4.  Schedule **Install App** action

5.  Select application name

6.  Select NEW version from dropdown

7.  Confirm deployment

Device Manager automatically:

-   Stops old version

-   Downloads and installs new version

-   Starts new version

-   Removes old version files

-   Updates device status

**Update Configuration Files:**

Configuration management through Device Manager is far more efficient than manual command-line editing, especially when managing multiple files or multiple devices.

1.  Navigate to **Developer** page

2.  Click on your application

3.  Go to **Configurations** tab

4.  Click **Upload Configuration**

5.  Select configuration file(s) to upload

6.  Provide description/notes

7.  Complete upload

To deploy configuration to devices:

1.  Navigate to **Devices** page

2.  Select target device(s)

3.  Schedule **Install App Config** action

4.  Select application

5.  Select configuration file(s) to install

6.  Confirm deployment

When devices receive the config update:

-   app-manager downloads new configuration file(s)

-   Files are placed in the application's config/ directory

-   Existing files with same names are replaced

-   app-manager executes Start reload command

-   Application reloads configuration without full restart

**Start/Stop Applications:**

1.  Navigate to **Devices** page

2.  Select device(s)

3.  Schedule action:

    -   **Start App**: Start stopped application

    -   **Stop App**: Stop running application

    -   **Restart App**: Stop then start application

4.  Select application

5.  Confirm

**Uninstall Applications:**

1.  Navigate to **Devices** page

2.  Select device(s)

3.  Schedule **Uninstall App** action

4.  Select application

5.  Confirm

Device Manager will:

-   Stop application

-   Execute Install remove to clean up dependencies

-   Delete entire application directory

-   Update device status

**Staged Rollout Strategy:**

For production deployments, use a staged approach:

**Phase 1 - Development Testing:**

-   Test manual installation on development device

-   Verify all functionality

-   Test install/uninstall/upgrade cycles

-   Review logs for any issues

**Phase 2 - Pilot Group (1-5 devices):**

1.  Upload application to Device Manager

2.  Deploy to small pilot group

3.  Monitor for 24-48 hours

4.  Check status across all pilot devices

5.  Review any failures or issues

6.  Verify application performance

**Phase 3 - Staged Rollout (10-20% of fleet):**

1.  Deploy to larger subset of fleet

2.  Monitor for several days

3.  Gather feedback on performance and stability

4.  Address any issues discovered

**Phase 4 - Full Deployment:**

1.  Deploy to remaining devices

2.  Continue monitoring across fleet

3.  Use scheduled deployment for different time zones

4.  Have rollback plan ready

**Monitoring and Troubleshooting:**

**View Application Status Across Fleet:**

1.  Use Device Manager dashboard

2.  Filter devices by application status

3.  Identify devices with FAILED or STOPPED status

4.  Investigate individual device logs

**Troubleshoot Failed Installations:**

1.  Check device details for error messages

2.  Review scheduled action results

3.  SSH to device and check logs:

bash

grep \"app-manager\" /var/log/messages \| tail -50

4.  Verify device has sufficient storage

5.  Check network connectivity to Device Manager

6.  Retry installation if transient issue

**Handle Devices That Won't Update:**

1.  Verify device is checking in regularly

2.  Check device connectivity to Device Manager

3.  Force device check-in:

bash

/etc/init.d/devicehq restart

4.  Review device logs for check-in errors

5.  Contact MultiTech support if persistent issues

**Best Practices for Device Manager Deployment:**

1.  **Always Test Locally First**: Never upload to Device Manager without local testing

2.  **Use Semantic Versioning**: Clear version numbers help track deployments

    -   Example: 1.0.0 → 1.0.1 (patch) → 1.1.0 (minor) → 2.0.0 (major)

3.  **Write Detailed Version Notes**: Help track what changed between versions

    -   Include: bug fixes, new features, breaking changes, dependencies updated

4.  **Start Small**: Pilot deployments catch issues before fleet-wide impact

5.  **Use Configuration Updates**: Prefer config updates over full reinstalls when possible

    -   Faster deployment

    -   Less disruptive

    -   Lower bandwidth usage

6.  **Schedule Appropriately**: Consider operational impact

    -   Off-peak hours for non-critical updates

    -   Maintenance windows for major changes

    -   Stagger updates across time zones

7.  **Monitor Actively**: Don't assume success

    -   Check status after deployments

    -   Set up alerts for failures

    -   Review logs periodically

8.  **Document Deployments**: Maintain deployment records

    -   Which version deployed when

    -   Which devices received update

    -   Any issues encountered

9.  **Have Rollback Plan**: Be prepared to revert

    -   Keep previous version available

    -   Test rollback procedure

    -   Know how to quickly revert if needed

10. **Leverage Device Manager Features**:

    -   Use device groups for organizational units

    -   Apply tags for deployment targeting

    -   Set up custom alerts

    -   Use scheduled deployments for automation

**Integration with MultiTech Services**

**Onboarding Services**

When using MultiTech's professional onboarding services, Device Manager enables:

-   Pre-configured application deployment during device provisioning

-   Standardized application versions across customer fleet

-   Automated application installation as part of onboarding workflow

-   Consistent configuration across all provisioned devices

**Cloud Services**

Device Manager integrates with MultiTech's broader cloud ecosystem:

-   Application status visible in cloud dashboards

-   Automated alerts and notifications

-   Integration with cloud APIs for programmatic management

-   Data collection and analytics on application performance

**Advantages Over Local Installation**

  ------------------------------------------------------------------------------
  **Aspect**      **Local Installation**         **Device Manager**
  --------------- ------------------------------ -------------------------------
  Scale           One device at a time           Entire fleet simultaneously

  Access          Requires SSH/physical access   Web interface from anywhere

  Tracking        Manual record keeping          Automatic deployment history

  Configuration   Edit files on each device      Push configs from cloud

  Monitoring      SSH to each device             Dashboard view of all devices

  Rollback        Manual on each device          Schedule rollback deployment

  Scheduling      Immediate only                 Schedule future deployments

  Audit           Limited                        Complete action history
  ------------------------------------------------------------------------------

**When to Use Each Approach**

Use Local Installation for:

-   Development and testing

-   Proof-of-concept work

-   Single device deployments

-   Troubleshooting specific device issues

-   Learning and training

Use Device Manager for:

-   Production deployments

-   Multiple devices

-   Fleet management

-   Configuration updates across devices

-   Version tracking and management

-   Professional/enterprise deployments

-   Integration with MultiTech services

**Common Issues and Solutions**

**Installation Pending for Extended Time:**

-   Check device connectivity to Device Manager

-   Verify device check-in interval (default 15 minutes)

-   Force check-in: /etc/init.d/devicehq restart

**Installation Fails - Insufficient Storage:**

-   Free up space on device

-   Remove old application versions

-   Use SD card for installation: \"SDCard\": true in manifest.json

**Configuration Update Doesn't Apply:**

-   Verify reload command implemented in Start script

-   Check application actually reloads config files

-   Review application logs for reload errors

**Application Status Not Updating:**

-   Verify status.json is being written correctly

-   Check PID values are accurate

-   Wait for next device check-in (up to 15 minutes)

-   Review app-manager logs

**Version Mismatch After Update:**

-   Verify correct version selected in deployment

-   Check if installation actually succeeded

-   Review device logs for installation errors

-   Reinstall if necessary
