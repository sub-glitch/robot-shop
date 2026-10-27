#!/usr/bin/env bash
set -uo pipefail
helm uninstall otel-operator -n opentelemetry-operator-system || true
helm uninstall cert-manager -n cert-manager || true
helm uninstall otel-collector fluent-bit loki blackbox monitoring -n monitoring || true
kubectl delete -f "$(dirname "$0")/../tracing/jaeger.yaml" --ignore-not-found
kubectl delete pvc --all -n monitoring
