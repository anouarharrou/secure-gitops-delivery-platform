#!/usr/bin/env bash
set -euo pipefail
kubectl config use-context kind-delivery-lab
printf '\n== Nodes ==\n'
kubectl get nodes -o wide
printf '\n== Core platform ==\n'
for ns in argocd kyverno argo-rollouts monitoring delivery-demo; do
  echo "--- namespace: $ns ---"
  kubectl get pods -n "$ns" 2>/dev/null || true
done
printf '\n== Argo CD Applications ==\n'
kubectl get applications -n argocd 2>/dev/null || true
printf '\n== Rollout ==\n'
kubectl get rollouts -n delivery-demo 2>/dev/null || true
