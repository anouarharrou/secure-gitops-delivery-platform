#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

kubectl config use-context kind-delivery-lab
kubectl get namespace delivery-demo >/dev/null 2>&1 || {
  echo "delivery-demo namespace does not exist yet. Complete the README setup first." >&2
  exit 1
}

run_expected_denial() {
  local file="$1"
  local label="$2"
  echo "== Expecting admission denial: $label =="
  if kubectl apply --dry-run=server -f "$file"; then
    echo "FAIL: the API server admitted $label" >&2
    exit 1
  else
    echo "PASS: admission denied $label"
  fi
}

run_expected_denial tests/fixtures/invalid-root-pod.yaml "a root / unrestricted Pod"
run_expected_denial tests/fixtures/unsigned-image-pod.yaml "an unsigned local image"

echo "All admission-denial checks behaved as expected."
