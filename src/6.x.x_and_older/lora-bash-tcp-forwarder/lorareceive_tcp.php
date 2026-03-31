<?php
/**
 * lorareceive_tcp.php
 *
 * PHP TCP server that receives LoRaWAN frames forwarded by the
 * lora-bash-tcp-forwarder mPower 6.x.x custom app.
 *
 * Transport: raw TCP socket on port 3001 (not HTTP).
 * Each connection sends one newline-terminated JSON object.
 *
 * Usage:
 *   php lorareceive_tcp.php
 *
 * The server loops indefinitely, accepting one connection at a time.
 * Run it as a background process / service on your PHP server.
 */

define('LISTEN_HOST', '0.0.0.0');
define('LISTEN_PORT', 3001);
define('LOG_DIR',     __DIR__ . '/lora_logs');
define('READ_TIMEOUT_SEC', 10);

// ---------------------------------------------------------------------------
// Create TCP server socket
// ---------------------------------------------------------------------------
$server = socket_create(AF_INET, SOCK_STREAM, SOL_TCP);
if ($server === false) {
    die("socket_create failed: " . socket_strerror(socket_last_error()) . "\n");
}

socket_set_option($server, SOL_SOCKET, SO_REUSEADDR, 1);

if (!socket_bind($server, LISTEN_HOST, LISTEN_PORT)) {
    die("socket_bind failed: " . socket_strerror(socket_last_error($server)) . "\n");
}

if (!socket_listen($server, 5)) {
    die("socket_listen failed: " . socket_strerror(socket_last_error($server)) . "\n");
}

if (!is_dir(LOG_DIR)) {
    mkdir(LOG_DIR, 0755, true);
}

log_msg("INFO", "TCP server listening on " . LISTEN_HOST . ":" . LISTEN_PORT);

// ---------------------------------------------------------------------------
// Main accept loop
// ---------------------------------------------------------------------------
while (true) {
    $client = @socket_accept($server);
    if ($client === false) {
        log_msg("WARN", "socket_accept error: " . socket_strerror(socket_last_error($server)));
        sleep(1);
        continue;
    }

    socket_getpeername($client, $client_ip, $client_port);
    log_msg("INFO", "Connection from {$client_ip}:{$client_port}");

    // Read data with timeout
    socket_set_option($client, SOL_SOCKET, SO_RCVTIMEO,
        ['sec' => READ_TIMEOUT_SEC, 'usec' => 0]);

    $raw = '';
    while (true) {
        $chunk = @socket_read($client, 4096, PHP_NORMAL_READ);
        if ($chunk === false || $chunk === '') {
            break;
        }
        $raw .= $chunk;
        // Stop after reading a newline-terminated JSON line
        if (strpos($raw, "\n") !== false) {
            break;
        }
    }

    socket_close($client);

    $raw = trim($raw);
    if ($raw === '') {
        log_msg("WARN", "Empty payload from {$client_ip}:{$client_port}");
        continue;
    }

    $data = json_decode($raw, true);
    if (!$data) {
        log_msg("WARN", "Invalid JSON from {$client_ip}:{$client_port}: " . substr($raw, 0, 120));
        continue;
    }

    handle_frame($data, $client_ip);
}

socket_close($server);

// ---------------------------------------------------------------------------
// Handle one received frame
// ---------------------------------------------------------------------------
function handle_frame(array $data, string $source_ip): void
{
    $date_str  = date('Y-m-d');
    $timestamp = date('Y-m-d H:i:s');

    // Full JSON log
    $full_log  = LOG_DIR . "/frames_{$date_str}.log";
    $log_entry = json_encode([
        'received_at' => $timestamp,
        'source_ip'   => $source_ip,
        'gateway_eui' => $data['gateway_eui'] ?? null,
        'raw_hex'     => $data['raw_hex']     ?? null,
        'lora_data'   => $data['lora_data']   ?? null,
    ], JSON_PRETTY_PRINT) . "\n---\n";
    file_put_contents($full_log, $log_entry, FILE_APPEND | LOCK_EX);

    // Decoded frames log (one line per rxpk frame)
    $decoded_log = LOG_DIR . "/frames_decoded_{$date_str}.log";
    $rxpk_list   = $data['lora_data']['rxpk'] ?? [];
    foreach ($rxpk_list as $rxpk) {
        // Decode base64 payload to hex if present
        $data_hex = 'N/A';
        if (!empty($rxpk['data'])) {
            $decoded  = base64_decode($rxpk['data'], true);
            $data_hex = ($decoded !== false) ? strtoupper(bin2hex($decoded)) : 'DECODE_ERR';
        }
        $line = sprintf(
            "[%s] GW: %s | Freq: %s | DR: %s | RSSI: %s | SNR: %s | Size: %s | Payload(hex): %s\n",
            $timestamp,
            $data['gateway_eui']   ?? 'N/A',
            $rxpk['freq']          ?? 'N/A',
            $rxpk['datr']          ?? 'N/A',
            $rxpk['rssi']          ?? 'N/A',
            $rxpk['lsnr']          ?? 'N/A',
            $rxpk['size']          ?? 'N/A',
            $data_hex
        );
        file_put_contents($decoded_log, $line, FILE_APPEND | LOCK_EX);
    }

    $frame_count = count($rxpk_list);
    log_msg("INFO", "Stored frame from GW=" . ($data['gateway_eui'] ?? 'N/A') .
            " frames={$frame_count}");
}

// ---------------------------------------------------------------------------
// Console/log helper
// ---------------------------------------------------------------------------
function log_msg(string $level, string $msg): void
{
    $line = sprintf("[%s] [%s] %s\n", date('Y-m-d H:i:s'), $level, $msg);
    echo $line;
    $log_file = LOG_DIR . '/server_' . date('Y-m-d') . '.log';
    file_put_contents($log_file, $line, FILE_APPEND | LOCK_EX);
}
