#!/usr/bin/env bash
# Shows what the Robot Shop services really expose, so you can fix metric names in gen_dashboard.py
set -uo pipefail
for svc in cart catalogue payment user; do
  echo "=================== $svc /metrics (first 25 lines matching http or custom metrics)"
  kubectl -n robot-shop run "probe-$svc" --rm -i --restart=Never --image=curlimages/curl:8.10.1 --quiet -- \
    curl -s -m 5 "http://$svc:8080/metrics" | grep -v '^#' | head -25 || echo "(no /metrics)"
done
echo
echo "Which targets does Prometheus see?  Open Status > Targets, job 'robot-shop'."
echo "Then in Grafana Explore try:  {namespace=\"robot-shop\"} metrics matching http_*"
