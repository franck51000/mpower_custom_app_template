#!/usr/bin/env python3
"""
LoRa Frame Forwarder to PHP Server - mPower 6.x.x version
Listens on UDP port 1700 (Semtech protocol) and forwards decoded frames via HTTP POST.
"""

import socket
import json
import base64
import logging
import argparse
import datetime
import requests

PUSH_DATA = 0x00
PUSH_ACK  = 0x01
PULL_DATA = 0x02
PULL_RESP = 0x03
PULL_ACK  = 0x04
TX_ACK    = 0x05

PACKET_TYPE_NAMES = {
    PUSH_DATA: "PUSH_DATA",
    PUSH_ACK:  "PUSH_ACK",
    PULL_DATA: "PULL_DATA",
    PULL_RESP: "PULL_RESP",
    PULL_ACK:  "PULL_ACK",
    TX_ACK:    "TX_ACK",
}

def load_config(cfg_path):
    with open(cfg_path) as f:
        return json.load(f)

def setup_logging(log_file):
    logging.basicConfig(
        filename=log_file,
        level=logging.INFO,
        format="%(asctime)s [%(levelname)s] %(message)s"
    )
    console = logging.StreamHandler()
    console.setLevel(logging.INFO)
    logging.getLogger().addHandler(console)

def parse_semtech_packet(data):
    if len(data) < 4:
        return None
    version  = data[0]
    token    = data[1:3]
    pkt_type = data[3]
    result = {
        "protocol_version": version,
        "token": token.hex(),
        "packet_type": PACKET_TYPE_NAMES.get(pkt_type, "UNKNOWN(0x{:02x})".format(pkt_type)),
        "packet_type_id": pkt_type,
        "gateway_eui": None,
        "frames": []
    }
    if pkt_type == PUSH_DATA and len(data) >= 12:
        gw_eui = data[4:12]
        result["gateway_eui"] = gw_eui.hex().upper()
        json_payload = data[12:]
        try:
            parsed = json.loads(json_payload.decode("utf-8"))
            for rxpk in parsed.get("rxpk", []):
                frame = {
                    "tmst":     rxpk.get("tmst"),
                    "freq":     rxpk.get("freq"),
                    "datr":     rxpk.get("datr"),
                    "rssi":     rxpk.get("rssi"),
                    "lsnr":     rxpk.get("lsnr"),
                    "size":     rxpk.get("size"),
                    "data_b64": rxpk.get("data"),
                    "data_hex": None,
                    "modu":     rxpk.get("modu"),
                    "chan":     rxpk.get("chan"),
                    "rfch":     rxpk.get("rfch"),
                    "stat":     rxpk.get("stat"),
                }
                if rxpk.get("data"):
                    try:
                        frame["data_hex"] = base64.b64decode(rxpk["data"]).hex().upper()
                    except Exception:
                        pass
                result["frames"].append(frame)
        except Exception as e:
            logging.warning("Failed to parse JSON payload: {}".format(e))
    elif pkt_type == PULL_DATA and len(data) >= 12:
        result["gateway_eui"] = data[4:12].hex().upper()
    return result

def forward_to_php(url, payload):
    try:
        resp = requests.post(url, json=payload, timeout=5)
        logging.info("Forwarded to PHP server | HTTP {}".format(resp.status_code))
        return True
    except requests.exceptions.ConnectionError as e:
        logging.error("Connection error to PHP server: {}".format(e))
    except requests.exceptions.Timeout:
        logging.error("Timeout connecting to PHP server")
    except Exception as e:
        logging.error("Unexpected error sending to PHP server: {}".format(e))
    return False

def send_ack(sock, addr, token, ack_type):
    ack = bytes([2, token[0], token[1], ack_type])
    sock.sendto(ack, addr)

def main():
    parser = argparse.ArgumentParser(description="LoRa to PHP Forwarder (mPower 6.x.x)")
    parser.add_argument("--cfgfile", required=True, help="Path to config JSON file")
    args = parser.parse_args()

    cfg = load_config(args.cfgfile)
    setup_logging(cfg.get("log_file", "/var/log/lora_forwarder.log"))

    host    = cfg.get("listen_host", "0.0.0.0")
    port    = cfg.get("listen_port", 1700)
    php_url = cfg["php_server_url"]

    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    sock.bind((host, port))
    logging.info("LoRa PHP Forwarder (6.x.x) started - Listening on {}:{}".format(host, port))
    logging.info("Forwarding to: {}".format(php_url))

    while True:
        try:
            data, addr = sock.recvfrom(4096)
            logging.info("Packet received from {} | size={} bytes".format(addr, len(data)))
            parsed = parse_semtech_packet(data)
            if not parsed:
                logging.warning("Could not parse packet, skipping.")
                continue
            pkt_type_id = parsed["packet_type_id"]
            token_bytes = bytes.fromhex(parsed["token"])
            if pkt_type_id == PUSH_DATA:
                send_ack(sock, addr, token_bytes, PUSH_ACK)
                logging.info("PUSH_ACK sent to {}".format(addr))
            elif pkt_type_id == PULL_DATA:
                send_ack(sock, addr, token_bytes, PULL_ACK)
                logging.info("PULL_ACK sent to {}".format(addr))
            php_payload = {
                "received_at":      datetime.datetime.utcnow().isoformat() + "Z",
                "source_ip":        addr[0],
                "source_port":      addr[1],
                "raw_hex":          data.hex().upper(),
                "protocol_version": parsed["protocol_version"],
                "packet_type":      parsed["packet_type"],
                "token":            parsed["token"],
                "gateway_eui":      parsed["gateway_eui"],
                "frames":           parsed["frames"]
            }
            if pkt_type_id == PUSH_DATA:
                forward_to_php(php_url, php_payload)
            else:
                logging.info("Packet type {} - not forwarded to PHP".format(parsed["packet_type"]))
        except KeyboardInterrupt:
            logging.info("Forwarder stopped by user.")
            break
        except Exception as e:
            logging.error("Unexpected error in main loop: {}".format(e))

if __name__ == "__main__":
    main()
