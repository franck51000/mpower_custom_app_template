# Troubleshooting

**Summary:** Troubleshooting requires systematic investigation of logs, processes, files, and configuration. Use the debugging tools and techniques in this section to diagnose and resolve issues efficiently. Start with logs, verify basic functionality, then progressively narrow down the problem area.

## Common Issues

This section covers frequently encountered problems and their solutions.

**Installation Failures**

**Problem**: Package won't install

**Solutions:**

-   Verify package structure:

```{=html}
<!-- -->
```
-   Ensure required files (manifest.json, Install, Start) are at top level

```{=html}
<!-- -->
```
-   Check file permissions:

```{=html}
<!-- -->
```
-   Both should be executable (-rwxr-xr-x)

```{=html}
<!-- -->
```
-   Verify JSON syntax:

```{=html}
<!-- -->
```
-   Should output formatted JSON without errors

**Problem**: Installation fails with \"insufficient space\"

**Solutions:**

-   Check available space:

-   Free up space

-   Use PersistentStorage: Add to manifest.json:

**Application Won't Start**

**Problem**: Status shows \"START FAILED\"

**Solutions:**

-   Check Start script permissions:

-   Test Start script manually:

```{=html}
<!-- -->
```
-   Look for error messages

```{=html}
<!-- -->
```
-   Check dependencies:

```{=html}
<!-- -->
```
-   Verify all dependencies install successfully

```{=html}
<!-- -->
```
-   Review logs:

**Problem**: Application starts but immediately stops

**Solutions:**

-   Check application logs:

-   Test application directly:

```{=html}
<!-- -->
```
-   Look for Python errors, missing modules, etc.

```{=html}
<!-- -->
```
-   Verify configuration files exist:

-   Check for port conflicts:

**Status Issues**

**Problem**: Status shows \"STARTED\" instead of \"RUNNING\"

**Solution:** Application is not updating status.json. Add status tracking:

**Problem**: Status shows \"FAILED\" but processes are running

**Solutions:**

-   Check PID values in status.json:

-   Verify processes exist:

-   Ensure status.json is updated with correct PIDs:

**Problem**: Multi-process app shows FAILED when one process stops

**Solution:** This is expected behavior. For multi-process apps, ALL processes must be running for status to show RUNNING. Investigate why the process stopped:

**Dependency Issues**

**Problem**: IPK installation fails

**Solutions:**

-   Check p_manifest.json syntax:

-   Verify IPK files exist:

-   Test manual installation:

-   Check for dependency conflicts:

**Problem**: Application works locally but fails after MultiTech Device Manager deployment

**Solutions:**

-   Verify package uploaded correctly to MultiTech Device Manager

-   Check that mPower device has sufficient space

-   Review mPower device logs after deployment:

-   Ensure MultiTech Device Manager selected correct version

-   Try manual installation to isolate MultiTech Device Manager vs package issue

**Configuration Issues**

**Problem**: Configuration file not found

**Solutions:**

-   Verify CONFIG_DIR is used in Start script:

-   Check config directory exists:

-   Verify file permissions:

-   Use absolute paths with CONFIG_DIR:

**Problem**: Configuration update via MultiTech Device Manager doesn't apply

**Solution:** The reload command must be implemented in Start script:

## Debugging

Effective debugging requires understanding the available tools and techniques for diagnosing issues.

**Enabling Debug Mode**

Add debug logging to your Start script:

Run with debug enabled:

**Checking System Logs**

**View all application messages**

**View recent messages**

**Follow logs in real-time**

**View app-manager messages**

**View with timestamps**

**Testing Scripts Manually**

**Test Install script**

**Test Start script**

**Checking Process Status**

**Find your processes**

**Check specific PID**

**Check process tree**

**Check what process is doing**

**Checking File Access**

**Verify file exists**

**Check permissions**

**Check file type**

**Test file execution**

**Checking Network Issues**

**Verify port listening**

**Test connectivity**

**Check firewall**

**Python-Specific Debugging**

**Test import statements**

**Run with verbose output**

**Check Python path**

**Verify module installation**

**C/C++ Debugging**

**Check library dependencies**

**Verify libraries exist**

**Run with debug output**

**Storage and Space Issues**

**Check available space**

**Check inode usage**

**Interactive Debugging Session Example**

**Creating Debug Packages**

For persistent issues, create a debug package:
