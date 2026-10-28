# SLO and Error Budget Policy: Robot Shop

**Owner:** Uleko Blessing Samuel | **Reviewed:** 2026-10-28 | **Review cadence:** every Wednesday catch-up

## Service and scope
Robot Shop storefront. Critical user journeys: browse catalogue, add to cart, pay. Services in scope: `web`, `catalogue`, `cart`, `payment`.

## SLI (how we measure health)
Availability = successful synthetic probes / total probes, per service.
- Probe: blackbox exporter, HTTP GET through the `web` service every 15 seconds, success = HTTP 2xx within 5 seconds.
- Prometheus query: `avg by (service) (avg_over_time(probe_success{app="robot-shop"}[5m]))`
- Recorded as `sli:availability:ratio_5m` in `capstone2/monitoring/robot-shop-rules.yaml`.

## SLO (the target)
**99% availability per service, measured over a rolling 30 days.**

## Error budget
- Budget = 1% of the window = **7.2 hours** of full unavailability per 30 days (about 432 minutes).
- Example: a 30 minute cart outage consumes about 7% of the cart error budget.
- Note: Prometheus keeps 5 days of data in this capstone, so the 30 day figure is tracked from the recorded SLI and reported manually. Production would use longer retention or remote storage.

## Alerting
| Alert | Condition | Severity | Goes to |
|---|---|---|---|
| RobotShopAvailabilityLow | availability below 90% for 1 minute | page | Slack |
| RobotShopDeploymentUnavailable | fewer ready replicas than desired for 2 minutes | page | Slack |
| (stretch) FastBurn / SlowBurn | 14.4x over 1h+5m, 6x over 6h+30m | page / warning | Slack |

Every alert links to the runbook: `capstone2/docs/runbook.md`.

## Error budget policy
| Budget consumed (30 days) | Action |
|---|---|
| 0 to 50% | Normal development. Ship features as usual. |
| 50 to 75% | Review recent incidents at the next catch-up. Add missing alerts or tests. Risky changes need a rollback plan. |
| 75 to 100% | Only reliability fixes and low-risk changes. Every deploy must be watched on the dashboard. |
| 100% or more | **Feature freeze.** Only fixes that improve reliability ship until the budget recovers above 25%. Blameless postmortem required for the cause. |

**Decision makers:** service owner decides on exceptions; document every exception in the repository.
**Exclusions:** planned maintenance announced 24 hours ahead does not count against the budget.
