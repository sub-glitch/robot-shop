#!/usr/bin/env bash
# Turns the dashboard JSON into a ConfigMap that Grafana's sidecar auto-loads, and saves that YAML to Git.
set -euo pipefail
cd "$(dirname "$0")"
python3 gen_dashboard.py
kubectl create configmap robot-shop-dashboard -n monitoring --from-file=robot-shop-red.json \
  --dry-run=client -o yaml \
  | kubectl label --local -f - grafana_dashboard=1 -o yaml > robot-shop-dashboard-configmap.yaml
kubectl apply -f robot-shop-dashboard-configmap.yaml
echo "Dashboard loaded. Grafana picks it up within about a minute."
