<?php
/**
 * lorareceive.php
 * Receives LoRa frames forwarded by the mPower custom app.
 * Expects a JSON POST body.
 */

header('Content-Type: application/json');

$raw = file_get_contents('php://input');
$data = json_decode($raw, true);

if (!$data) {
    http_response_code(400);
    echo json_encode(["status" => "error", "message" => "Invalid JSON"]);
    exit;
}

$log_dir = __DIR__ . '/lora_logs';
if (!is_dir($log_dir)) {
    mkdir($log_dir, 0755, true);
}

$log_file = $log_dir . '/frames_' . date('Y-m-d') . '.log';
$log_entry = json_encode([
    "received_at"  => date('Y-m-d H:i:s'),
    "gateway_eui"  => $data['gateway_eui'] ?? null,
    "source_ip"    => $data['source_ip'] ?? null,
    "packet_type"  => $data['packet_type'] ?? null,
    "raw_hex"      => $data['raw_hex'] ?? null,
    "frames"       => $data['frames'] ?? [],
], JSON_PRETTY_PRINT) . "\n---\n";

file_put_contents($log_file, $log_entry, FILE_APPEND | LOCK_EX);

foreach ($data['frames'] ?? [] as $frame) {
    $frame_log = sprintf(
        "[%s] GW: %s | Freq: %s | DR: %s | RSSI: %s | SNR: %s | Size: %s | Payload(hex): %s\n",
        date('Y-m-d H:i:s'),
        $data['gateway_eui'] ?? 'N/A',
        $frame['freq'] ?? 'N/A',
        $frame['datr'] ?? 'N/A',
        $frame['rssi'] ?? 'N/A',
        $frame['lsnr'] ?? 'N/A',
        $frame['size'] ?? 'N/A',
        $frame['data_hex'] ?? 'N/A'
    );
    file_put_contents($log_dir . '/frames_decoded_' . date('Y-m-d') . '.log', $frame_log, FILE_APPEND | LOCK_EX);
}

http_response_code(200);
echo json_encode(["status" => "ok", "frames_received" => count($data['frames'] ?? [])]);
?>
