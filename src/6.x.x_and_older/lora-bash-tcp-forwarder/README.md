# lora-bash-tcp-forwarder — mPower Firmware 6.x.x

## ⚡ Démarrage rapide / Quick Start

> **Créer le fichier `.tar.gz` prêt à installer sur la gateway mPower :**
> **Create the `.tar.gz` file ready to install on the mPower gateway:**

### Étape 1 — Obtenir le fichier `.ipk` socat

Téléchargez le paquet compatible et placez-le dans `provisioning/` :

```bash
# Dans le dossier lora-bash-tcp-forwarder/
wget https://downloads.openwrt.org/releases/21.02.7/packages/arm_arm926ej-s/base/socat_1.7.3.2-3_arm_arm926ej-s.ipk
mv socat_*.ipk provisioning/socat_1.7.3.2-3_arm926ejste.ipk
```

### Étape 2 — Lancer le script de packaging

```bash
# Dans le dossier lora-bash-tcp-forwarder/
# Le script chmod +x automatiquement tous les scripts avant de packager
./build_package.sh
```

Le script génère : **`lora-bash-tcp-forwarder_1.0.0.tar.gz`**

### Étape 3 — Installer sur la gateway mPower 6.x.x

**Via l'interface web :**
1. Connectez-vous à l'interface web mPower
2. Allez dans **Apps > Custom Apps**
3. Uploadez `lora-bash-tcp-forwarder_1.0.0.tar.gz`

**Via SSH :**
```bash
scp lora-bash-tcp-forwarder_1.0.0.tar.gz admin@<gateway-ip>:/tmp/
ssh admin@<gateway-ip> 'app-manager --install /tmp/lora-bash-tcp-forwarder_1.0.0.tar.gz'
```

---

## Description / Description

**FR:** Application custom mPower pour firmware **6.x.x et antérieur**.
Écrite entièrement en **bash/sh** (aucun Python requis).
Écoute les trames LoRaWAN sur **UDP port 1700** (protocole Semtech packet
forwarder), mémorise la **dernière trame reçue**, et la transmet vers un
**serveur PHP sur le port TCP 3001** via une connexion TCP brute (`nc`).

**EN:** Custom mPower application for firmware **6.x.x and older**.
Written entirely in **bash/sh** (no Python required).
Listens for LoRaWAN frames on **UDP port 1700** (Semtech packet forwarder
protocol), tracks the **last received frame**, and forwards it to a
**PHP server on TCP port 3001** over a raw TCP connection (`nc`).

---

## Différences par rapport à lora-php-forwarder / Differences from lora-php-forwarder

| Élément                    | lora-php-forwarder       | lora-bash-tcp-forwarder  |
|----------------------------|--------------------------|--------------------------|
| Langage                    | Python 3                 | **bash / sh**            |
| Transport vers serveur PHP | HTTP POST (port 80/443)  | **TCP brut port 3001**   |
| Dépendance                 | python3-requests (.ipk)  | socat (.ipk)             |
| Fichier config             | JSON                     | bash key=value (.cfg)    |

---

## Architecture / Architecture

```
Gateway mPower 6.x.x
┌──────────────────────────────────────────┐
│  Semtech packet forwarder                │
│  (lora-packet-forwarder daemon)          │
│       │  UDP datagrams                   │
│       ▼  port 1700                       │
│  forwarder.sh  ──── socat ──────────┐   │
│                    UDP4-RECVFROM    │   │
│                    reuseaddr,fork   │   │
│                                     │   │
│  Per datagram: handle_packet.sh ◄───┘   │
│    • Parse Semtech header               │
│    • Extract JSON rxpk payload          │
│    • Save last_frame.json (atomic)      │
│    • nc -w3 PHP_HOST PHP_PORT ──────────┼──► PHP server :3001
└──────────────────────────────────────────┘
```

- **socat** (`UDP4-RECVFROM,fork`): binds UDP port 1700 persistently; for
  each received datagram, forks a new process running `handle_packet.sh`.
