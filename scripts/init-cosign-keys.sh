#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
KEY_DIR="$ROOT/security/cosign"
ROTATE=false

if [[ "${1:-}" == "--rotate" && $# -eq 1 ]]; then
  ROTATE=true
elif [[ $# -ne 0 ]]; then
  echo "Usage: $0 [--rotate]" >&2
  exit 2
fi

mkdir -p "$KEY_DIR"
if [[ "$ROTATE" != true && ( -e "$KEY_DIR/cosign.key" || -e "$KEY_DIR/cosign.pub" ) ]]; then
  echo "A Cosign key file already exists under $KEY_DIR." >&2
  echo "Use --rotate only when you intend to replace the signing identity." >&2
  exit 1
fi

command -v cosign >/dev/null 2>&1 || {
  echo "Cosign is required. Install the pinned host version from docs/requirements.md." >&2
  exit 1
}

read -r -s -p "Choose a strong passphrase for the Cosign private key: " COSIGN_PASSWORD
echo
if [[ -z "$COSIGN_PASSWORD" ]]; then
  echo "The passphrase cannot be empty." >&2
  exit 1
fi
export COSIGN_PASSWORD

umask 077
TEMP_DIR="$(mktemp -d "$KEY_DIR/.cosign-init.XXXXXX")"
cleanup() {
  unset COSIGN_PASSWORD
  rm -rf "$TEMP_DIR"
}
trap cleanup EXIT

(cd "$TEMP_DIR" && cosign generate-key-pair)
chmod 0600 "$TEMP_DIR/cosign.key"
chmod 0644 "$TEMP_DIR/cosign.pub"
mv -f "$TEMP_DIR/cosign.key" "$KEY_DIR/cosign.key"
mv -f "$TEMP_DIR/cosign.pub" "$KEY_DIR/cosign.pub"

echo "Generated a local Cosign key pair in $KEY_DIR."
echo "Private key: security/cosign/cosign.key (gitignored; keep it private)."
echo "Public key:  security/cosign/cosign.pub (commit this for Kyverno)."
echo "Provision the private key and passphrase in Jenkins credentials, then apply the Kyverno policy."
