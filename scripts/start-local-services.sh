#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

./scripts/check-prereqs.sh

if [[ ! -f .env ]]; then
  cp .env.example .env
  echo "Created .env from .env.example."
fi

docker compose up -d --build

echo
echo "Local services are starting:"
echo "  Jenkins:  http://127.0.0.1:8080"
echo "  Registry: http://127.0.0.1:5000/v2/"
echo
echo "First Jenkins unlock password:"
docker compose exec -T jenkins sh -c 'cat /var/jenkins_home/secrets/initialAdminPassword' 2>/dev/null || \
  echo "Jenkins is still initializing. Retry: docker compose exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword"
