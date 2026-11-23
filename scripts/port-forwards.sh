#!/usr/bin/env bash
set -euo pipefail
kubectl config use-context kind-delivery-lab

cat <<'TXT'
Starting local-only port forwards. Keep this terminal open.
  Argo CD:   https://127.0.0.1:8081
  Grafana:   http://127.0.0.1:3000
  Prometheus http://127.0.0.1:9090
  Demo app:  http://127.0.0.1:8088
TXT

kubectl port-forward -n argocd svc/argocd-server 8081:443 &
P1=$!
kubectl port-forward -n monitoring svc/monitoring-grafana 3000:80 &
P2=$!
kubectl port-forward -n monitoring svc/monitoring-kube-prometheus-prometheus 9090:9090 &
P3=$!
kubectl port-forward -n delivery-demo svc/delivery-demo-stable 8088:8080 &
P4=$!
trap 'kill "$P1" "$P2" "$P3" "$P4" 2>/dev/null || true' EXIT INT TERM
wait
