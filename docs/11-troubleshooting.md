# Troubleshooting

**Summary:** Troubleshooting requires systematic investigation of logs, processes, files, and configuration. Use the debugging tools and techniques in this section to diagnose and resolve issues efficiently. Start with logs, verify basic functionality, then progressively narrow down the problem area.

## Common Issues

This section covers frequently encountered problems and their solutions.

**Installation Failures**

**Problem**: Package won't install

**Solutions:**

-   Verify package structure:
    ```bash
    tar -tzf MyApp.tgz | head -10
    ```
-   Ensure required files (manifest.json, Install, Start) are at top level

-   Check file permissions:
    ```bash
    tar -xzf MyApp.tgz
    ls -l Install Start
    ```
-   Both should be executable (`-rwxr-xr-x`) (-rwxr-xr-x)

-   Verify JSON syntax:
    ```bash
    cat manifest.json | python3 -m json.tool
    ```
-   Should output formatted JSON without errors without errors

**Problem**: Installation fails with "insufficient space"

**Solutions:**

-   Check available space:
    ```bash
    df -h /var/persistent
    df -h /var/config
    ```
-   Free up space or use PersistentStorage. Add to manifest.json:
    ```json
    "PersistentStorage": true
    ```

**Application Won't Start**

**Problem**: Status shows "START FAILED"

**Solutions:**

```bash
ls -l /var/config/app/MyApp/Start
chmod +x /var/config/app/MyApp/Start
```
```bash
cd /var/config/app/MyApp
./Start start
```
```bash
cd /var/config/app/MyApp
./Install install
```
```bash
grep "MyApp" /var/log/messages | tail -20
```

-   Check Start script permissions:

-   Test Start script manually:

-   Look for error messages

-   Check dependencies:

-   Verify all dependencies install successfully

-   Review logs:

**Problem**: Application starts but immediately stops

**Solutions:**

```bash
grep "MyApp" /var/log/messages
```
```bash
cd /var/config/app/MyApp
./myapp.py  # or whatever your executable is
```
```bash
ls -la /var/config/app/MyApp/config/
```
```bash
netstat -tulpn | grep <your_port>
```

-   Check application logs:

-   Test application directly:

-   Look for Python errors, missing modules, etc.

-   Verify configuration files exist:

-   Check for port conflicts:

**Status Issues**

**Problem**: Status shows "STARTED" instead of "RUNNING"

**Solution:** Application is not updating status.json. Add status tracking:

```python
# In your application
import json, os

def update_status(message):
    status = {"pid": os.getpid(), "AppInfo": message}
    with open('status.json', 'w') as f:
        json.dump(status, f)

# Call at startup
update_status("Application running")
```

**Problem**: Status shows "FAILED" but processes are running

**Solutions:**

```bash
cat /var/config/app/MyApp/status.json
```
```bash
ps aux | grep <pid_from_status>
```
```bash
# Check actual process PID
ps aux | grep myapp
# Compare with status.json
cat status.json
```

-   Check PID values in status.json:

-   Verify processes exist:

-   Ensure status.json is updated with correct PIDs:

**Problem**: Multi-process app shows FAILED when one process stops

```bash
# Check which process failed
grep "MyApp" /var/log/messages | tail -50
# Restart the application
app-manager --command restart --appid <id>
```

**Solution:** This is expected behavior. For multi-process apps, ALL processes must be running for status to show RUNNING. Investigate why the process stopped:

**Dependency Issues**

**Problem**: IPK installation fails

**Solutions:**

-   Check p_manifest.json syntax:
    ```bash
    cat provisioning/p_manifest.json | python3 -m json.tool
    ```
-   Verify IPK files exist:
    ```bash
    ls -la provisioning/*.ipk
    ```
-   Test manual installation:
    ```bash
    opkg install provisioning/mypackage.ipk
    ```
-   Check for dependency conflicts:
    ```bash
    opkg status <package_name>
    ```

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

```bash
grep CONFIG_DIR /var/config/app/MyApp/Start
```
```bash
ls -la /var/config/app/MyApp/config/
```
```bash
ls -l /var/config/app/MyApp/config/*.conf
```
```bash
DAEMON_ARGS="--config ${CONFIG_DIR}/app.conf"
```

-   Verify CONFIG_DIR is used in Start script:

-   Check config directory exists:

-   Verify file permissions:

-   Use absolute paths with CONFIG_DIR:

**Problem**: Configuration update via MultiTech Device Manager doesn't apply

**Solution:** The reload command must be implemented in Start script:

```bash
do_reload() {
    logger -t "$APP_ID" "Reloading configuration"

    # Option 1: Send SIGHUP to process
    if [ -f "$PIDFILE" ]; then
        kill -HUP $(cat "$PIDFILE")
    fi

    # Option 2: Restart (if application doesn't support SIGHUP)
    do_stop
    sleep 2
    do_start
}
```

## Debugging

Effective debugging requires understanding the available tools and techniques for diagnosing issues.

**Enabling Debug Mode**

```bash
#!/bin/bash
# Enable debug mode
DEBUG=${DEBUG:-0}

debug_log() {
    if [ "$DEBUG" = "1" ]; then
        logger -t "$APP_ID" "[DEBUG] $@"
        echo "[DEBUG] $@" >&2
    fi
}

do_start() {
    debug_log "Starting with APP_DIR=$APP_DIR"
    debug_log "DAEMON=$DAEMON"
    debug_log "DAEMON_ARGS=$DAEMON_ARGS"

    start-stop-daemon --start \
        --pidfile "$PIDFILE" \
        --exec "$DAEMON" \
        -- $DAEMON_ARGS

    local result=$?
    debug_log "start-stop-daemon returned: $result"
    return $result
}
```

Run with debug enabled:

```bash
DEBUG=1 ./Start start
```

Add debug logging to your Start script:

Run with debug enabled:

**Checking System Logs**

**View all application messages**

```bash
grep "MyApp" /var/log/messages
```

**View recent messages**

```bash
grep "MyApp" /var/log/messages | tail -50
```

**Follow logs in real-time**

```bash
tail -f /var/log/messages | grep "MyApp"
```

**View app-manager messages**

```bash
grep "app-manager" /var/log/messages
```

**View with timestamps**

```bash
grep "MyApp" /var/log/messages | tail -20
```

**Testing Scripts Manually**

**Test Install script**

```bash
cd /var/config/app/MyApp
export APP_DIR=$(pwd)
export APP_ID="APP_ID"
# Test install
./Install install
# Test postinstall
./Install postinstall
# Test remove
./Install remove
```

**Test Start script**

```bash
cd /var/config/app/MyApp
export APP_DIR=$(pwd)
export CONFIG_DIR="$APP_DIR/config"
export APP_ID="APP_ID"
# Test start
./Start start
# Check if running
ps aux | grep myapp
# Test stop
./Start stop
```

**Checking Process Status**

**Find your processes**

```bash
ps aux | grep myapp
```

**Check specific PID**

```bash
ps aux | grep <pid>
```

**Check process tree**

```bash
pstree -p | grep myapp
```

**Check what process is doing**

```bash
strace -p <pid>
```

**Checking File Access**

**Verify file exists**

```bash
ls -la /var/config/app/MyApp/myapp.py
```

**Check permissions**

```bash
ls -l /var/config/app/MyApp/Start
# Should show: -rwxr-xr-x
```

**Check file type**

```bash
file /var/config/app/MyApp/manifest.json
# Should show: ASCII text, with no line terminators
```

**Test file execution**

```bash
cd /var/config/app/MyApp/
./myapp.py  # Should run without "Permission denied"
```

**Checking Network Issues**

**Verify port listening**

```bash
netstat -tulpn | grep <port>
```

**Test connectivity**

```bash
ping <server>
curl http://<server>:<port>
```

**Check firewall**

```bash
firewall -4 --list all --stdout
```

**Python-Specific Debugging**

**Test import statements**

```bash
python3 -c "import requests"
```

**Run with verbose output**

```bash
python3 -v myapp.py
```

**Check Python path**

```bash
python3 -c "import sys; print('\n'.join(sys.path))"
```

**Verify module installation**

```bash
python3 -m pip list
```

**C/C++ Debugging**

**Check library dependencies**

```bash
ldd /var/config/app/MyApp/myapp
```

**Verify libraries exist**

```bash
ls -la /usr/lib/libboost*
```

**Run with debug output**

```bash
LD_DEBUG=libs /var/config/app/MyApp/myapp
```

**Storage and Space Issues**

**Check available space**

```bash
df -h
```

**Check inode usage**

```bash
df -i
```

**Interactive Debugging Session Example**

```bash
# 1. Connect to device
ssh admin@192.168.1.100
# 2. Switch to root account
sudo -s
# 3. Check application status
app-manager --command status
# 4. View recent logs
grep "MyApp" /var/log/messages | tail -30
# 5. Check processes
ps aux | grep myapp
# 6. Test Start script manually
cd /var/config/app/MyApp
export APP_DIR=$(pwd)
export CONFIG_DIR="$APP_DIR/config"
./Start start
# 7. If fails, check errors
echo $?  # Non-zero means error
# 8. Try running application directly
./myapp.py
# 9. Check status.json
cat status.json
```

**Creating Debug Packages**

For persistent issues, create a debug package:

```bash
#!/bin/bash
# collect-debug-info.sh
APP_ID="666d78aa-8270-446f-88cb-04c799558476"
OUTPUT="debug-${APP_ID}-$(date +%Y%m%d-%H%M%S).tar.gz"

mkdir -p /tmp/debug

app-manager --command status > /tmp/debug/status.txt
ps aux > /tmp/debug/processes.txt
df -h > /tmp/debug/disk.txt
free -m > /tmp/debug/memory.txt
grep "$APP_ID" /var/log/messages > /tmp/debug/app.log
cp -r /var/config/$APP_ID /tmp/debug/

tar -czf "$OUTPUT" -C /tmp debug/
echo "Debug package created: $OUTPUT"
```
