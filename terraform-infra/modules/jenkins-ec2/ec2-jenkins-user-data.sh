#!/bin/bash
set -Eeuo pipefail
umask 022

# ============================================================
# JENKINS EC2 BOOTSTRAP
# OS: Ubuntu 26.04 LTS
# Tools: Java 21, Jenkins, Docker, AWS CLI v2,
#        kubectl, Helm, Terraform, Git
# ============================================================

LOG_FILE="/var/log/user-data-setup.log"
exec > >(tee -a "$LOG_FILE") 2>&1

trap 'rc=$?; echo "ERROR: Bootstrap failed at line ${LINENO} (exit ${rc}). Check ${LOG_FILE} and cloud-init logs."; exit "$rc"' ERR

if [[ "$EUID" -ne 0 ]]; then
    echo "ERROR: This script must run as root."
    exit 1
fi

export DEBIAN_FRONTEND=noninteractive

echo "============================================================"
echo "Starting Jenkins EC2 provisioning: $(date -Is)"
echo "============================================================"

# ------------------------------------------------------------
# 1. SYSTEM PREREQUISITES
# ------------------------------------------------------------

apt-get update

apt-get install -y \
    ca-certificates \
    curl \
    gnupg \
    unzip \
    git \
    wget \
    fontconfig \
    openjdk-21-jre

ARCH="$(dpkg --print-architecture)"

case "$ARCH" in
    amd64)
        K8S_ARCH="amd64"
        AWS_ARCH="x86_64"
        ;;
    arm64)
        K8S_ARCH="arm64"
        AWS_ARCH="aarch64"
        ;;
    *)
        echo "ERROR: Unsupported architecture: $ARCH"
        exit 1
        ;;
esac

. /etc/os-release

CODENAME="${UBUNTU_CODENAME:-$VERSION_CODENAME}"

if [[ "$ID" != "ubuntu" || "$VERSION_ID" != "26.04" ]]; then
    echo "ERROR: This script targets Ubuntu 26.04 LTS."
    exit 1
fi

# ------------------------------------------------------------
# 2. DOCKER OFFICIAL APT REPOSITORY
# ------------------------------------------------------------

install -m 0755 -d /etc/apt/keyrings

curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
    -o /etc/apt/keyrings/docker.asc

chmod 0644 /etc/apt/keyrings/docker.asc

cat > /etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: ${CODENAME}
Components: stable
Architectures: ${ARCH}
Signed-By: /etc/apt/keyrings/docker.asc
EOF

apt-get update

apt-get install -y \
    docker-ce \
    docker-ce-cli \
    containerd.io \
    docker-buildx-plugin \
    docker-compose-plugin

systemctl enable --now docker

# ------------------------------------------------------------
# 3. JENKINS OFFICIAL APT REPOSITORY
# ------------------------------------------------------------

curl -fsSL \
    https://pkg.jenkins.io/debian-stable/jenkins.io-2026.key \
    -o /etc/apt/keyrings/jenkins-keyring.asc

chmod 0644 /etc/apt/keyrings/jenkins-keyring.asc

echo "deb [signed-by=/etc/apt/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/" \
    > /etc/apt/sources.list.d/jenkins.list

apt-get update
apt-get install -y jenkins

# Allow Jenkins to access Docker through the docker group.
# Docker group membership is highly privileged.
usermod -aG docker jenkins

# ------------------------------------------------------------
# 4. AWS CLI V2
# ------------------------------------------------------------

curl -fsSL \
    "https://awscli.amazonaws.com/awscli-exe-linux-${AWS_ARCH}.zip" \
    -o /tmp/awscliv2.zip

unzip -q /tmp/awscliv2.zip -d /tmp

if [[ -x /usr/local/aws-cli/v2/current/bin/aws ]]; then
    /tmp/aws/install --update
else
    /tmp/aws/install
fi

rm -rf /tmp/aws /tmp/awscliv2.zip

# ------------------------------------------------------------
# 5. KUBECTL
# ------------------------------------------------------------

# For production, set KUBECTL_VERSION explicitly to a release
# compatible with your EKS/Kubernetes cluster.
KUBECTL_VERSION="${KUBECTL_VERSION:-$(curl -fsSL \
    https://dl.k8s.io/release/stable.txt)}"

if [[ ! "$KUBECTL_VERSION" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "ERROR: Invalid kubectl version: $KUBECTL_VERSION"
    exit 1
fi

curl -fsSL \
    "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/${K8S_ARCH}/kubectl" \
    -o /tmp/kubectl

curl -fsSL \
    "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/${K8S_ARCH}/kubectl.sha256" \
    -o /tmp/kubectl.sha256

(
    cd /tmp
    sha256sum --check kubectl.sha256
)

install -o root -g root -m 0755 \
    /tmp/kubectl /usr/local/bin/kubectl

rm -f /tmp/kubectl /tmp/kubectl.sha256

# ------------------------------------------------------------
# 6. HELM OFFICIAL APT REPOSITORY
# ------------------------------------------------------------

curl -fsSL https://baltocdn.com/helm/signing.asc \
    -o /etc/apt/keyrings/helm.asc

chmod 0644 /etc/apt/keyrings/helm.asc

cat > /etc/apt/sources.list.d/helm-stable-debian.list <<'EOF'
deb [arch=amd64,arm64 signed-by=/etc/apt/keyrings/helm.asc] https://baltocdn.com/helm/stable/debian/ all main
EOF

apt-get update
apt-get install -y helm

# ------------------------------------------------------------
# 7. TERRAFORM OFFICIAL APT REPOSITORY
# ------------------------------------------------------------

curl -fsSL https://apt.releases.hashicorp.com/gpg \
    | gpg --dearmor --yes \
        -o /usr/share/keyrings/hashicorp-archive-keyring.gpg

chmod 0644 /usr/share/keyrings/hashicorp-archive-keyring.gpg

cat > /etc/apt/sources.list.d/hashicorp.list <<EOF
deb [arch=${ARCH} signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com ${CODENAME} main
EOF

apt-get update
apt-get install -y terraform

# ------------------------------------------------------------
# 8. ENABLE AND RESTART SERVICES
# ------------------------------------------------------------

systemctl enable docker
systemctl enable jenkins

# Restart after Docker installation and Jenkins group membership.
systemctl restart docker
systemctl restart jenkins

# ------------------------------------------------------------
# 9. VERIFY INSTALLATIONS AND SERVICE HEALTH
# ------------------------------------------------------------

echo "========== Installed Versions =========="

java -version
git --version
docker --version
docker compose version
aws --version
kubectl version --client
helm version --short
terraform version
jenkins --version

echo "========== Service Status =========="

systemctl is-active docker
systemctl is-active jenkins

echo "========== Jenkins Initial Setup =========="

echo "Retrieve the initial administrator password using:"
echo "sudo cat /var/lib/jenkins/secrets/initialAdminPassword"

echo "============================================================"
echo "Jenkins EC2 provisioning completed: $(date -Is)"
echo "============================================================"
