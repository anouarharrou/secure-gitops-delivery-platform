# Architecture and design decisions

## System boundary

GitHub is the remote source-control system. It is the only mandatory hosted service in this POC. Jenkins, BuildKit, the OCI registry, Kind, Argo CD, Kyverno, Argo Rollouts, Prometheus and Grafana run locally.

The Jenkins service polls GitHub every two minutes. No public webhook, reverse proxy, tunnel, hosted CI runner or cloud cluster is required. GitHub is used as SCM, not as the CI execution environment.

## Delivery flow

```mermaid
flowchart LR
  Dev[Developer] --> GH[GitHub repository]
  GH -->|SCM polling| J[Jenkins on Fedora]
  J --> BK[Rootless BuildKit]
  BK --> OCI[OCI archive]
  OCI --> TV[Trivy scan]
  OCI --> SBOM[Syft SBOM]
  TV --> REG[Local OCI registry]
  SBOM --> REG
  REG --> SIGN[Cosign signature + SBOM attestation]
  SIGN --> J
  J -->|commit immutable digest| GH
  GH -->|GitOps source| CD[Argo CD]
  CD --> KY[Kyverno admission]
  KY --> RO[Argo Rollouts]
  RO --> K[Kind Kubernetes cluster]
  K --> APP[Demo application]
  APP --> PM[Prometheus]
  PM --> ANA[Rollout analysis]
  ANA -->|promote or abort| RO
  PM --> GF[Grafana]
```

## Trust boundaries

- GitHub repository contents are trusted only after pipeline checks.
- Jenkins is allowed to write a single image digest to the GitOps overlay. It does not use `kubectl` and does not have a Kubernetes service-account token.
- The BuildKit daemon is rootless and reachable only on the private Docker Compose network.
- The OCI registry is HTTP because it is a private local lab service. It is bound to `127.0.0.1` on the host and is never published externally.
- Cosign uses a locally generated key pair. The private key is stored as a Jenkins Secret File credential and is not committed.
- Kyverno verifies image signatures using only the public key. The local HTTP registry exception is enabled only for this lab.
- Argo CD reads desired state from GitHub and reconciles Kubernetes. It is the only component responsible for applying GitOps resources.

## Progressive-delivery behavior

The Rollout uses replica-based canary progression (25%, then 50%, then 100%). It does not claim exact HTTP traffic splitting. The canary Service is targeted by a small in-cluster load generator. Prometheus counts HTTP 503 responses and Argo Rollouts evaluates the count at each analysis step. If analysis fails, the rollout aborts and the prior stable ReplicaSet remains the serving version. Git remains the desired-state source; after investigating a failed release, push a healthy commit to build and publish a corrected digest.

## Local-only caveats

The registry uses HTTP and Kyverno is configured with `--allowInsecureRegistry`. This is intentionally restricted to the loopback-only lab registry. Do not reuse that configuration for production. Likewise, Jenkins is a single local controller with a built-in executor for learning purposes, not a hardened production controller.
