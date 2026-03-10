# Reviewing Application Package Structure

**Summary:** Custom applications must follow a specific structure with required files at the top level. Optional files and directories add functionality for monitoring, configuration, and dependency management. Understanding this structure is fundamental to creating valid application packages.

## Required Files

Every custom application package must include these files at the top level:

**manifest.json:** Contains metadata about your application, including name, version, description, and installation preferences. This is the primary configuration file read by the app-manager during installation.

**Install:** A script that handles the installation and removal of application and their dependencies. Must be executable and support specific command-line arguments (install, postinstall, remove).

**Start:** A script that starts, stops, and restarts your application processes. Must be executable and support specific command-line arguments (start, stop, restart, reload).

## Optional Files

These files enhance functionality but are not required:

**status.json:** Provides process tracking and status information. Allows the app-manager tor your application and provide a detailed status to users. Recommended for production applications.

**version_extra:** Contains an additional version identifier separate from the main version. Useful for tracking build numbers, branches, or other supplementary version information.

**config/ (directory):** Contains configuration files that can be updated remotely through MultiTech Device Manager. Files placed here can be modified without reinstalling the entire application.

**provisioning/ directory:** Contains IPK dependency packages and p_manifest.json. Used when your application requires additional system packages to be installed.

## Directory Layout

```
MyApplication/
├── manifest.json           (required)
├── Install                 (required)
├── Start                   (required)
├── status.json            (optional)
├── version_extra          (optional)
├── config/                (optional)
│   └── app.conf
├── provisioning/          (optional)
│   ├── p_manifest.json
│   ├── dependency1.ipk
│   └── dependency2.ipk
└── <application files>
    ├── myapp.py
    └── lib/
        └── helper.py
```

A complete application package has this structure:

**Important Notes**

-   All required files must be present at the top level of the package
-   The package structure is preserved during installation
-   File permissions must be set correctly (Install and Start must be executable)
-   The tarball name does not need to match the application name

## After Installation

```
/var/config/app/MyApplication/   (or /var/persistent/)
├── manifest.json
├── Install
├── Start
├── status.json
├── version_extra
├── config/
│   └── app.conf
├── provisioning/
│   ├── p_manifest.json
│   ├── dependency1.ipk
│   └── dependency2.ipk
└── <application files>
```

Once installed, your application structure appears in the installation directory:
