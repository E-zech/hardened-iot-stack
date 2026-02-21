# 🛡️ The Hardened IoT Stack
### Secure, Automated Home Automation via Home Assistant & Docker

This is a production-ready, security-first deployment for a complete IoT infrastructure. Unlike standard setups, this stack is hardened by default, ensuring your home data is never exposed to your local network or the internet—only accessible via your private Tailscale mesh.


-----

## ✨ Key Services
* **Home Assistant:** The brain of your home.
* **Zigbee2MQTT:** Universal Zigbee support without vendor lock-in.
* **Frigate (NVR):** AI-powered local video surveillance.
* **Mosquitto:** High-performance, authenticated MQTT broker.
* **Tailscale:** Secure Zero-Trust remote access.

## 🛡️ Security Features (Why this is different)
* **Zero-Exposure Ports:** Sensitive services (MQTT, Frigate UI, Zigbee2MQTT) are bound to `127.0.0.1`. They are invisible to other devices on your WiFi.
* **Tailscale Sidecar Access:** Remote access is granted exclusively through your encrypted Tailscale tunnel.
* **Rootless Execution:** Services run under `UID 1000` with optimized `cap_add` permissions, avoiding the risks of `privileged: true`.
* **Mandatory MQTT Auth:** Mosquitto is pre-configured to reject anonymous connections.

* No Domain or Port Forwarding Required, Tailscale handles all encryption and routing. Access your dashboard directly via its Tailscale IP, even if you don't own a domain :) 
-----

## 🛠 Prerequisites

### Hardware
* **Host:** PC or Raspberry Pi 4/5 (64-bit Ubuntu recommended). 4GB RAM minimum.
* **Zigbee Dongle:** (e.g., Sonoff ZBDongle-E/P).

### Software
* Docker & Docker Compose installed.
* A Tailscale Account. (https://tailscale.com/)

-----

## 🚀 Installation Steps

### 1. Create Project Directory
"mkdir ~/iot && cd ~/iot"

### 2. Prepare the Setup Script
Download `setup.sh` to the `iot` directory and grant execution permissions with "chmod +x setup.sh"

### 3. Run the Script
"./setup.sh"

### 4. Configure Secrets
Edit the generated `.env` file:
* **TS_AUTHKEY:** Your Tailscale Auth Key.
* **FRIGATE_PASSWORD:** Secure password for camera streams.

### 5. Create MQTT Credentials (Required)
"docker compose run --rm mosquitto mosquitto_passwd -b /mosquitto/config/password.txt <USER> <PASS>"

### 6. Deploy
"docker compose up -d"

(Note: It may take a few minutes for Home Assistant to fully initialize on its first run).
-----

## 🌐 Accessing Dashboards
Access is available **only** via your Tailscale IP:

* **Home Assistant:** `http://<tailscale-ip>:8123`
* **Zigbee2MQTT:** `http://<tailscale-ip>:8081`
* **Frigate UI:** `http://<tailscale-ip>:5000`

-----

## 📜 License & Copyright
Copyright (c) 2026 [ez].
This project is licensed under the **MIT License**. You are free to use, modify, and distribute it, provided that the original copyright notice and permission notice are included in all copies.

