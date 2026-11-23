#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

if [[ -n "$(git status --porcelain)" ]]; then
  echo "Working tree is not clean. Commit or stash your existing changes first." >&2
  exit 1
fi
git pull --rebase origin main
if [[ ! -f application/fault-injection.enabled ]]; then
  echo "Fault injection is not enabled. Nothing to restore."
  exit 0
fi

rm application/fault-injection.enabled
git add -u application/fault-injection.enabled
git commit -m "fix: restore healthy application release"
git push origin main

echo "Healthy release pushed. Jenkins will rebuild and update the GitOps digest."
