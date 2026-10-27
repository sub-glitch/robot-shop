# Runbook: Robot Shop Availability Alerts

Alerts: `RobotShopAvailabilityLow`, `RobotShopDeploymentUnavailable`
Linked from: the `runbook_url` annotation on both alerts.

## 1. What does this alert mean?
Users cannot reliably use part of the shop. The synthetic probe for one service (the `service` label) is failing, or a deployment has fewer ready pods than it should.

## 2. Mitigate FIRST (restore service, then investigate)
1. Was there a recent deploy? `helm history robot-shop -n robot-shop` and `kubectl -n robot-shop rollout history deployment/<service>`
2. If yes: `helm rollback robot-shop <previous-revision> -n robot-shop` or `kubectl -n robot-shop rollout undo deployment/<service>`
3. If a deployment is at 0 replicas or crash looping: `kubectl -n robot-shop scale deployment/<service> --replicas=1` then `kubectl -n robot-shop rollout restart deployment/<service>`
4. If pods are Pending: the cluster is out of capacity. `kubectl describe pod <pod> -n robot-shop` and add a node (raise `node_desired_size`, apply Terraform).
5. Confirm recovery: the availability panel is back near 100% and the alert resolves in Slack.

## 3. Diagnose
| Question | Where to look |
|---|---|
| When did it start and which service? | Grafana dashboard "Robot Shop - Requests, Errors, Latency" |
| What did the service say? | Grafana Explore, Loki: `{namespace="robot-shop", service="<svc>", level="error"}` |
| Which hop is slow or failing? | Jaeger (`kubectl -n monitoring port-forward svc/jaeger 16686:16686`), pick service, find a failed trace |
| Pod state | `kubectl get pods -n robot-shop`, `kubectl describe pod <pod> -n robot-shop`, `kubectl logs <pod> -n robot-shop --previous` |
| Dependencies | `kubectl get pods -n robot-shop` for mongodb, redis, mysql, rabbitmq |

## 4. Escalate
If not mitigated within 15 minutes, or if data may be lost, escalate to CHANGEME (instructor / team lead).

## 5. After the incident
Write a blameless postmortem within 48 hours using `postmortem-template.md`. Update this runbook with anything that was missing.