- **handle_packet.sh**: reads the raw datagram from stdin, parses the
  Semtech header (packet type check), extracts the LoRaWAN JSON payload,
  saves it atomically as `/tmp/lora_tcp_fwd/last_frame.json`, then opens a
  TCP connection to the PHP server with `nc`.

---

## Prérequis / Prerequisites

- mPower firmware **6.x.x** (mLinux, busybox)
- `socat` available on the device (installed via .ipk, see step 1 above)
- `nc` (netcat/busybox) — included in mLinux by default
- `od`, `dd`, `date`, `logger` — all part of busybox
- A PHP server listening on **TCP port 3001** (see `lorareceive_tcp.php`)

---

## Structure des fichiers / File Structure

```
lora-bash-tcp-forwarder/
├── manifest.json                    # App metadata
├── Start                            # start/stop bash control script
├── Install                          # opkg dependency installer
├── forwarder.sh                     # Main script: socat UDP listener
├── handle_packet.sh                 # Per-datagram handler (called by socat)
├── config/
│   └── forwarder.cfg                # Configuration (host, port, log)
├── provisioning/
│   └── p_manifest.json              # socat .ipk package list
│   └── socat_*.ipk                  # (place .ipk file here before packaging)
├── lorareceive_tcp.php              # Example PHP TCP server receiver
└── build_package.sh                 # Packaging script
```

---

## Configuration

Éditez `config/forwarder.cfg` :

```sh
# UDP port to listen for Semtech packet forwarder datagrams
LISTEN_PORT=1700

# PHP server host (IP or hostname)
PHP_HOST=192.168.1.100

# PHP server TCP port (raw TCP, not HTTP)
PHP_PORT=3001

# Log file path
LOG_FILE=/var/log/lora_tcp_forwarder.log
```

| Paramètre     | Description                                      |
|---------------|--------------------------------------------------|
| `LISTEN_PORT` | Port UDP d'écoute (1700 = standard Semtech)      |
| `PHP_HOST`    | Adresse IP ou hostname du serveur PHP            |
| `PHP_PORT`    | Port TCP du serveur PHP (3001 par défaut)        |
| `LOG_FILE`    | Chemin du fichier de log                         |

---

## Format JSON envoyé au serveur PHP / JSON Payload Sent to PHP

Le JSON est envoyé en clair sur la connexion TCP (une ligne, terminée par `\n`) :

```json
{
  "received_at": "2024-01-15T10:30:45Z",
  "gateway_eui": "AABBCCDDEEFF0011",
  "size": 76,
  "raw_hex": "0212AB00AABBCCDDEEFF0011...",
  "lora_data": {
    "rxpk": [
      {
        "tmst": 123456789,
        "freq": 868.1,
        "datr": "SF7BW125",
        "rssi": -85,
        "lsnr": 9.5,
        "size": 23,
        "data": "QAQDAgGAAQABVGVzdA=="
      }
    ]
  }
}
```

| Champ          | Description                                               |
|----------------|-----------------------------------------------------------|
| `received_at`  | Horodatage UTC ISO-8601                                   |
| `gateway_eui`  | EUI 64 bits de la gateway (extrait du header Semtech)    |
| `size`         | Taille du datagramme UDP en octets                       |
| `raw_hex`      | Datagramme complet en hexadécimal majuscule              |
| `lora_data`    | Payload JSON Semtech (champ `rxpk` avec les trames LoRa) |

---

## Serveur PHP receveur / PHP TCP Server Side

Déployez `lorareceive_tcp.php` sur votre serveur et lancez-le :

```bash
# Écoute sur le port TCP 3001
php lorareceive_tcp.php
```

Le script :
- Crée un serveur TCP sur le port 3001 (`socket_bind` / `socket_listen`)
- Accepte les connexions entrantes en boucle
- Décode le JSON reçu
- Enregistre chaque trame dans `lora_logs/frames_YYYY-MM-DD.log`

---

## Obtenir le fichier socat .ipk pour OpenWRT/ARM

Le fichier `.ipk` doit être compatible avec l'architecture ARM de la gateway.

