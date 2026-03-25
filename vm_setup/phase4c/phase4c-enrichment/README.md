# Phase 4c — IP Enrichment

## Setup

```bash
cd phase4c-enrichment
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

## API keys

| Service | Where to get | Free tier |
|---------|-------------|-----------|
| AbuseIPDB | abuseipdb.com → API tab | 1,000 checks/day |
| Shodan | shodan.io → Account → API Key | Limited |
| ipinfo.io | No key needed | 50k req/month |

Store keys on the analysis machine:

```bash
sudo mkdir -p /etc/hive
echo "your_abuseipdb_key" | sudo tee /etc/hive/abuseipdb.key
echo "your_shodan_key"    | sudo tee /etc/hive/shodan.key
sudo chmod 600 /etc/hive/*.key
```

## Test

```bash
export ABUSEIPDB_API_KEY="your_key"
export SHODAN_API_KEY="your_key"
bash scripts/test-enrichment.sh
```

## Run manually

```bash
source venv/bin/activate
export ABUSEIPDB_API_KEY="$(cat /etc/hive/abuseipdb.key)"
export SHODAN_API_KEY="$(cat /etc/hive/shodan.key)"
python enricher.py
```

## Cron (every 6 hours)

```bash
sudo cp scripts/run-enrichment.sh /opt/hive/scripts/run-enrichment.sh
sudo chmod +x /opt/hive/scripts/run-enrichment.sh
sudo cp -r . /opt/hive/phase4c-enrichment/
echo '0 */6 * * * /opt/hive/scripts/run-enrichment.sh >> /var/log/hive/enrichment.log 2>&1' | crontab -
```

## Reset cache

```bash
rm /var/lib/hive/enrichment_cache.db
```
