# Appendices

## Appendix A: App-Manager Command Reference

Complete reference for all app-manager commands and options. Syntax is:

**Commands**

**install** - Install a custom application

**install --** Install an application from a tarball

**install --** Install an application from the cloud

**remove** - Uninstall a custom application

**start** - Start a stopped application

**stop** - Stop a running application

**restart** - Restart an application

**status** - Display status of all applications

**config** - Install configuration file (R.7.1.0+)

**installdeps** - Install dependencies only (R.7.1.0+)

**list-installed** - List installed applications (R.7.1.0+)

**Exit Codes**

-   **0**: Success
-   **1**: General error
-   **2**: Invalid arguments
-   **3**: Application not found
-   **4**: Installation failed
-   **5**: Start/stop failed

## Appendix B: Status Transitions

Visual reference for application status states and transitions. Status states are:

-   **STARTED** - Application has been started but status.json not present or not being monitored
-   **RUNNING** - All monitored processes are running
-   **STOPPED** - Application has been stopped
-   **FAILED** - One or more monitored processes are not running
-   **INSTALL FAILED** - Installation encountered errors
-   **START FAILED** - Application failed to start

**Installation State Transition Diagram**

![Diagram](media/image1.png)

**Uninstallation State Diagram**

![Diagram](media/image2.png)

**Status Display Rules**

  ---------------------------------------------------------------------------
  **Condition**                             **Status**            **Color**
  ----------------------------------------- --------------------- -----------
  No status.json present                    STARTED               Yellow

  status.json exists, all PIDs running      RUNNING               Green

  status.json exists, any PID not running   FAILED                Red

  Application stopped via stop command      STOPPED               Red

  Installation failed                       INSTALL FAILED        Red

  Start command failed                      START FAILED          Red
  ---------------------------------------------------------------------------

**Multi-Process Status Logic**

## Appendix C: Direct Process Management Example

## Appendix D: Environment Variables Reference

Complete reference for environment variables available to Install and Start scripts.

**Variables Set by App-Manager (R.7.1.0+)**

  ------------------------------------------------------------------------------------------------------------------
  **Variable**   **Description**                                   **Example Value**              **Available In**
  -------------- ------------------------------------------------- ------------------------------ ------------------
  APP_DIR        Full path to application installation directory   /var/config/MyApp              Start

  CONFIG_DIR     Full path to configuration directory              /var/config/app/MyApp/config   Start

  APP_ID         Application name from MT Device Manager           611d1dde31eddd056018b8bf       Start
  ------------------------------------------------------------------------------------------------------------------

**Usage Examples**

**In Start script**

**Providing Default Values**

Always provide defaults for robustness:

**Passing to Your Application**

Export variables for your application to use:

**Python Access**

**Additional System Variables**

These standard Linux variables are also available:

  -----------------------------------------------------------------------
  **Variable**       **Description**
  ------------------ ----------------------------------------------------
  PATH               System executable search path

  HOME               User home directory

  USER               Current user (usually root)

  PWD                Current working directory

  SHELL              Current shell
  -----------------------------------------------------------------------

**Best Practices**

-   **Always use APP_DIR** for application files
-   **Use CONFIG_DIR** for configuration files
-   **Provide defaults** for all variables
-   **Export if needed** by your application
-   **Document** expected variables in your code
-   **Test manually** by setting variables and running scripts
