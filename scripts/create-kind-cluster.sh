#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
CLUSTER_NAME="delivery-lab"
REGISTRY_NAME="kind-registry"
REGISTRY_PORT="5000"
NODE_IMAGE="kindest/node:v1.37.0@sha256:a1ed56cfb0e7b93589bdf97c8cd566405a265939e3620fc4f5de89adff580ae5"

command -v kind >/dev/null || { echo "kind is required; see docs/requirements.md" >&2; exit 1; }
command -v kubectl >/dev/null || { echo "kubectl is required; see docs/requirements.md" >&2; exit 1; }
docker info >/dev/null 2>&1 || { echo "Docker daemon is not available" >&2; exit 1; }

docker inspect "$REGISTRY_NAME" >/dev/null 2>&1 || {
  echo "Local registry container '$REGISTRY_NAME' is not running. Start it first:"
  echo "  docker compose up -d kind-registry"
  exit 1
}

if kind get clusters | grep -qx "$CLUSTER_NAME"; then
  echo "Kind cluster '$CLUSTER_NAME' already exists; reusing it."
else
  kind create cluster \
    --name "$CLUSTER_NAME" \
    --image "$NODE_IMAGE" \
    --config "$ROOT/platform/kind/cluster.yaml" \
    --wait 180s
fi

# Register the local HTTP registry in every Kind node's containerd hosts directory.
# Kind v0.27+ configures certs.d by default; this explicit hosts.toml maps the name
# used by image references to the registry container on the Kind Docker network.
for node in $(kind get nodes --name "$CLUSTER_NAME"); do
  docker exec "$node" mkdir -p "/etc/containerd/certs.d/${REGISTRY_NAME}:${REGISTRY_PORT}"
  printf '[host."http://%s:%s"]\n  capabilities = ["pull", "resolve"]\n' "$REGISTRY_NAME" "$REGISTRY_PORT" \
    | docker exec -i "$node" tee "/etc/containerd/certs.d/${REGISTRY_NAME}:${REGISTRY_PORT}/hosts.toml" >/dev/null
done

if [[ "$(docker inspect -f '{{if index .NetworkSettings.Networks "kind"}}connected{{else}}missing{{end}}' "$REGISTRY_NAME")" == "missing" ]]; then
  docker network connect kind "$REGISTRY_NAME"
fi

kubectl config use-context "kind-${CLUSTER_NAME}"
kubectl apply -f "$ROOT/platform/kind/local-registry-configmap.yaml"

kubectl wait --for=condition=Ready nodes --all --timeout=180s

echo
echo "Kind cluster '${CLUSTER_NAME}' is ready."
kubectl get nodes -o wide
