#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

python3 scripts/render-kyverno-policy.py
kubectl apply -f security/policies/require-nonroot.yaml
kubectl apply -f security/policies/verify-images.yaml
kubectl wait --for=condition=Ready clusterpolicy/require-restricted-delivery-demo-pods --timeout=180s
kubectl wait --for=condition=Ready clusterpolicy/verify-delivery-demo-images --timeout=180s

kubectl get clusterpolicy
