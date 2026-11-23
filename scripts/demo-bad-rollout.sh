#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

if [[ -n "$(git status --porcelain)" ]]; then
  echo "Working tree is not clean. Commit or stash your existing changes first." >&2
  exit 1
fi
git pull --rebase origin main
if [[ -f application/fault-injection.enabled ]]; then
  echo "Fault injection is already enabled. Remove it with scripts/restore-healthy-release.sh." >&2
  exit 1
fi

touch application/fault-injection.enabled
git add application/fault-injection.enabled
git commit -m "test: simulate an unhealthy canary release"
git push origin main

cat <<'TXT'
Fault-injection commit pushed.

Expected flow:
  1. Jenkins detects the application change and builds FAIL_REQUESTS=true.
  2. Trivy scans, Syft generates an SBOM, Cosign signs and attests the image.
  3. Jenkins updates the GitOps digest in GitHub.
  4. Argo CD syncs the digest; Argo Rollouts starts a canary.
  5. The load-generator hits the canary Service; the bad version returns HTTP 503.
  6. Prometheus analysis fails and Argo Rollouts aborts the canary.

Watch with:
  kubectl argo rollouts get rollout delivery-demo -n delivery-demo --watch
  kubectl get pods -n delivery-demo -w
  kubectl port-forward -n monitoring svc/monitoring-kube-prometheus-prometheus 9090:9090

After confirming the previous stable ReplicaSet still serves traffic, run:
  ./scripts/restore-healthy-release.sh
TXT
