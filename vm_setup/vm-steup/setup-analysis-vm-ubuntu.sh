#!/usr/bin/env bash
# Bootstrap a fresh Ubuntu 24.04 VM as the hive analysis machine.
# Run as a normal user with sudo access. Hive project must be at ~/hive.
set -euo pipefail

HIVE_DIR="${HIVE_DIR:-$HOME/hive}"
SECRETS_FILE="/etc/hive/secrets.env"
CACHE_DIR="/var/lib/hive"
CRON_LOG="/var/log/hive/enrichment.log"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
info()  { echo -e "${GREEN}[+]${NC} $*"; }
warn()  { echo -e "${YELLOW}[!]${NC} $*"; }
error() { echo -e "${RED}[✗]${NC} $*" >&2; exit 1; }

[[ $EUID -eq 0 ]] && error "Do not run as root."
[[ -d "$HIVE_DIR" ]] || error "Hive project not found at $HIVE_DIR."
command -v sudo >/dev/null || error "sudo is required"

DISTRO_ID=$(lsb_release -si 2>/dev/null || echo "unknown")
DISTRO_RELEASE=$(lsb_release -sr 2>/dev/null || echo "0")
if [[ "$DISTRO_ID" != "Ubuntu" ]]; then
    warn "This script targets Ubuntu 24.04. Detected: $DISTRO_ID $DISTRO_RELEASE"
    read -rp "Continue anyway? [y/N] " ans
    [[ "${ans,,}" == "y" ]] || exit 1
elif [[ "$DISTRO_RELEASE" != "24.04" ]]; then
    warn "Expected Ubuntu 24.04, detected Ubuntu $DISTRO_RELEASE."
    read -rp "Continue anyway? [y/N] " ans
    [[ "${ans,,}" == "y" ]] || exit 1
fi

info "Updating package lists..."
sudo apt-get update -qq

info "Installing Docker, WireGuard, Python 3, utilities..."
sudo apt-get install -y \
    ca-certificates curl gnupg lsb-release \
    wireguard \
    python3 python3-pip python3-venv \
    git jq

if ! command -v docker >/dev/null 2>&1; then
    info "Adding Docker apt repository..."
    sudo install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
        | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    sudo chmod a+r /etc/apt/keyrings/docker.gpg
    echo \
        "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
        https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
        | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt-get update -qq
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
else
    info "Docker already installed, skipping."
fi

if ! groups "$USER" | grep -q docker; then
    info "Adding $USER to the docker group..."
    sudo usermod -aG docker "$USER"
    warn "Log out and back in (or run 'newgrp docker') before using docker without sudo."
else
    info "User already in docker group."
fi

info "Creating /var/lib/hive..."
sudo mkdir -p "$CACHE_DIR"
sudo chown "$USER":"$USER" "$CACHE_DIR"

info "Creating /var/log/hive..."
sudo mkdir -p /var/log/hive
sudo chown "$USER":"$USER" /var/log/hive

info "Creating /etc/hive..."
sudo mkdir -p /etc/hive

if [[ ! -f "$SECRETS_FILE" ]]; then
    info "Writing secrets template to $SECRETS_FILE..."
    sudo tee "$SECRETS_FILE" > /dev/null <<'EOF'
GRAFANA_ADMIN_PASSWORD=changeme
ABUSEIPDB_API_KEY=your_abuseipdb_key_here
SHODAN_API_KEY=your_shodan_key_here
EOF
    sudo chmod 600 "$SECRETS_FILE"
    warn "Edit $SECRETS_FILE with real API keys before running the enricher."
else
    info "Secrets file already exists — leaving it alone."
fi

ENRICHMENT_DIR="$HIVE_DIR/phase4c/phase4c-enrichment"
[[ -d "$ENRICHMENT_DIR" ]] || error "Enrichment directory not found at $ENRICHMENT_DIR"

if [[ ! -d "$ENRICHMENT_DIR/venv" ]]; then
    info "Creating Python venv for phase4c enrichment..."
    python3 -m venv "$ENRICHMENT_DIR/venv"
    "$ENRICHMENT_DIR/venv/bin/pip" install --quiet -r "$ENRICHMENT_DIR/requirements.txt"
    info "Venv ready."
else
    info "Phase4c venv already exists — skipping."
fi

ELK_DIR="$HIVE_DIR/phase4a/phase4a-elk"
[[ -d "$ELK_DIR" ]] || error "ELK directory not found at $ELK_DIR"

info "Starting ELK stack..."
if groups "$USER" | grep -q docker; then
    docker compose -f "$ELK_DIR/docker-compose.yml" up -d
else
    sudo docker compose -f "$ELK_DIR/docker-compose.yml" up -d
fi

info "Waiting for Elasticsearch (up to 90s)..."
ES_READY=0
for i in $(seq 1 18); do
    if curl -sf http://localhost:9200/_cluster/health >/dev/null 2>&1; then
        ES_READY=1
        break
    fi
    echo -n "."
    sleep 5
done
echo ""
[[ $ES_READY -eq 1 ]] || error "Elasticsearch did not become healthy. Check: docker compose -f $ELK_DIR/docker-compose.yml logs elasticsearch"

info "Creating index templates..."
bash "$ELK_DIR/scripts/create-indices.sh"

ENRICHMENT_SCRIPT="$ENRICHMENT_DIR/scripts/run-enrichment.sh"
if [[ -f "$ENRICHMENT_SCRIPT" ]]; then
    CRON_LINE="0 */6 * * * source $SECRETS_FILE && HIVE_CACHE_DB=$CACHE_DIR/enrichment_cache.db bash $ENRICHMENT_SCRIPT >> $CRON_LOG 2>&1"
    if ! crontab -l 2>/dev/null | grep -qF "$ENRICHMENT_SCRIPT"; then
        info "Installing enrichment cron job (every 6 hours)..."
        ( crontab -l 2>/dev/null; echo "$CRON_LINE" ) | crontab -
    else
        info "Enrichment cron job already installed — skipping."
    fi
else
    warn "run-enrichment.sh not found — skipping cron setup."
fi

echo ""
info "Setup complete. Next steps:"
echo "  1. Fill in API keys:    sudo nano $SECRETS_FILE"
echo "  2. Set up WireGuard:    see phase3b/README"
echo "  3. Open Kibana:         http://localhost:5601"
echo "  4. Open Grafana:        http://localhost:3000"
echo ""
warn "If you were just added to the docker group, log out and back in before using docker without sudo."
