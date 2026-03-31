#!/bin/bash
# =============================================================================
# handle_packet.sh — Per-datagram handler for lora-bash-tcp-forwarder
#
# Called by socat (EXEC with fork) for every received UDP datagram.
# stdin  = raw datagram bytes (one Semtech packet)
# stdout = ignored (no ACK sent back — acceptable for monitoring use-cases)
#
# What this script does:
#  1. Reads raw datagram from stdin into a temp file.
#  2. Parses the 4-byte Semtech UDP header to get the packet type.
#  3. If PUSH_DATA (type 0x00): extracts the JSON payload (bytes 13+),
#     builds a JSON object, saves it atomically as the "last frame", and
#     sends it to the PHP server over a raw TCP connection on PHP_PORT.
#  4. Non-PUSH_DATA packets (PULL_DATA keepalives, etc.) are logged and
#     discarded without forwarding.
#
# Environment (set by forwarder.sh):
#   PHP_HOST        — remote PHP server host/IP
#   PHP_PORT        — remote PHP server TCP port (default 3001)
#   LOG_FILE        — path to log file
#   LAST_FRAME_DIR  — directory for runtime temp files
# =============================================================================

PHP_HOST="${PHP_HOST:-192.168.1.100}"
PHP_PORT="${PHP_PORT:-3001}"
LOG_FILE="${LOG_FILE:-/var/log/lora_tcp_forwarder.log}"
LAST_FRAME_DIR="${LAST_FRAME_DIR:-/tmp/lora_tcp_fwd}"

mkdir -p "$LAST_FRAME_DIR"

# ---------------------------------------------------------------------------
# Logging helper
# ---------------------------------------------------------------------------
log() {
    _level="$1"; shift
    printf '%s [%s] lora-tcp-fwd: %s\n' \
        "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" "$_level" "$*" \
        >> "$LOG_FILE"
}

# ---------------------------------------------------------------------------
# Read raw datagram from stdin
# ---------------------------------------------------------------------------
TMPFILE=$(mktemp /tmp/lora_pkt_XXXXXX.bin)
cat > "$TMPFILE"

PKT_SIZE=$(wc -c < "$TMPFILE")

if [ "$PKT_SIZE" -lt 4 ]; then
    log WARN "Datagram too short (${PKT_SIZE} B) — discarding"
    rm -f "$TMPFILE"
    exit 0
fi

# ---------------------------------------------------------------------------
# Convert raw bytes to uppercase hex string
# od -A n -t x1: hex bytes, no address prefix
# tr -d ' \n':   remove spaces and newlines → continuous hex string
# tr a-f A-F:    uppercase
# ---------------------------------------------------------------------------
HEX=$(od -A n -t x1 "$TMPFILE" | tr -d ' \n' | tr 'a-f' 'A-F')

# ---------------------------------------------------------------------------
# Parse Semtech UDP packet header (4 bytes):
#   Byte 0    : protocol version (0x02)
#   Bytes 1-2 : random token
#   Byte 3    : packet type
#     0x00 = PUSH_DATA  → gateway sending uplink LoRaWAN frames
#     0x01 = PUSH_ACK
#     0x02 = PULL_DATA  → gateway keepalive (no frame payload)
#     0x03 = PULL_RESP
#     0x04 = PULL_ACK
#     0x05 = TX_ACK
#
# In the hex string each byte = 2 chars.  Byte 3 starts at char index 6.
# ---------------------------------------------------------------------------
PKT_TYPE="${HEX:6:2}"
TOKEN="${HEX:2:4}"

log INFO "Semtech pkt type=0x${PKT_TYPE} token=${TOKEN} size=${PKT_SIZE}B"

# Only forward PUSH_DATA (type 0x00) — these carry rxpk LoRaWAN frames
if [ "$PKT_TYPE" != "00" ]; then
    log INFO "Type 0x${PKT_TYPE} — not a PUSH_DATA, skipping forward"
    rm -f "$TMPFILE"
    exit 0
fi

# ---------------------------------------------------------------------------
# PUSH_DATA layout (bytes, 0-indexed):
#   0      : protocol version
#   1-2    : token
#   3      : packet type (0x00)
#   4-11   : gateway EUI (8 bytes)
#   12+    : JSON payload  {"rxpk":[...]}
# ---------------------------------------------------------------------------

# Extract gateway EUI (bytes 4-11 → hex chars 8-23)
GW_EUI="${HEX:8:16}"

# Extract JSON payload: skip first 12 bytes of the binary file
# tail -c +N  outputs from byte N onwards (1-indexed → skip 12 means +13)
JSON_PAYLOAD=$(tail -c +13 "$TMPFILE" 2>/dev/null)

TIMESTAMP=$(date -u '+%Y-%m-%dT%H:%M:%SZ')

# ---------------------------------------------------------------------------
# Build the forwarding JSON object
# Use printf with %s for JSON_PAYLOAD to avoid shell interpretation
# ---------------------------------------------------------------------------
LAST_FRAME_FILE="${LAST_FRAME_DIR}/last_frame.json"
LAST_FRAME_TMP="${LAST_FRAME_FILE}.tmp"

{
    printf '{"received_at":"%s",' "$TIMESTAMP"
    printf '"gateway_eui":"%s",' "$GW_EUI"
    printf '"size":%d,' "$PKT_SIZE"
    printf '"raw_hex":"%s",' "$HEX"
    printf '"lora_data":%s' "${JSON_PAYLOAD:-{}}"
    printf '}\n'
} > "$LAST_FRAME_TMP"

# Atomic replace so readers always see a complete JSON file
mv "$LAST_FRAME_TMP" "$LAST_FRAME_FILE"

log INFO "Last frame saved to ${LAST_FRAME_FILE} (gw=${GW_EUI})"

# ---------------------------------------------------------------------------
# Forward to PHP server via raw TCP on PHP_PORT
# nc -w 3 : TCP connect with 3-second timeout
# The PHP server reads the newline-terminated JSON from the TCP stream
# ---------------------------------------------------------------------------
if nc -w 3 "$PHP_HOST" "$PHP_PORT" < "$LAST_FRAME_FILE" 2>/dev/null; then
    log INFO "Frame forwarded to ${PHP_HOST}:${PHP_PORT} OK"
else
    log ERROR "Failed to forward frame to ${PHP_HOST}:${PHP_PORT}"
fi

rm -f "$TMPFILE"
exit 0
