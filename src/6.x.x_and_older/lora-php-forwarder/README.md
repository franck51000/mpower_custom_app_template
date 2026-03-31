# lora-php-forwarder — mPower Firmware 6.x.x

## Description / Description

**FR:** Application custom mPower pour firmware **6.x.x et antérieur**.  
Écoute les trames LoRa sur **UDP port 1700** (protocole Semtech packet forwarder) et les transfère vers un serveur PHP via **HTTP POST JSON**.

**EN:** Custom mPower application for firmware **6.x.x and older**.  
Listens for LoRa frames on **UDP port 1700** (Semtech packet forwarder protocol) and forwards them to a PHP server via **HTTP POST JSON**.

---

## Différences avec la version 7.x.x / Differences from 7.x.x

| Élément | Firmware 7.x.x | Firmware 6.x.x |
|---|---|---|
| Installation Python | `pip3 install requests` | `opkg install` via `.ipk` |
| Manifeste paquets | Non requis | `provisioning/p_manifest.json` |
| Script `Install` | pip3 | `jsparser` + `opkg` |
| Arguments `Install` | `install\|remove\|postinstall\|postremove` | `install\|remove\|postinstall\|postremove` |

---

## Prérequis / Prerequisites

- Python3 disponible sur le firmware mPower 6.x.x
- Fichier `.ipk` de `python3-requests` compatible OpenWRT/ARM (voir ci-dessous)
- Accès réseau vers `http://192.168.28.55/lorareceive.php`

---

## Structure des fichiers / File Structure

```
lora-php-forwarder/
├── manifest.json                    # App metadata
├── Start                            # Start/stop bash script
├── Install                          # opkg dependency installer
├── forwarder.py                     # Main Python forwarder script
├── config/
│   └── forwarder.cfg.json           # Configuration (URL, port, log)
├── provisioning/
│   └── p_manifest.json              # List of .ipk packages to install
│   └── python3-requests_*.ipk       # (place .ipk file here before packaging)
└── lorareceive.php                  # Example PHP server-side receiver
```

---

## Configuration

Éditez `config/forwarder.cfg.json` :

```json
{
  "php_server_url": "http://192.168.28.55/lorareceive.php",
  "listen_host": "0.0.0.0",
  "listen_port": 1700,
  "log_file": "/var/log/lora_forwarder.log"
}
```

| Paramètre | Description |
|---|---|
| `php_server_url` | URL complète du script PHP receveur |
| `listen_host` | Interface d'écoute UDP (0.0.0.0 = toutes) |
| `listen_port` | Port UDP (1700 = standard Semtech) |
| `log_file` | Chemin du fichier de log |

---

## Obtenir le fichier python3-requests .ipk pour OpenWRT/ARM

Le fichier `.ipk` doit être compatible avec l'architecture ARM de la gateway (ex: `arm926ejste`).

**Option 1 — Télécharger depuis le dépôt OpenWRT :**
```bash
# Remplacer l'URL par la version compatible avec votre firmware
wget https://downloads.openwrt.org/releases/21.02.x/packages/arm_arm926ej-s/packages/python3-requests_2.27.1-1_arm_arm926ej-s.ipk
```

**Option 2 — Extraire depuis un Conduit existant :**
```bash
# Sur un Conduit avec python3-requests déjà installé
opkg info python3-requests
# Puis récupérer le .ipk depuis /var/cache/opkg/
```

Renommez le fichier comme indiqué dans `provisioning/p_manifest.json` et placez-le dans le dossier `provisioning/` avant de créer le package.

---

## Packaging / Creating the .tar.gz

```bash
cd src/6.x.x_and_older/lora-php-forwarder/

# Placer le fichier .ipk dans provisioning/ avant de packager
# cp /chemin/vers/python3-requests_*.ipk provisioning/

tar -czf lora-php-forwarder_1.0.0.tar.gz \
    manifest.json \
    Start \
    Install \
    forwarder.py \
    config/ \
    provisioning/
```

---

## Déploiement sur mPower 6.x.x / Deployment

1. Créez le fichier `.tar.gz` comme indiqué ci-dessus
2. Connectez-vous à l'interface web mPower
3. Naviguez vers **Apps > Custom Apps**
4. Uploadez le fichier `.tar.gz`
5. L'app-manager exécutera automatiquement `Install install` puis `Start start`

**Ou via ligne de commande :**
```bash
scp lora-php-forwarder_1.0.0.tar.gz admin@<gateway-ip>:/tmp/
ssh admin@<gateway-ip>
app-manager --install /tmp/lora-php-forwarder_1.0.0.tar.gz
```

---

## Format JSON envoyé au serveur PHP / JSON Payload Sent to PHP

```json
{
  "received_at": "2024-01-15T10:30:45.123456Z",
  "source_ip": "192.168.1.100",
  "source_port": 51234,
  "raw_hex": "0212AB00AABBCCDDEEFF0011...",
  "protocol_version": 2,
  "packet_type": "PUSH_DATA",
  "token": "12ab",
  "gateway_eui": "AABBCCDDEEFF0011",
  "frames": [
    {
      "tmst": 123456789,
      "freq": 868.1,
      "datr": "SF7BW125",
      "rssi": -85,
      "lsnr": 9.5,
      "size": 23,
      "data_b64": "QAQDAgGAAQABVGVzdA==",
      "data_hex": "4004030201800100015465737400",
      "modu": "LORA",
      "chan": 0,
      "rfch": 0,
      "stat": 1
    }
  ]
}
```

---

## Serveur PHP / PHP Server Side

Déployez `lorareceive.php` sur votre serveur web (ex: Apache/Nginx) à l'adresse `http://192.168.28.55/lorareceive.php`.

Le script :
- Reçoit le JSON POST
- Crée le dossier `lora_logs/` automatiquement
- Enregistre chaque trame dans `lora_logs/frames_YYYY-MM-DD.log` (JSON complet)
- Enregistre les trames décodées dans `lora_logs/frames_decoded_YYYY-MM-DD.log`
- Répond `{"status":"ok","frames_received":N}` en HTTP 200

---

## Commandes de debug / Debug Commands

**Vérifier que l'app tourne :**
```bash
cat /var/run/lora-php-forwarder.pid
ps aux | grep forwarder
```

**Consulter les logs :**
```bash
tail -f /var/log/lora_forwarder.log
```

**Tester manuellement depuis la gateway :**
```bash
# Envoyer un paquet UDP de test
APP_DIR=/opt/lora-php-forwarder CONFIG_DIR=/opt/lora-php-forwarder/config ./Start start

# Vérifier la réception sur le serveur PHP
curl -X POST http://192.168.28.55/lorareceive.php \
  -H "Content-Type: application/json" \
  -d '{"test":true,"gateway_eui":"AABB","frames":[]}'
```

**Tester l'écoute UDP :**
```bash
# Sur un PC du même réseau
echo -n "test" | nc -u <gateway-ip> 1700
```

---

## Notes importantes / Important Notes

- Le fichier `.ipk` de `python3-requests` **n'est pas inclus** dans ce dépôt et doit être ajouté manuellement dans `provisioning/` avant de packager.
- Le protocole Semtech supporte les types de paquets : `PUSH_DATA`, `PULL_DATA`, `PULL_RESP`, `TX_ACK`. Seuls les `PUSH_DATA` (trames LoRa montantes) sont transmis au serveur PHP.
- L'application répond automatiquement aux `PUSH_DATA` avec `PUSH_ACK` et aux `PULL_DATA` avec `PULL_ACK`.
