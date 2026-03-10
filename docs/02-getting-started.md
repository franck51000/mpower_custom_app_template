# Getting Started

## Prerequisites

Before beginning custom application development, ensure you have the following knowledge and tools:

**Technical Skills**

-   Experience developing embedded Linux applications
-   Fluency in one or more supported languages: Python3, BASH, C++, or C
    -   The languages we support are open for debate, for example, you may also be able to create an application in Rust or using Mono/C# and node.js.
-   Knowledge of UNIX/Linux file systems and permissions
-   Familiarity with command-line tools and shell scripting

**Development Tools**

-   A text editor capable of creating and editing files with the UNIX line ending convention (LF, not CRLF)
-   Archive software capable of creating tar/gzip format files (.tar.gz)
-   SSH client for accessing the mPower device
-   (Optional) Cross-compilation toolchain for C/C++ applications

**Hardware**

-   mPower device running mPower firmware 7.0 or later
-   Network connectivity to the mPower device

## Development Environment Setup

To set up your development environment:

1.  **Obtain the custom app template:** Download the [custom app SDK template](https://github.com/MultiTech-FAE/mpower_custom_app_template), which includes template files and utility scripts. Extract this to a working directory on your development machine.

2.  **Verify device access:** Ensure you can SSH into your mPower device:

```bash
$ ssh admin@<your_device_ip>
```

3.  **Install Development Tools:** For C/C++ development, set up the appropriate cross-compilation toolchain for your target mPower device architecture. mPower and mLinux SDKs are available [to download](https://www.multitech.net/developer/downloads/).
