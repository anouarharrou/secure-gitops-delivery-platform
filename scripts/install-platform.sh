#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

CONTEXT="kind-delivery-lab"
kubectl config use-context "$CONTEXT"

# Argo CD (non-HA profile is appropriate for a laptop lab).
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
kubectl apply --server-side --force-conflicts -n argocd \
  -f "https://raw.githubusercontent.com/argoproj/argo-cd/v3.6.1/manifests/install.yaml"
kubectl rollout status deployment/argocd-server -n argocd --timeout=300s

# Kyverno 1.20.0 (Helm chart 3.10.0).
helm repo add kyverno https://kyverno.github.io/kyverno/ --force-update
helm repo update
helm upgrade --install kyverno kyverno/kyverno \
  --version 3.10.0 \
  --namespace kyverno --create-namespace \
  --set admissionController.replicas=1 \
  --set backgroundController.replicas=1 \
  --set cleanupController.replicas=1 \
  --set reportsController.replicas=1 \
  --wait --timeout 5m

# Lab-only switch: the registry is a private, loopback-bound HTTP registry.
# Never enable this for an internet-exposed or production registry.
if ! kubectl get deployment kyverno-admission-controller -n kyverno -o jsonpath='{.spec.template.spec.containers[0].args}' | grep -q -- '--allowInsecureRegistry'; then
  kubectl patch deployment kyverno-admission-controller -n kyverno --type='json' \
    -p='[{"op":"add","path":"/spec/template/spec/containers/0/args/-","value":"--allowInsecureRegistry"}]'
fi
kubectl rollout status deployment/kyverno-admission-controller -n kyverno --timeout=300s

# Argo Rollouts controller + CRDs.
kubectl create namespace argo-rollouts --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -n argo-rollouts \
  -f https://github.com/argoproj/argo-rollouts/releases/download/v1.10.2/install.yaml
kubectl rollout status deployment/argo-rollouts -n argo-rollouts --timeout=300s

# Prometheus Operator, Prometheus, Alertmanager and Grafana.
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts --force-update
helm repo update
helm upgrade --install monitoring prometheus-community/kube-prometheus-stack \
  --version 93.9.0 \
  --namespace monitoring --create-namespace \
  -f platform/monitoring/values.yaml \
  --wait --timeout 10m

kubectl wait --for=condition=Established crd/servicemonitors.monitoring.coreos.com --timeout=180s

echo
echo "Platform controllers installed. Check:"
kubectl get pods -n argocd
kubectl get pods -n kyverno
kubectl get pods -n argo-rollouts
kubectl get pods -n monitoring
