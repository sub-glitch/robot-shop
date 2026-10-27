#!/usr/bin/env bash
# Usage: ./instrument-service.sh cart nodejs      (cart is Node.js)
#        ./instrument-service.sh payment python   (fallback if cart's Node version is too old)
# Check first:  kubectl -n robot-shop exec deploy/cart -- node -v    (auto-instrumentation wants Node 18+)
set -euo pipefail
SVC=${1:-cart}; LANG_=${2:-nodejs}
kubectl apply -f "$(dirname "$0")/instrumentation.yaml"
kubectl -n robot-shop patch deployment "$SVC" --type merge -p \
  "{\"spec\":{\"template\":{\"metadata\":{\"annotations\":{\"instrumentation.opentelemetry.io/inject-${LANG_}\":\"robot-shop/robot-shop\"}}}}}"
kubectl -n robot-shop rollout status deployment "$SVC" --timeout=180s
echo "Now generate traffic (load-gen already does) and open Jaeger: kubectl -n monitoring port-forward svc/jaeger 16686:16686"
echo "NOTE: a 'helm upgrade' of the robot-shop chart removes this annotation; re-run this script afterwards."
