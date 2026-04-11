# lora-php-forwarder

## Description (Français)

Application custom mPower (firmware 7.x+) qui écoute les trames LoRa sur le port UDP 1700 (protocole Semtech packet forwarder standard), les décode et les transmet en HTTP POST JSON vers un serveur PHP.

## Description (English)

mPower custom application (firmware 7.x+) that listens for LoRa frames on UDP port 1700 (Semtech packet forwarder standard protocol), decodes them, and forwards them via HTTP POST JSON to a PHP server.

---

## Prérequis / Prerequisites

- mPower firmware **7.x.x or newer**
- Python 3.10+
- pip3
- Python package: `requests`

---

## Structure des fichiers / File Structure

```
lora-php-forwarder/
├── manifest.json            # App metadata
├── Start                    # Start/stop bash script (mPower app-manager)
├── Install                  # Dependency installation script
├── forwarder.py             # Main Python script
├── lorareceive.php          # Example PHP receiver script (deploy on your server)
├── config/
│   └── forwarder.cfg.json   # Configuration file
└── README.md                # This file
```

---

## Configuration

Edit `config/forwarder.cfg.json` to match your setup:

```json
{
  "php_server_url": "http://192.168.28.55/lorareceive.php",
  "listen_host": "0.0.0.0",
  "listen_port": 1700,
  "log_file": "/var/log/lora_forwarder.log"
}
```

| Parameter        | Description                                      | Default                                     |
|------------------|--------------------------------------------------|---------------------------------------------|
| `php_server_url` | Full URL of the PHP receiver endpoint            | `http://192.168.28.55/lorareceive.php`      |
| `listen_host`    | UDP bind address (use `0.0.0.0` for all interfaces) | `0.0.0.0`                               |
| `listen_port`    | UDP port to listen on (Semtech standard: 1700)   | `1700`                                      |
| `log_file`       | Path to the application log file                 | `/var/log/lora_forwarder.log`               |

---

## Format JSON envoyé au serveur PHP / JSON Payload sent to PHP server

```json
{
  "received_at": "2024-01-15T12:34:56.789Z",
  "source_ip": "192.168.1.10",
  "source_port": 52345,
  "raw_hex": "0212AB00AABBCCDDEEFF0011...",
  "protocol_version": 2,
  "packet_type": "PUSH_DATA",
  "token": "12ab",
  "gateway_eui": "AABBCCDDEEFF0011",
  "frames": [
    {
      "tmst": 1234567890,
      "freq": 868.1,
      "datr": "SF7BW125",
      "rssi": -85,
      "lsnr": 9.2,
      "size": 23,
      "data_b64": "QBkYASaAAAABMdM+Hs8=",
      "data_hex": "401918012680000001...",
      "modu": "LORA",
      "chan": 0,
      "rfch": 0,
      "stat": 1
    }
  ]
}
```

### Champs / Fields

| Field              | Description                                                 |
|--------------------|-------------------------------------------------------------|
| `received_at`      | ISO8601 timestamp when the packet was received              |
| `source_ip`        | IP address of the packet sender (gateway)                   |
| `source_port`      | UDP source port                                             |
| `raw_hex`          | Full raw UDP packet as hexadecimal string                   |
| `protocol_version` | Semtech protocol version                                    |
| `packet_type`      | Semtech packet type (`PUSH_DATA`, `PULL_DATA`, etc.)        |
| `token`            | 2-byte Semtech token (hex)                                  |
| `gateway_eui`      | Gateway EUI (8 bytes from Semtech header, uppercase hex)    |
| `frames`           | Array of decoded LoRa frames                                |
| `frames[].tmst`    | Internal gateway timestamp                                  |
| `frames[].freq`    | Radio frequency (MHz)                                       |
| `frames[].datr`    | LoRa data rate / spreading factor (e.g. `SF7BW125`)        |
| `frames[].rssi`    | RSSI in dBm                                                 |
| `frames[].lsnr`    | LoRa SNR in dB                                              |
| `frames[].size`    | Payload size in bytes                                       |
| `frames[].data_b64`| Raw LoRa payload in Base64                                  |
| `frames[].data_hex`| Raw LoRa payload as uppercase hexadecimal string            |
| `frames[].modu`    | Modulation type (`LORA` or `FSK`)                           |
| `frames[].chan`    | IF channel used                                             |
| `frames[].rfch`    | Concentrator RF chain                                       |
| `frames[].stat`    | CRC status                                                  |

---

## Packaging / Création du paquet

```bash
cd src/7.x.x_and_newer/lora-php-forwarder
tar -czf lora-php-forwarder_1.0.0.tar.gz \
    manifest.json \
    Start \
    Install \
    forwarder.py \
    config/
```

---

## Déploiement sur mPower / Deployment on mPower

### Via l'interface web
1. Connectez-vous à l'interface web mPower
2. Naviguez vers **Apps** → **Install**
3. Téléversez le fichier `lora-php-forwarder_1.0.0.tar.gz`
4. Cliquez sur **Install**
5. L'application démarrera automatiquement

### Via app-manager (ligne de commande)
```bash
app-manager install lora-php-forwarder_1.0.0.tar.gz
app-manager start lora-php-forwarder
```

### Test manuel / Manual test
```bash
sudo APP_DIR=$(pwd) CONFIG_DIR=$(pwd)/config ./Start start
```

---

## Déploiement du fichier PHP / Deploying the PHP file

Copiez `lorareceive.php` sur votre serveur web dans le répertoire web racine ou un sous-dossier accessible.

Copy `lorareceive.php` to your web server's document root or an accessible subfolder.

```bash
cp lorareceive.php /var/www/html/lorareceive.php
```

Le script PHP créera automatiquement un dossier `lora_logs/` dans son répertoire pour stocker les logs quotidiens.

The PHP script will automatically create a `lora_logs/` folder in its directory for daily logs.

---

## Commandes de debug / Debug Commands

### Vérifier les logs de l'application / Check application logs
```bash
tail -f /var/log/lora_forwarder.log
```

### Tester l'envoi UDP manuellement / Test UDP sending manually
```bash
# Envoyer un faux paquet PUSH_DATA (remplacer par un vrai paquet Semtech)
echo -n "test" | nc -u 127.0.0.1 1700
```

### Vérifier que l'application tourne / Check if the application is running
```bash
ps aux | grep forwarder.py
cat /var/run/lora-php-forwarder.pid
```

### Tester le serveur PHP / Test the PHP server
```bash
curl -X POST http://192.168.28.55/lorareceive.php \
     -H "Content-Type: application/json" \
     -d '{"gateway_eui":"AABBCCDDEEFF0011","packet_type":"PUSH_DATA","frames":[]}'
```

---

## Licence / License

MIT
