# mPower Custom Application Development Guide

Documentation for developing, packaging, and deploying custom applications on mPower devices running firmware 7.0 or later.

## Contents

1. [Introduction](01-introduction.md)
2. [Getting Started](02-getting-started.md)
3. [Understanding mPower Custom Applications](03-understanding-mpower-apps.md)
4. [Reviewing Application Package Structure](04-package-structure.md)
5. [Identifying Core Configuration Files](05-configuration-files.md)
6. [Working with Application Scripts](06-application-scripts.md)
7. [Building Your First Application](07-building-your-first-app.md)
8. [Packaging and Deploying](08-packaging-and-deploying.md)
9. [Application Management](09-application-management.md)
10. [Using Advanced Features](10-advanced-features.md)
11. [Troubleshooting](11-troubleshooting.md)
12. [Conclusion](12-conclusion.md)
13. [Appendices](13-appendices.md)

## Quick Links

- [Prerequisites](02-getting-started.md#prerequisites)
- [Package Structure](04-package-structure.md)
- [manifest.json Reference](05-configuration-files.md#manifestjson)
- [Install Script](06-application-scripts.md#install-script)
- [Start Script](06-application-scripts.md#start-script)
- [Bash Example App](07-building-your-first-app.md#bash-script-example)
- [Python Example App](07-building-your-first-app.md#python3-script-example)
- [Manual Installation](08-packaging-and-deploying.md#manual-installation)
- [MultiTech Device Manager Deployment](08-packaging-and-deploying.md#multitech-device-manager-deployment)
- [App-Manager CLI Reference](13-appendices.md#appendix-a-app-manager-command-reference)
- [Environment Variables Reference](13-appendices.md#appendix-d-environment-variables-reference)

## About

This guide covers mPower firmware 7.0+. Custom applications are packaged as `.tar.gz` files and managed by the `app-manager` service, with optional remote deployment via MultiTech Device Manager.
