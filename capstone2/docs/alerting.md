# Alerting and Slack Notifications

## Overview

This document describes the alerting pipeline configured for the DevOps Capstone 2 project. Prometheus evaluates alert rules, Alertmanager receives and routes alerts, and Slack delivers notifications to the `capstone-alerts` channel.

## Architecture

The alerting flow is:

Prometheus → Alertmanager → Slack (`capstone-alerts`)

- **Prometheus:** Evaluates configured alerting rules.
- **Alertmanager:** Receives alerts from Prometheus and manages notification delivery, including firing and resolved notifications.
- **Slack:** Receives alert notifications in the `capstone-alerts` channel.

## Configuration

Prometheus and Alertmanager were run as Docker containers for this validation.

The Prometheus configuration includes:
- A 15-second scrape interval.
- A 15-second rule evaluation interval.
- An alertmanager target of `capstone-alertmanager:9093`.
- A rule file at `/etc/prometheus/alert.rules.yml`.

The test rule `PrometheusToSlackTest` uses `vector(1)`, which always returns a value of 1. The rule waits 10 seconds before firing.

The alert includes the labels:
- `service: robot-shop`
- `severity: warning`

Its purpose is to validate alert delivery, not to measure actual Robot Shop health.

## Validation Results

The following checks were completed:

1. A direct Slack notification test was received in `capstone-alerts`.
2. Alertmanager delivered a test alert to Slack.
3. A resolved notification was received when the Alertmanager test alert resolved.
4. Prometheus evaluated `PrometheusToSlackTest` and reported it as firing.
5. Slack received the corresponding Prometheus alert notification.

These results confirm that the synthetic alerting pipeline works from Prometheus rule evaluation through Alertmanager to Slack.

## Limitations

- The test rule is synthetic and does not detect real service failures.
- Prometheus and Alertmanager were run in Docker rather than deployed as a complete Kubernetes monitoring stack.
- Workload-specific alert rules and comprehensive monitoring of Robot Shop services remain incomplete.
- This validation does not establish that all application components are healthy or that production alerting is fully operational.

## Evidence

Screenshots of the Prometheus alert, Alertmanager alert, and Slack notification are stored in `capstone2/docs/evidence/`.

## Security

Slack webhook URLs must be kept secret. Store webhook credentials in protected configuration or a secrets manager, never commit them to Git, and rotate any webhook that has been exposed.