```bash
# Adaptez la version selon votre firmware mPower (ex: 21.02.7)
wget https://downloads.openwrt.org/releases/21.02.7/packages/arm_arm926ej-s/base/socat_1.7.3.2-3_arm_arm926ej-s.ipk
mv socat_*.ipk provisioning/socat_1.7.3.2-3_arm926ejste.ipk
```

---

## Packaging / Creating the .tar.gz

```bash
cd src/6.x.x_and_older/lora-bash-tcp-forwarder/

# 1. Place the .ipk in provisioning/ before packaging
#    Placer le fichier .ipk dans provisioning/ avant de packager
cp /path/to/socat_*.ipk provisioning/socat_1.7.3.2-3_arm926ejste.ipk

# 2. Rendre les scripts exécutables (chmod +x) — requis après upload depuis Windows
#    ou transfert SFTP qui peut supprimer le bit +x
chmod +x Start Install forwarder.sh handle_packet.sh

# 3. Lancer le script de packaging (il fait aussi le chmod +x automatiquement)
./build_package.sh
# → génère : lora-bash-tcp-forwarder_1.0.0.tar.gz
```

**Ou manuellement :**
```bash
# Assurez-vous d'abord que les scripts sont exécutables !
chmod +x Start Install forwarder.sh handle_packet.sh

tar -czf lora-bash-tcp-forwarder_1.0.0.tar.gz \
    manifest.json \
    Start \
    Install \
    forwarder.sh \
    handle_packet.sh \
    config/ \
    provisioning/
```

---

## Commandes de debug / Debug Commands

**Vérifier que l'app tourne :**
```bash
cat /var/run/lora-bash-tcp-forwarder.pid
ps aux | grep forwarder
```

**Consulter les logs :**
```bash
tail -f /var/log/lora_tcp_forwarder.log
```

**Voir la dernière trame reçue :**
```bash
cat /tmp/lora_tcp_fwd/last_frame.json
```

**Tester manuellement (depuis la gateway) :**
```bash
APP_DIR=$(pwd) CONFIG_DIR=$(pwd)/config ./Start start
```

**Envoyer un paquet UDP de test (depuis un PC du même réseau) :**
```bash
# PUSH_DATA Semtech minimal (version=2, token=1234, type=0x00, gw_eui=8 bytes, payload={})
printf '\x02\x12\x34\x00\xAA\xBB\xCC\xDD\xEE\xFF\x00\x11{}' | nc -u <gateway-ip> 1700
```

**Tester la connexion TCP vers le serveur PHP :**
```bash
echo '{"test":true}' | nc -w 3 <php-server-ip> 3001
```

---

## Notes importantes / Important Notes

- **chmod +x obligatoire** : Après upload des fichiers sur la gateway (via SFTP
  vers `/home` par exemple), les scripts peuvent perdre leurs droits d'exécution.
  **Toujours faire `chmod +x Start Install forwarder.sh handle_packet.sh`** avant
  d'installer l'app, ou utiliser `build_package.sh` qui le fait automatiquement.
  Le script `Install postinstall` et la fonction `CreateAccess` du script `Start`
  appliquent aussi ce `chmod +x` comme filet de sécurité.
- Le fichier `.ipk` de `socat` **n'est pas inclus** dans ce dépôt et doit
  être ajouté manuellement dans `provisioning/` avant de packager.
- Seuls les paquets **PUSH_DATA** (type `0x00`) sont transmis au serveur PHP.
  Les `PULL_DATA` (keepalives) sont ignorés.
- La **dernière trame** reçue est toujours disponible dans
  `/tmp/lora_tcp_fwd/last_frame.json` même si la transmission TCP échoue.
- Aucun ACK Semtech (`PUSH_ACK`) n'est renvoyé par cette app. Le packet
  forwarder peut re-émettre les paquets plusieurs fois ; cela ne provoque
  pas de perte de données mais peut générer des doublons côté PHP.
- Le transport est **TCP brut** (pas HTTP) : le serveur PHP doit écouter
  directement sur le port TCP 3001 avec `socket_listen`.
