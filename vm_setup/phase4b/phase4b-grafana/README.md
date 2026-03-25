# Phase 4b — Grafana Dashboards

## Prerequisites

Phase 4a ELK stack must be running:

```bash
cd ../phase4a-elk
docker compose ps
```

## Add Grafana to Phase 4a

1. Copy the `grafana` service block from `docker-compose-addition.yml` into `phase4a-elk/docker-compose.yml`
2. Add `grafanadb:` to the `volumes:` section
3. Run:

```bash
cp -r ../phase4b-grafana ./phase4b-grafana
docker compose up -d grafana
```

## Verify

```bash
bash phase4b-grafana/scripts/verify-grafana.sh
```

## Open Grafana

```
http://localhost:3000
Login: admin / honeypot2025
```

## Dashboards

| Dashboard | Data source |
|-----------|-------------|
| Attack Overview | `hive-*` |
| Web Hive | `hive-web-*` |
| SSH/Telnet (Cowrie) | `hive-cowrie-*` |
| IDS Alerts | `hive-suricata-*` |
| Geographic | `hive-*` |
| IP Enrichment | `hive-enriched-*` (requires Phase 4c) |

## Editing dashboards

1. Edit in the Grafana UI
2. **Share → Export → Save to file**
3. Replace the corresponding JSON in `provisioning/dashboards/`
4. Commit to git

## Rebuild from scratch

```bash
docker compose down -v
docker compose up -d
```

## Remote access

```bash
ssh -L 3000:localhost:3000 user@analysis-machine
```
