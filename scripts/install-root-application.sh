#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

if grep -q 'anouarharrou' gitops/root-application.yaml; then
  echo "Configure the GitHub repository URL first:" >&2
  echo "  ./scripts/configure-repository.sh https://github.com/OWNER/secure-gitops-delivery-platform.git" >&2
  exit 1
fi

kubectl config use-context kind-delivery-lab
kubectl apply -f gitops/root-application.yaml

echo "Applied Argo CD Application. Watch it with:"
echo "  kubectl get applications -n argocd -w"
