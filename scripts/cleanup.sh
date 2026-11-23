#!/usr/bin/env bash
set -euo pipefail
CLUSTER_NAME="delivery-lab"
read -r -p "Delete Kind cluster '${CLUSTER_NAME}'? Persistent Jenkins/registry volumes will be kept. [y/N] " answer
if [[ "$answer" =~ ^[Yy]$ ]]; then
  kind delete cluster --name "$CLUSTER_NAME"
  echo "Kind cluster deleted. Local Jenkins and registry containers remain running."
else
  echo "Nothing changed."
fi
