# Postmortem: Robot Shop Kubernetes Deployment Degradation

**Date:** 2026-10-28 | **Authors:** Uleko Blessing Samuel | **Status:** Draft
**Severity:** Major (development environment) | **Duration:** Under investigation | **Error budget consumed:** Not measured

## Summary
During the capstone deployment, several Robot Shop dependencies and dependent services failed readiness checks or entered crash loops in the local Kind cluster. The MySQL and RabbitMQ pods were observed in OOMKilled/CrashLoopBackOff states, while ratings and shipping were not healthy. The application remained reachable through Docker Compose, but Kubernetes health was not restored during this investigation.

## Impact
- Kubernetes user journeys could be degraded because database/message-broker dependencies were unhealthy.
- The Docker Compose storefront responded with HTTP 200 during verification.
- Actual failed-request counts and outage duration were not measured.
- No successful Slack alert delivery was verified.

## Timeline (UTC)
| Time | Event |
|---|---|
| 2026-10-28, time not recorded | Kubernetes deployment observed with unhealthy dependencies and dependent services |
| 2026-10-28, time not recorded | MySQL and RabbitMQ resource settings were adjusted; failures persisted |
| 2026-10-28, time not recorded | Docker Compose storefront verified with HTTP 200 |
| 2026-10-28, time not recorded | Monitoring installation attempted; Helm repository request timed out |
| 2026-10-28 | Investigation paused to prioritize submission documentation and repository delivery |

## Detection
The issue was found by inspecting Kubernetes pod status and container logs. Prometheus/Grafana installation did not complete, so automated alert detection was not verified.

## Root cause
The definitive root cause has not been established. Observed evidence includes OOMKilled/exit 137 for MySQL and RabbitMQ, failing readiness for ratings, and connection failures for shipping. The Helm repository request also timed out, preventing the planned monitoring stack installation.

## What went well
- The Docker Compose storefront remained reachable.
- Kubernetes pod status and application response checks helped distinguish the local Compose environment from the Kind deployment.

## What went badly
- Kubernetes dependencies remained unhealthy after resource adjustments.
- Monitoring, logging, tracing, and Slack alert delivery were not verified.

## Where we got lucky
- The Docker Compose application remained available for a basic functional check.

## Action items
| Action | Type (prevent / detect / mitigate) | Owner | Due |
|---|---|---|---|
| Diagnose MySQL and RabbitMQ termination events using pod events and resource metrics | prevent | Project owner | Follow-up |
| Restore Kubernetes dependency health and verify service readiness | mitigate | Project owner | Follow-up |
| Deploy Prometheus/Grafana and validate the dashboard | detect | Project owner | Follow-up |
| Validate log search, a Jaeger trace, and Slack alert delivery | detect | Project owner | Follow-up |

## Lessons learned
Verify each layer independently, keep measured evidence separate from assumptions, and establish basic service health before relying on observability integrations.
