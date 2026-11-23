#!/usr/bin/env bash
set -euo pipefail

missing=0
for bin in docker kubectl kind helm git curl python3 openssl jq; do
  if ! command -v "$bin" >/dev/null 2>&1; then
    printf 'MISSING  %s\n' "$bin"
    missing=1
  else
    printf 'FOUND    %-10s %s\n' "$bin" "$(command -v "$bin")"
  fi
done

if [[ "$(uname -m)" != "x86_64" ]]; then
  echo "NOTE: This bundle pins the Jenkins tool image to linux/amd64."
  echo "      On $(uname -m), update ci/Dockerfile and tool downloads before building."
fi

if command -v docker >/dev/null 2>&1; then
  if ! docker info >/dev/null 2>&1; then
    echo "ERROR: Docker is installed but the daemon is unavailable or the current user lacks permission."
    echo "       Start it with: sudo systemctl enable --now docker"
    echo "       Then log out/in after adding your user to the docker group."
    missing=1
  fi
  if ! docker compose version >/dev/null 2>&1; then
    echo "MISSING  docker compose plugin"
    missing=1
  else
    docker compose version
  fi
fi

if [[ "$missing" -ne 0 ]]; then
  echo "Install the missing prerequisites using docs/requirements.md."
  exit 1
fi

echo "All required host prerequisites are available."
