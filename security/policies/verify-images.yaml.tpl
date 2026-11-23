apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: verify-delivery-demo-images
  annotations:
    policies.kyverno.io/title: Verify signed delivery-demo images
    policies.kyverno.io/category: Software Supply Chain Security
    policies.kyverno.io/subject: Pod
    policies.kyverno.io/description: Require a Cosign signature from the lab's trusted public key for delivery-demo images.
spec:
  background: false
  validationFailureAction: Enforce
  failurePolicy: Fail
  rules:
    - name: verify-delivery-demo-image-signature
      match:
        any:
          - resources:
              kinds:
                - Pod
              namespaces:
                - delivery-demo
      verifyImages:
        - imageReferences:
            - "kind-registry:5000/delivery-demo*"
          attestors:
            - count: 1
              entries:
                - keys:
                    publicKeys: |-
                      __COSIGN_PUBLIC_KEY__
          required: true
          verifyDigest: true
          mutateDigest: true
