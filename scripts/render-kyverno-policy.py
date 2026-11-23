#!/usr/bin/env python3
"""Render the Kyverno image-verification policy with the lab's Cosign public key."""
from pathlib import Path
import sys

root = Path(__file__).resolve().parents[1]
key_file = root / "security/cosign/cosign.pub"
template_file = root / "security/policies/verify-images.yaml.tpl"
out_file = root / "security/policies/verify-images.yaml"

if not key_file.exists():
    raise SystemExit("Missing security/cosign/cosign.pub. Generate a Cosign key pair first; see README.md.")
public_key = key_file.read_text().strip()
if "BEGIN PUBLIC KEY" not in public_key or "END PUBLIC KEY" not in public_key:
    raise SystemExit("The public key file does not look like a PEM-encoded Cosign public key.")

template = template_file.read_text()
rendered = template.replace("__COSIGN_PUBLIC_KEY__", public_key.replace("\n", "\n          "))
out_file.write_text(rendered)
print(f"Rendered {out_file}")
