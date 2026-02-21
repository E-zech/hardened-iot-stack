#!/bin/bash
# ==============================================================================
# Project: The Hardened IoT Stack
# Author:  [ez]
# License: MIT (Copyright (c) 2026)
# Description: Automated, security-first deployment for Home Assistant IoT stack.
# ==============================================================================


# --- Colors for output ---
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}🚀 Starting Ultimate Secure IoT Home Server Setup...${NC}"

# 1. Create Directory Structure
echo -e "${YELLOW}📂 Creating directory structure...${NC}"
DIRS=(
    "homeassistant/config"
    "zigbee2mqtt/data"
    "zigbee2mqtt/mosquitto_config"
    "zigbee2mqtt/mosquitto_data"
    "frigate/config"
    "frigate/storage/media"
    "tailscale/state"
)

for dir in "${DIRS[@]}"; do
    if [ ! -d "$dir" ]; then
        mkdir -p "$dir"
        echo -e "  ✅ Created $dir"
    else
        echo -e "  ℹ️  $dir already exists"
    fi
done

# Fix Ownership for UID 1000 (Critical for Home Assistant)
echo -e "${YELLOW}🔑 Adjusting permissions for UID 1000...${NC}"
sudo chown -R 1000:1000 homeassistant/ zigbee2mqtt/ frigate/ tailscale/
echo -e "  ✅ Permissions set."

# 2. Auto-detect Hardware for .env
echo -e "${YELLOW}🔍 Detecting hardware for .env...${NC}"
DETECTED_TZ=$(readlink /etc/localtime | sed 's/.*zoneinfo\///')
DETECTED_ZIGBEE=$(ls /dev/ttyUSB* /dev/ttyACM* 2>/dev/null | head -n 1)
DETECTED_RENDER=$(ls /dev/dri/renderD* 2>/dev/null | head -n 1)
DETECTED_HOSTNAME=$(hostname)-server

if [ ! -f .env ]; then
    cat <<EOF > .env
# --- System Settings ---
TIMEZONE=${DETECTED_TZ:-Asia/Jerusalem}
RENDER_DEVICE=${DETECTED_RENDER:-/dev/dri/renderD128}
ZIGBEE_DEVICE=${DETECTED_ZIGBEE:-/dev/ttyACM0}

# --- Secrets (EDIT THESE!) ---
TS_AUTHKEY=INSERT_YOUR_TAILSCALE_KEY
FRIGATE_PASSWORD=INSERT_CHOSEN_RTSP_PASSWORD
TS_HOSTNAME=${DETECTED_HOSTNAME}
EOF
    echo -e "${GREEN}  ✅ Created .env template.${NC}"
else
    echo -e "  ℹ️  .env already exists."
fi

# 3. Create Secure Mosquitto Config
echo -e "${YELLOW}🔐 Setting up Mosquitto security...${NC}"
cat <<EOF > zigbee2mqtt/mosquitto_config/mosquitto.conf
persistence true
persistence_location /mosquitto/data/
log_dest stdout
listener 1883
allow_anonymous false
password_file /mosquitto/config/password.txt
EOF

if [ ! -f zigbee2mqtt/mosquitto_config/password.txt ]; then
    touch zigbee2mqtt/mosquitto_config/password.txt
    chmod 600 zigbee2mqtt/mosquitto_config/password.txt
    echo "  ✅ Created secure password.txt (empty)"
fi

# 4. Create docker-compose.yml
echo -e "${YELLOW}🐳 Creating docker-compose.yml...${NC}"
cat <<EOF > docker-compose.yml
services:
  mosquitto:
    image: eclipse-mosquitto:latest
    container_name: mosquitto
    user: "1000:1000"
    restart: unless-stopped
    networks:
      - home_network
    ports:
      - "127.0.0.1:1883:1883"
    volumes:
      - ./zigbee2mqtt/mosquitto_config:/mosquitto/config
      - ./zigbee2mqtt/mosquitto_data:/mosquitto/data

  homeassistant:
    image: ghcr.io/home-assistant/home-assistant:stable
    container_name: homeassistant
    user: "1000:1000"
    privileged: false
    restart: unless-stopped
    network_mode: host
    cap_add:
      - NET_ADMIN
      - NET_RAW
    volumes:
      - ./homeassistant/config:/config
      - /etc/localtime:/etc/localtime:ro
    depends_on:
      - mosquitto

  zigbee2mqtt:
    image: koenkk/zigbee2mqtt:latest
    container_name: zigbee2mqtt
    user: "1000:1000"
    group_add:
      - 20
    restart: unless-stopped
    depends_on:
      - mosquitto
    networks:
      - home_network
    volumes:
      - ./zigbee2mqtt/data:/app/data
      - /run/udev:/run/udev:ro
    ports:
      - "127.0.0.1:8081:8080"
    environment:
      - TZ=\${TIMEZONE}
    devices:
      - \${ZIGBEE_DEVICE}:\${ZIGBEE_DEVICE}

  tailscale:
    image: tailscale/tailscale:latest
    container_name: tailscale
    hostname: \${TS_HOSTNAME}
    network_mode: host
    env_file:
      - .env
    environment:
      - TS_AUTHKEY=\${TS_AUTHKEY}
      - TS_STATE_DIR=/var/lib/tailscale
    volumes:
      - ./tailscale/state:/var/lib/tailscale
      - /dev/net/tun:/dev/net/tun
    cap_add:
      - NET_ADMIN
      - SYS_MODULE
    restart: unless-stopped

  frigate:
    image: ghcr.io/blakeblackshear/frigate:stable
    container_name: frigate
    privileged: false
    cap_add:
      - SYS_ADMIN 
    security_opt:
      - apparmor:unconfined
    restart: unless-stopped
    shm_size: "128mb"
    networks:
      - home_network
    ports:
      - "127.0.0.1:5000:5000"
      - "127.0.0.1:8554:8554"
    devices:
      - \${RENDER_DEVICE}:\${RENDER_DEVICE}
    volumes:
      - /etc/localtime:/etc/localtime:ro
      - ./frigate/config:/config
      - ./frigate/storage/media:/media/frigate
    environment:
      FRIGATE_RTSP_PASSWORD: \${FRIGATE_PASSWORD}

networks:
  home_network:
    driver: bridge
EOF

# 5. Create .gitignore (To keep your secrets safe)
echo -e "${YELLOW}🛡️ Creating .gitignore...${NC}"
cat <<EOF > .gitignore
.env
*.log
**/mosquitto_data/
**/mosquitto_config/password.txt
**/tailscale/state/
EOF
echo -e "  ✅ .gitignore created."

echo -e "${GREEN}✨ Setup script finished!${NC}"