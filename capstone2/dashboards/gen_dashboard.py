#!/usr/bin/env python3
"""Generates robot-shop-red.json (Grafana dashboard) so the dashboard is code you can review in Git.

Row 1 uses blackbox probe metrics (always available).
Row 2 uses the app's own /metrics. Run scripts/discover-metrics.sh, then edit the three constants below
if the real metric / label names differ.
"""
import json

APP_HIST = "http_request_duration_seconds"   # histogram base name exposed by the services
STATUS_LABEL = "status"                      # label holding the HTTP status code (could be status_code / code)
NS = "robot-shop"
DS = {"type": "prometheus", "uid": "prometheus"}
_id = 0


def panel(title, exprs, x, y, w=8, h=8, unit="short", legend="{{service}}", thresholds=None):
    global _id
    _id += 1
    p = {
        "id": _id, "type": "timeseries", "title": title, "datasource": DS,
        "gridPos": {"x": x, "y": y, "w": w, "h": h},
        "fieldConfig": {"defaults": {"unit": unit, "custom": {"lineWidth": 2, "fillOpacity": 10}}, "overrides": []},
        "options": {"legend": {"displayMode": "table", "placement": "bottom", "calcs": ["lastNotNull", "max"]},
                    "tooltip": {"mode": "multi"}},
        "targets": [{"refId": chr(65 + i), "expr": e, "legendFormat": legend, "datasource": DS}
                    for i, e in enumerate(exprs)],
    }
    if thresholds:
        p["fieldConfig"]["defaults"]["min"] = 0
        p["fieldConfig"]["defaults"]["max"] = 1
    return p


def row(title, y):
    global _id
    _id += 1
    return {"id": _id, "type": "row", "title": title, "collapsed": False, "gridPos": {"x": 0, "y": y, "w": 24, "h": 1}}


panels = [
    row("Synthetic golden signals (blackbox probes through the web service)", 0),
    panel("Availability (5m success ratio)",
          ['avg by (service) (avg_over_time(probe_success{app="robot-shop"}[5m]))'],
          0, 1, unit="percentunit", thresholds=True),
    panel("Errors (failed probes in last 5m)",
          ['sum by (service) (count_over_time(probe_success{app="robot-shop"}[5m]) * (1 - avg_over_time(probe_success{app="robot-shop"}[5m])))'],
          8, 1),
    panel("Latency (probe duration)",
          ['max by (service) (probe_duration_seconds{app="robot-shop"})'],
          16, 1, unit="s"),

    row("Application metrics (edit constants in gen_dashboard.py after discovery)", 9),
    panel("Requests per second",
          [f'sum by (service) (rate({APP_HIST}_count{{namespace="{NS}"}}[5m]))'],
          0, 10, unit="reqps"),
    panel("Error rate (5xx)",
          [f'sum by (service) (rate({APP_HIST}_count{{namespace="{NS}",{STATUS_LABEL}=~"5.."}}[5m]))'],
          8, 10, unit="reqps"),
    panel("Latency p95",
          [f'histogram_quantile(0.95, sum by (le, service) (rate({APP_HIST}_bucket{{namespace="{NS}"}}[5m])))'],
          16, 10, unit="s"),

    row("Platform (always available)", 18),
    panel("Pod restarts (1h)",
          [f'sum by (pod) (increase(kube_pod_container_status_restarts_total{{namespace="{NS}"}}[1h]))'],
          0, 19, legend="{{pod}}"),
    panel("CPU by pod (cores)",
          [f'sum by (pod) (rate(container_cpu_usage_seconds_total{{namespace="{NS}",container!=""}}[5m]))'],
          8, 19, legend="{{pod}}"),
    panel("Memory by pod",
          [f'sum by (pod) (container_memory_working_set_bytes{{namespace="{NS}",container!=""}})'],
          16, 19, unit="bytes", legend="{{pod}}"),
]

dash = {
    "uid": "robot-shop-red", "title": "Robot Shop - Requests, Errors, Latency",
    "tags": ["capstone", "robot-shop"], "timezone": "browser", "schemaVersion": 39, "version": 1,
    "refresh": "15s", "time": {"from": "now-1h", "to": "now"}, "panels": panels,
}
with open("robot-shop-red.json", "w") as f:
    json.dump(dash, f, indent=2)
print("wrote robot-shop-red.json")
