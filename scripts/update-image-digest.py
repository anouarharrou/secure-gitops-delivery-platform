#!/usr/bin/env python3
"""Update the digest entry for the demo-app Kustomize image transformer."""
from pathlib import Path
import re
import sys

if len(sys.argv) != 2:
    raise SystemExit("Usage: update-image-digest.py sha256:<64-hex-digits>")

digest = sys.argv[1]
if not re.fullmatch(r"sha256:[a-f0-9]{64}", digest):
    raise SystemExit("Refusing invalid image digest")

path = Path(__file__).resolve().parents[1] / "gitops/overlays/local/kustomization.yaml"
text = path.read_text()
pattern = r"(?m)^(\s*digest:\s*)sha256:[a-f0-9]{64}\s*$"
updated, count = re.subn(pattern, lambda m: m.group(1) + digest, text, count=1)
if count != 1:
    raise SystemExit(f"Expected exactly one digest entry in {path}")
path.write_text(updated)
print(f"Updated Kustomize image digest to {digest}")
