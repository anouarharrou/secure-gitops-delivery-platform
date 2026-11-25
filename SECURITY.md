# Security policy

This repository is a local learning lab. Do not expose its Jenkins UI, HTTP registry, Grafana or Prometheus endpoints publicly.

## Secrets

- Never commit `security/cosign/cosign.key`, GitHub tokens, Jenkins credentials or `.env` secrets.
- Generate the Cosign key pair locally with `scripts/init-cosign-keys.sh`. The private key is gitignored and is provisioned from that local file to Jenkins as a Secret File credential. Only the matching public key is committed. The pipeline checks that the Jenkins key matches the committed public key before signing.
- Use a fine-grained GitHub token scoped to this repository and grant only `Contents: Read and write` for the demo pipeline.
- Rotate/revoke the token if it is exposed.

## Local registry warning

The registry uses plain HTTP, and Kyverno's `--allowInsecureRegistry` option is enabled to verify local images. This setting is only for the isolated, loopback-bound Kind lab. It is not suitable for production.

## Reporting

For a security issue in the example code or manifests, open a GitHub issue without including credentials, private keys or personal data. For an exposed token or key, revoke/rotate it immediately before reporting.
