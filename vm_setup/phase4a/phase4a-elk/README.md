# Phase 4a — ELK Stack

## Prerequisites

- Docker and Docker Compose installed
- At least 4GB RAM free
- Ports 9200, 5601, 5044 available

```bash
sudo apt install docker.io docker-compose-plugin -y
sudo usermod -aG docker $USER   # log out and back in after this
```

## Start

```bash
cd phase4a-elk
docker compose up -d
```

Elasticsearch takes ~60 seconds to become healthy. Watch progress:

```bash
docker compose logs -f elasticsearch
```

## Verify

```bash
bash scripts/verify-stack.sh
```

## Create index templates (do this before first ingest)

```bash
bash scripts/create-indices.sh
```

| Template | Index pattern |
|----------|--------------|
| hive-web | `hive-web-*` |
| hive-cowrie | `hive-cowrie-*` |
| hive-suricata | `hive-suricata-*` |
| hive-pcap | `hive-pcap-*` |
| hive-enriched | `hive-enriched-*` |

## Test ingestion

```bash
bash scripts/test-ingest.sh
```

## Open Kibana

http://localhost:5601

## Rebuild from scratch

```bash
docker compose down -v
docker compose up -d
bash scripts/create-indices.sh
```

## Switch to WireGuard (production)

In `docker-compose.yml`, change the Logstash port binding:

```yaml
- "10.0.0.2:5044:5044"
```

Update `00-input.conf` host to `"10.0.0.2"`.
