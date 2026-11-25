# Test plan and acceptance criteria

The goal is to collect reproducible evidence for the major delivery-platform controls.

| ID | Scenario | Execution | Expected result | Evidence |
|---|---|---|---|---|
| T-01 | Clean image build | Trigger Jenkins on an application commit | BuildKit exports OCI image successfully | Jenkins console log |
| T-02 | Critical vulnerability gate | Use a test image with a known CRITICAL finding in an isolated branch | Trivy exits non-zero and pipeline stops before publication | Trivy report and failed stage |
| T-03 | SBOM generation | Complete a successful CI build | CycloneDX JSON exists and is archived | `sbom.cdx.json` |
| T-04 | Image signature | Complete a successful CI build | Cosign verifies image digest with trusted public key | `cosign verify` output |
| T-05 | SBOM attestation | Complete a successful CI build | Cosign verifies CycloneDX attestation | `cosign verify-attestation` output |
| T-06 | GitOps update | Complete a successful CI build | Jenkins commits image digest to the GitOps overlay | GitHub commit and Argo CD Sync status |
| T-07 | Non-root policy | Run `tests/run-admission-tests.sh` | Kyverno denies unrestricted/root Pod | Admission error output |
| T-08 | Unsigned-image policy | Run `tests/run-admission-tests.sh` | Kyverno denies unsigned local image | Admission error output |
| T-09 | Healthy rollout | Deploy a normal application change | Canary analysis passes and new ReplicaSet is promoted | Rollout status and AnalysisRun |
| T-10 | Failed canary | Run `scripts/demo-bad-rollout.sh` | Prometheus sees 503s; Argo Rollouts aborts canary; stable ReplicaSet stays active | AnalysisRun, Prometheus query and stable HTTP response |
| T-11 | Recovery | Run `scripts/restore-healthy-release.sh` | Jenkins builds corrected image and Argo CD syncs a healthy digest | Jenkins run, GitOps commit and rollout status |

## Lab completion criteria

The lab is validated when T-01, T-03 through T-11 pass. T-02 is a controlled negative test and should be run with an intentionally vulnerable image on a separate test branch; do not intentionally weaken the main application base image just to force the gate to fail.

For portfolio evidence, capture the full Jenkins pipeline, a Trivy JSON report, CycloneDX SBOM, Cosign verification, Kyverno denial messages, Argo CD sync status, Argo Rollouts canary/abort state, Prometheus 503 query and the stable application's successful response during the abort.
