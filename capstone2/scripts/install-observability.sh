#!/usr/bin/env bash
# One command to install the whole Capstone 2 stack on the cluster from Capstone 1.
# Prereqs: kubectl points at the cluster, helm installed, Robot Shop already deployed in namespace robot-shop,
#          export SLACK_WEBHOOK_URL=https://hooks.slack.com/services/...   (never commit this)
# Optional: pin chart versions after the first run, e.g.  KPS_VERSION=xx.y.z ./install-observability.sh
set -euo pipefail
cd "$(dirname "$0")/.."

: "${SLACK_WEBHOOK_URL:?export SLACK_WEBHOOK_URL first}"
ver() { [ -n "${1:-}" ] && echo "--version $1" || true; }

helm repo add prometheus-community https://prometheus-community.github.io/helm-charts >/dev/null
helm repo add grafana https://grafana.github.io/helm-charts >/dev/null
helm repo add fluent https://fluent.github.io/helm-charts >/dev/null
helm repo add open-telemetry https://open-telemetry.github.io/opentelemetry-helm-charts >/dev/null
helm repo add jetstack https://charts.jetstack.io >/dev/null
helm repo update >/dev/null

kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -

echo ">> Secrets (created in-cluster only)"
GRAFANA_PW=${GRAFANA_PW:-$(LC_ALL=C tr -dc 'A-Za-z0-9' </dev/urandom | head -c 20)}
kubectl -n monitoring create secret generic grafana-admin \
  --from-literal=admin-user=admin --from-literal=admin-password="$GRAFANA_PW" \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl -n monitoring create secret generic alertmanager-slack \
  --from-literal=webhook_url="$SLACK_WEBHOOK_URL" \
  --dry-run=client -o yaml | kubectl apply -f -

echo ">> kube-prometheus-stack (Prometheus, Alertmanager, Grafana)"
# shellcheck disable=SC2046
helm upgrade --install monitoring prometheus-community/kube-prometheus-stack -n monitoring \
  $(ver "${KPS_VERSION:-}") -f monitoring/kube-prometheus-stack-values.yaml --wait --timeout 10m

echo ">> Loki"
# shellcheck disable=SC2046
helm upgrade --install loki grafana/loki -n monitoring \
  $(ver "${LOKI_VERSION:-}") -f monitoring/loki-values.yaml --wait --timeout 10m

echo ">> Fluent Bit"
# shellcheck disable=SC2046
helm upgrade --install fluent-bit fluent/fluent-bit -n monitoring \
  $(ver "${FLUENTBIT_VERSION:-}") -f monitoring/fluent-bit-values.yaml --wait --timeout 5m

echo ">> Blackbox exporter + probes + alert rules"
# shellcheck disable=SC2046
helm upgrade --install blackbox prometheus-community/prometheus-blackbox-exporter -n monitoring \
  $(ver "${BLACKBOX_VERSION:-}") -f monitoring/blackbox-values.yaml --wait
kubectl apply -f monitoring/probes.yaml
kubectl apply -f monitoring/robot-shop-rules.yaml

echo ">> Jaeger + OpenTelemetry Collector"
kubectl apply -f tracing/jaeger.yaml
# shellcheck disable=SC2046
helm upgrade --install otel-collector open-telemetry/opentelemetry-collector -n monitoring \
  $(ver "${OTELCOL_VERSION:-}") -f tracing/otel-collector-values.yaml --wait --timeout 5m

echo ">> cert-manager + OpenTelemetry Operator (for zero-code auto-instrumentation)"
helm upgrade --install cert-manager jetstack/cert-manager -n cert-manager --create-namespace \
  --set crds.enabled=true --wait --timeout 5m
helm upgrade --install otel-operator open-telemetry/opentelemetry-operator -n opentelemetry-operator-system \
  --create-namespace --set manager.collectorImage.repository=otel/opentelemetry-collector-contrib \
  --wait --timeout 5m

echo ">> Load generator + dashboard"
kubectl apply -f robot-shop/load-gen.yaml
dashboards/apply-dashboard.sh

cat <<MSG

DONE.
Grafana admin password (save it, it is not stored in Git):  $GRAFANA_PW
  kubectl -n monitoring port-forward svc/monitoring-grafana 3000:80    -> http://localhost:3000  (user: admin)
  kubectl -n monitoring port-forward svc/jaeger 16686:16686            -> http://localhost:16686
  kubectl -n monitoring port-forward svc/monitoring-kube-prometheus-prometheus 9090:9090
Next: ./tracing/instrument-service.sh cart nodejs
MSG
