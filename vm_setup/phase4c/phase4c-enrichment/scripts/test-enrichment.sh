#!/usr/bin/env bash
# Tests each enrichment source against 1.1.1.1 (Cloudflare — safe, won't burn quota).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/.."

if [ -d venv ]; then
    source venv/bin/activate
fi

if [ -z "${ABUSEIPDB_API_KEY:-}" ]; then
    echo "ERROR: ABUSEIPDB_API_KEY is not set"
    exit 1
fi
if [ -z "${SHODAN_API_KEY:-}" ]; then
    echo "ERROR: SHODAN_API_KEY is not set"
    exit 1
fi

python3 - <<'EOF'
import json
from sources.abuseipdb   import check_ip
from sources.shodan_lookup import lookup_ip
from sources.asn_lookup  import lookup_asn

TEST_IP = "1.1.1.1"
print(f"Testing enrichment sources against {TEST_IP} (Cloudflare)")
print()

print("--- AbuseIPDB ---")
result = check_ip(TEST_IP)
print(json.dumps(result, indent=2))
print()

print("--- Shodan ---")
result = lookup_ip(TEST_IP)
print(json.dumps(result, indent=2))
print()

print("--- ASN (ipinfo.io) ---")
result = lookup_asn(TEST_IP)
print(json.dumps(result, indent=2))
print()

print("All three sources responded successfully.")
EOF
