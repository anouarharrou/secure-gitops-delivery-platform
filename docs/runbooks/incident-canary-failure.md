# Runbook: failed canary release

## Symptoms

- Argo Rollouts shows `Degraded` or `Progressing` with an aborted analysis.
- Prometheus query `sum(increase(app_http_requests_total{status="503"}[2m])) or vector(0)` returns a value greater than zero.
- The stable ReplicaSet should continue serving the stable Service.

## Triage

```bash
kubectl get rollout delivery-demo -n delivery-demo -o wide
kubectl describe rollout delivery-demo -n delivery-demo
kubectl get rs,pods -n delivery-demo -o wide
kubectl logs deploy/delivery-demo-load-generator -n delivery-demo --tail=30
kubectl get analysisruns -n delivery-demo
```

## Confirm user-facing availability

```bash
kubectl port-forward -n delivery-demo svc/delivery-demo-stable 8088:8080
curl -i http://127.0.0.1:8088/
```

## Recovery

1. Do not manually delete the stable ReplicaSet.
2. Inspect the failing image digest and SBOM in the Jenkins build artifacts.
3. Remove `application/fault-injection.enabled` (or fix the application), commit and push to GitHub.
4. Jenkins builds/signs the corrected image and updates the GitOps digest.
5. Argo CD syncs the digest. Observe the next rollout and verify Prometheus analysis passes.

## Evidence to capture

- Jenkins failed/green build and scan artifacts.
- Argo Rollout status and AnalysisRun.
- Prometheus query result before and after recovery.
- Stable Service HTTP response during the aborted canary.
