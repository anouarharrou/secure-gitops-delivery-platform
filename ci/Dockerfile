ARG JENKINS_IMAGE=jenkins/jenkins:2.591-jdk21
FROM ${JENKINS_IMAGE}

USER root
ARG TRIVY_VERSION=0.76.2
ARG SYFT_VERSION=1.57.1
ARG COSIGN_VERSION=3.1.4
ARG BUILDKIT_VERSION=0.35.0

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
       bash ca-certificates curl git jq python3 skopeo tar gzip \
    && rm -rf /var/lib/apt/lists/*

# Trivy image/config scanner.
RUN curl -fsSL "https://github.com/aquasecurity/trivy/releases/download/v${TRIVY_VERSION}/trivy_${TRIVY_VERSION}_Linux-64bit.tar.gz" \
    | tar -xz -C /usr/local/bin trivy

# Syft SBOM generator.
RUN curl -fsSL "https://github.com/anchore/syft/releases/download/v${SYFT_VERSION}/syft_${SYFT_VERSION}_linux_amd64.tar.gz" \
    | tar -xz -C /usr/local/bin syft

# Cosign image signer (key-pair mode; no transparency-log upload in this local lab).
RUN curl -fsSL "https://github.com/sigstore/cosign/releases/download/v${COSIGN_VERSION}/cosign-linux-amd64" \
    -o /usr/local/bin/cosign \
    && chmod 0755 /usr/local/bin/cosign

# BuildKit client only. The daemon runs separately as a rootless container.
RUN curl -fsSL "https://github.com/moby/buildkit/releases/download/v${BUILDKIT_VERSION}/buildkit-v${BUILDKIT_VERSION}.linux-amd64.tar.gz" \
    | tar -xz -C /usr/local/bin --strip-components=1 bin/buildctl

COPY ci/plugins.txt /usr/share/jenkins/ref/plugins.txt
RUN jenkins-plugin-cli --plugin-file /usr/share/jenkins/ref/plugins.txt

USER jenkins
