#!/usr/bin/env bash
# Called from cron every 6 hours. Key files must be chmod 600.
set -euo pipefail

ABUSEIPDB_KEY_FILE="/etc/hive/abuseipdb.key"
SHODAN_KEY_FILE="/etc/hive/shodan.key"
ENRICHER_DIR="/opt/hive/phase4c-enrichment"

if [ ! -f "$ABUSEIPDB_KEY_FILE" ]; then
    echo "$(date -u '+%Y-%m-%dT%H:%M:%SZ') ERROR: $ABUSEIPDB_KEY_FILE not found"
    exit 1
fi
if [ ! -f "$SHODAN_KEY_FILE" ]; then
    echo "$(date -u '+%Y-%m-%dT%H:%M:%SZ') ERROR: $SHODAN_KEY_FILE not found"
    exit 1
fi

export ABUSEIPDB_API_KEY="$(cat "$ABUSEIPDB_KEY_FILE")"
export SHODAN_API_KEY="$(cat "$SHODAN_KEY_FILE")"
export ES_HOST="localhost"
export ES_PORT="9200"

cd "$ENRICHER_DIR"
source venv/bin/activate
python enricher.py
