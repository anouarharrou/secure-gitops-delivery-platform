# Lab Requirements — Fedora Linux

This lab targets **Fedora Workstation 44 x86_64** and uses Docker Engine as the container runtime for both Docker Compose and Kind. Follow these steps on a fresh Fedora workstation; skip packages you already have.

> Use this guide to prepare your host before following the setup sequence in the [main README](../README.md).

## 1. Hardware and operating-system requirements

| Resource | Minimum | Recommended |
|---|---:|---:|
| OS | Fedora 42+ x86_64 | Fedora Workstation 44 x86_64 |
| CPU | 4 logical cores | 8 logical cores |
| RAM | 12 GB | 16–24 GB |
| Free disk | 25 GB | 40–50 GB SSD |
| Network | Internet during setup | Broadband; images and Helm charts are downloaded once |

The lab runs Jenkins, BuildKit, a registry, a three-node Kind cluster, Argo CD, Kyverno, Argo Rollouts, Prometheus and Grafana. On a 24 GB machine, avoid running other memory-heavy clusters at the same time.

## 2. Install host utilities

```bash
sudo dnf install -y \
  git curl wget jq python3 openssl tar gzip unzip \
  findutils coreutils util-linux ca-certificates
```

## 3. Install Docker Engine and Compose plugin

The lab uses Docker Engine, not Podman, because the Kind helper script needs Docker networks and `docker exec` to configure the Kind nodes.

```bash
sudo dnf install -y dnf-plugins-core
sudo dnf config-manager addrepo --from-repofile=https://download.docker.com/linux/fedora/docker-ce.repo
sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo systemctl enable --now docker
```

Add your login user to the Docker group so the scripts can use Docker without `sudo`:

```bash
sudo usermod -aG docker "$USER"
```

**Log out of the desktop session and log back in** before continuing. Then verify:

```bash
docker version
docker compose version
docker info
```

The Docker group grants root-equivalent control of the host. This is a workstation lab convenience, not a least-privilege production pattern.

If Docker CE is already installed and running, do not reinstall it. Confirm that `docker compose` works and that your user can run `docker info`.

## 4. Install kubectl for Kubernetes 1.37

```bash
sudo tee /etc/yum.repos.d/kubernetes.repo >/dev/null <<'REPO'
[kubernetes]
name=Kubernetes
baseurl=https://pkgs.k8s.io/core:/stable:/v1.37/rpm/
enabled=1
gpgcheck=1
gpgkey=https://pkgs.k8s.io/core:/stable:/v1.37/rpm/repodata/repomd.xml.key
REPO

sudo dnf install -y kubectl
kubectl version --client
```

The Kind node image is pinned to Kubernetes `v1.37.0`; using a `kubectl` client within one minor version is recommended.

## 5. Install Kind v0.33.0

```bash
curl -fsSLo /tmp/kind https://kind.sigs.k8s.io/dl/v0.33.0/kind-linux-amd64
chmod +x /tmp/kind
sudo install -m 0755 /tmp/kind /usr/local/bin/kind
kind version
```

## 6. Install Helm 3

The lab uses Helm to install Kyverno and the Prometheus community chart. Install the current Helm 3 release using the upstream installer:

```bash
curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
helm version
```

## 7. Install the Argo Rollouts kubectl plugin

The controller is installed in-cluster by the lab script. The CLI plugin is only needed for the more readable `kubectl argo rollouts` commands.

```bash
curl -fsSLo /tmp/kubectl-argo-rollouts \
  https://github.com/argoproj/argo-rollouts/releases/download/v1.10.2/kubectl-argo-rollouts-linux-amd64
sudo install -m 0755 /tmp/kubectl-argo-rollouts /usr/local/bin/kubectl-argo-rollouts
kubectl argo rollouts version
```

## 8. Install Cosign on the Fedora host

Cosign also exists inside the Jenkins build image, but the host binary is used to generate the signing key pair locally with `scripts/init-cosign-keys.sh`.

```bash
curl -fsSLo /tmp/cosign \
  https://github.com/sigstore/cosign/releases/download/v3.1.4/cosign-linux-amd64
sudo install -m 0755 /tmp/cosign /usr/local/bin/cosign
cosign version
```

Trivy, Syft, BuildKit client and Skopeo are installed in the custom Jenkins image. They do not need to be installed separately on Fedora.

## 9. Verify all host prerequisites

From the repository root:

```bash
./scripts/check-prereqs.sh
```

The script checks Docker, Docker Compose, kubectl, Kind, Helm, Git, curl, Python, OpenSSL and jq.

## 10. Network and cost expectations

- The lab requires internet access during initial setup to download container images, Helm charts, release binaries, the GitHub source repository and the Trivy vulnerability database.
- GitHub is the remote source-control service. Use a public fork for the simplest Argo CD setup. A free GitHub account is sufficient for this lab.
- CI execution is local in Jenkins. No GitHub-hosted runner minutes are used.
- Kubernetes, registry, monitoring and build services run locally. No AWS, cloud cluster, hosted registry, paid tunnel or paid SaaS is required.
- The local registry uses plain HTTP and is bound to `127.0.0.1` on the Fedora host. Do not expose port 5000 to a LAN or the internet.

## 11. Fedora troubleshooting notes

### Docker permission denied

Log out and back in after `usermod -aG docker`. Confirm with `id -nG` and `docker info`.

### Port already in use

Jenkins defaults to `127.0.0.1:8080`; the registry defaults to `127.0.0.1:5000`. Edit `.env` before starting Compose if either port is occupied.

### SELinux / rootless BuildKit

This repository uses named Docker volumes for Jenkins, BuildKit and registry data. It avoids mounting the Docker socket into Jenkins and avoids writable host-path mounts, reducing SELinux friction. Keep SELinux enforcing. The BuildKit service uses a rootless image with the container security options documented by the BuildKit project; it is not run with `--privileged`. If BuildKit reports user-namespace or mount permission errors, inspect `docker compose logs buildkitd` and verify the Fedora kernel allows unprivileged user namespaces before changing host security settings.

### Docker Compose cannot pull images

Check DNS/connectivity, `docker info`, and disk space. `docker compose pull` can be used to retry image downloads.
