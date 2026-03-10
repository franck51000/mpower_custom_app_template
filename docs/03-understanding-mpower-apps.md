# Understanding mPower Custom Applications

**Summary:** Custom applications are packaged software that integrates with the mPower framework. They follow a defined lifecycle from installation through running and eventual removal, with flexible installation locations to suit different use cases.

## What is a Custom Application?

A custom application is a packaged software program that runs on a mPower device within the mPower application framework. Custom applications are:

-   **Packaged as gzipped tar files (.tar.gz)** containing all required files
-   **Managed by app-manager**, a system service that handles installation, updates, and lifecycle management
-   **Integrated with MultiTech Device Manager**, allowing remote deployment and monitoring

Custom applications can perform various tasks such as:

-   Processing sensor data leveraging the TTN sensor codec to decode payloads and send downlinks
-   Implementing custom protocols
-   Integrating with third-party systems
-   Extending LoRaWAN functionality
-   Providing custom user interfaces

## Application Lifecycle

Understanding the application lifecycle is crucial for proper development. Applications move through several states:

**Installation**

-   The application package is transferred to the mPower device
-   The package is extracted to the installation directory
-   Dependencies are installed via the Install script
-   Application metadata is registered with the app-manager
-   Application is started automatically (unless disabled)

**Running**

-   Application processes are started via the Start script
-   Status is monitored through status.json
-   Configuration can be updated remotely
-   Logs are written to the system log

**Updates**

-   New version is installed alongside the existing version
-   The old version is stopped
-   Dependencies are updated
-   A new version has started
-   Old version is removed if new version installs successfully

**Uninstallation**

-   Application is stopped
-   Dependencies are removed via the Install script
-   All application files are deleted
-   Metadata is removed from the app-manager

**Firmware Upgrades**

When you upgrade the firmware on mPower devices, this preserves custom applications and automatically reinstalls app dependencies:

-   Firmware upgrade occurs and mPower device reboots
-   On first boot, dependencies reinstall for each installed app
-   Applications are started automatically

## Installation Locations

```
if PersistentStorage is true in manifest.json:
    Install to /var/persistent/<app_name>
else
    Install to /var/config/app/<app_name>
```

You can install custom applications in one of two locations, determined automatically or by configuration, with the main difference being that /var/persistent is significantly larger than /var/config/app:

**1. Flash Memory (/var/config/app/\<app_name\>)**

-   Survives firmware upgrades and reboots
-   Cleared on factory reset
-   Limited by available flash space

**2. Persistent Storage (/var/persistent/\<app_name\>)**

-   Survives firmware upgrades
-   Cleared on factory reset
-   Author must explicitly configure use in the app's manifest file

The installation location is determined by the algorithm:
