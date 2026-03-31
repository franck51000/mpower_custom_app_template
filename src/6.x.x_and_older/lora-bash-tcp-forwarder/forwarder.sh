#!/bin/bash
# =============================================================================
# forwarder.sh — LoRa Bash TCP Forwarder (mPower 6.x.x)
#
# Listens for Semtech UDP packet-forwarder datagrams on LISTEN_PORT (default
# 1700).  For each received PUSH_DATA datagram, saves it as the "last frame"
# and forwards it to a PHP server over a raw TCP connection on PHP_PORT
# (default 3001).
#
# Transport: raw TCP (nc), NOT HTTP.
# Language:  sh/bash (no Python).
#
# Usage (invoked by Start):
#   APP_DIR=/opt/lora-bash-tcp-forwarder \
#   CONFIG_DIR=/opt/lora-bash-tcp-forwarder/config \
#   ./forwarder.sh
#
# Dependencies: socat, nc (netcat/busybox), od, dd, date, logger
# =============================================================================

# ---------------------------------------------------------------------------
# Load configuration
# ---------------------------------------------------------------------------
CFG_FILE="${CONFIG_DIR:-$(dirname "$0")/config}/forwarder.cfg"
if [ -f "$CFG_FILE" ]; then
    # shellcheck source=/dev/null
    . "$CFG_FILE"
fi

LISTEN_PORT="${LISTEN_PORT:-1700}"
PHP_HOST="${PHP_HOST:-192.168.1.100}"
PHP_PORT="${PHP_PORT:-3001}"
LOG_FILE="${LOG_FILE:-/var/log/lora_tcp_forwarder.log}"

APP_DIR="${APP_DIR:-$(dirname "$0")}"
HANDLER="${APP_DIR}/handle_packet.sh"

# Temporary directory for runtime files (last frame, etc.)
LAST_FRAME_DIR="/tmp/lora_tcp_fwd"
mkdir -p "$LAST_FRAME_DIR"

# ---------------------------------------------------------------------------
# Logging helper
# ---------------------------------------------------------------------------
log() {
    _level="$1"; shift
    _msg="$(date -u '+%Y-%m-%dT%H:%M:%SZ') [${_level}] lora-tcp-fwd: $*"
    printf '%s\n' "$_msg" >> "$LOG_FILE"
    logger -t lora-tcp-fwd "${_level}: $*" 2>/dev/null || true
}

# ---------------------------------------------------------------------------
# Clean up on exit
# ---------------------------------------------------------------------------
cleanup() {
    log INFO "Forwarder stopping"
    exit 0
}
trap cleanup INT TERM

# ---------------------------------------------------------------------------
# Sanity checks
# ---------------------------------------------------------------------------
if [ ! -x "$HANDLER" ]; then
    log ERROR "handle_packet.sh not found or not executable: $HANDLER"
    exit 1
fi

if ! command -v socat >/dev/null 2>&1; then
    log ERROR "socat not found — install via: opkg install socat"
    exit 1
fi

# ---------------------------------------------------------------------------
# Export config for handle_packet.sh subprocesses
# ---------------------------------------------------------------------------
export PHP_HOST PHP_PORT LOG_FILE LAST_FRAME_DIR

# ---------------------------------------------------------------------------
# Start listener
# ---------------------------------------------------------------------------
log INFO "=== LoRa TCP Forwarder starting ==="
log INFO "Listening on UDP :${LISTEN_PORT}"
log INFO "Forwarding last frame to TCP ${PHP_HOST}:${PHP_PORT}"

# socat UDP4-RECVFROM with fork:
#   - binds to LISTEN_PORT and keeps it open
#   - for each received UDP datagram, forks a new process running handle_packet.sh
#   - the forked process receives the raw datagram bytes on stdin
#   - reuseaddr: allow reuse of the port after restart
exec socat \
    "UDP4-RECVFROM:${LISTEN_PORT},reuseaddr,fork" \
    "EXEC:${HANDLER}"
