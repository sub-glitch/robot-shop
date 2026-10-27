#!/usr/bin/env bash
# Rehearse the incident drill yourself BEFORE the instructor does it.
#   ./drill-helper.sh break      scales cart to 0 (simulated outage)
#   ./drill-helper.sh bad-image  ships a bad image to catalogue
#   ./drill-helper.sh fix        restores both
set -euo pipefail
case "${1:-}" in
  break)     kubectl -n robot-shop scale deployment cart --replicas=0; date -u +"outage started %H:%M:%SZ" | tee -a /tmp/drill-timeline.txt ;;
  bad-image) kubectl -n robot-shop set image deployment/catalogue catalogue=robotshop/rs-catalogue:does-not-exist; date -u +"bad image shipped %H:%M:%SZ" | tee -a /tmp/drill-timeline.txt ;;
  fix)       kubectl -n robot-shop scale deployment cart --replicas=1
             kubectl -n robot-shop rollout undo deployment/catalogue 2>/dev/null || true
             date -u +"mitigated %H:%M:%SZ" | tee -a /tmp/drill-timeline.txt ;;
  *) echo "usage: $0 break|bad-image|fix"; exit 1 ;;
esac
