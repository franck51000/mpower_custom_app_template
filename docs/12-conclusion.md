# Conclusion

This guide provided comprehensive coverage of creating, packaging, deploying, and managing custom applications on mPower devices running mPower firmware 7.0 or later.

**Key Takeaways**

-   **Structure Matters**: Follow the required package structure with manifest.json, Install, and Start scripts at the top level

-   **Scripts Are Critical**: Properly implemented Install and Start scripts ensure reliable installation and lifecycle management

-   **Status Tracking**: Implementing status.json enables accurate monitoring and helpful user feedback

-   **Test Locally**: Always test manual installation before deploying via MultiTech Device Manager

-   **Use Environment Variables**: Leverage APP_DIR, CONFIG_DIR, and other variables for portability

-   **Log Everything**: Use system logging for troubleshooting and monitoring

-   **Follow Best Practices**: Implement graceful shutdown, manage error handling, test app behavior after firmware upgrades, and ensure proper cleanup

**Next Steps:**

-   Download the [custom app SDK template](https://github.com/MultiTech-FAE/mpower_custom_app_template)
-   Study the example applications
-   Create a simple test application
-   Deploy to a development mPower device
-   Iterate and enhance
-   Deploy to production via MultiTech Device Manager

**Additional Resources:**

-   [Custom App SDK:](https://github.com/MultiTech-FAE/mpower_custom_app_template) Contains templates and utility scripts
-   [mLinux Documentation:](https://www.multitech.net/developer/software/mlinux/) For Yocto and cross-compilation information
-   [MultiTech Support:](https://support.multitech.com) For assistance with specific issues
