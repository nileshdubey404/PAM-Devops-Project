#!/bin/bash
set -Eeuo pipefail

exec > >(tee -a /var/log/user-data-setup.log) 2>&1

echo "Starting EC2 Jenkins setup..."

export DEBIAN_FRONTEND=noninteractive

# 1. Update packages and install prerequisites
apt-get update
apt-get install -y ca-certificates curl gnupg unzip fontconfig openjdk-21-jre

# 2. Install Docker from the official Docker repository
install -m 0755 -d /etc/apt/keyrings

curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
  -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc

. /etc/os-release

cat > /etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: ${UBUNTU_CODENAME:-$VERSION_CODENAME}
Components: stable
Architectures: $(dpkg --print-architecture)
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

# 3. Install Jenkins from the official repository
curl -fsSL https://pkg.jenkins.io/debian/jenkins.io-2026.key \
  -o /etc/apt/keyrings/jenkins-keyring.asc

echo "deb [signed-by=/etc/apt/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian binary/" \
  > /etc/apt/sources.list.d/jenkins.list

apt-get update
apt-get install -y jenkins

# 4. Allow Jenkins to run Docker commands
# Preferred over chmod 777 on the Docker socket
usermod -aG docker jenkins

# 5. Install kubectl for the instance architecture
ARCH="$(dpkg --print-architecture)"

case "$ARCH" in
  amd64) K8S_ARCH="amd64" ;;
  arm64) K8S_ARCH="arm64" ;;
  *)
    echo "Unsupported architecture for kubectl: $ARCH"
    exit 1
    ;;
esac

KUBECTL_VERSION="$(curl -fsSL \
  https://dl.k8s.io/release/stable.txt)"

curl -fsSL \
  "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/${K8S_ARCH}/kubectl" \
  -o /tmp/kubectl

curl -fsSL \
  "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/${K8S_ARCH}/kubectl.sha256" \
  -o /tmp/kubectl.sha256

echo "$(cat /tmp/kubectl.sha256)  /tmp/kubectl" | sha256sum --check

install -o root -g root -m 0755 /tmp/kubectl /usr/local/bin/kubectl
rm -f /tmp/kubectl /tmp/kubectl.sha256

# 6. Install AWS CLI v2
case "$ARCH" in
  amd64) AWS_ARCH="x86_64" ;;
  arm64) AWS_ARCH="aarch64" ;;
esac

curl -fsSL \
  "https://awscli.amazonaws.com/awscli-exe-linux-${AWS_ARCH}.zip" \
  -o /tmp/awscliv2.zip

unzip -q /tmp/awscliv2.zip -d /tmp
/tmp/aws/install --update

rm -rf /tmp/aws /tmp/awscliv2.zip

# 7. Optional lab-only passwordless sudo configuration
# This is intentionally NOT enabled by default.
# See the instructions below if you explicitly need it.

# 8. Start Jenkins after Docker is installed and configured
systemctl enable jenkins
systemctl restart jenkins

# 9. Print installed versions
docker --version
kubectl version --client
aws --version
java -version
systemctl --no-pager --full status jenkins

echo "Jenkins EC2 setup completed."

