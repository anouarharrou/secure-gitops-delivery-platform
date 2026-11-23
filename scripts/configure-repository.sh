#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 https://github.com/OWNER/REPOSITORY.git" >&2
  exit 2
fi
REPO_URL="$1"
if [[ ! "$REPO_URL" =~ ^https://github\.com/[^/]+/[^/]+(\.git)?$ ]]; then
  echo "Expected a GitHub HTTPS repository URL, for example:" >&2
  echo "  https://github.com/YOUR_USERNAME/secure-gitops-delivery-platform.git" >&2
  exit 2
fi

python3 - "$ROOT/gitops/root-application.yaml" "$REPO_URL" <<'PY'
from pathlib import Path
import re
import sys
path = Path(sys.argv[1])
url = sys.argv[2].removesuffix(".git") + ".git"
text = path.read_text()
text, count = re.subn(r'(?m)^([ ]*repoURL:\s*).+$', lambda m: m.group(1) + url, text, count=1)
if count != 1:
    raise SystemExit("Could not find exactly one repoURL field in root-application.yaml")
path.write_text(text)
print(f"Updated {path} -> {url}")
PY
