# Script written with local LLM and human-proofreaded.
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }

apt-get update --fix-missing

# Essential CLI packages (not in default Debian minimal install)
apt-get install -y \
    git htop sysstat tree bind9-dnsutils jq unzip \
    lsb-release software-properties-common

# Disable DE
systemctl set-default multi-user.target 2>/dev/null || true

# Add Docker's official GPG key
log_info "Adding Docker GPG key..."
apt-get install -y ca-certificates curl
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources
tee /etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://download.docker.com/linux/debian
Suites: $(. /etc/os-release && echo "$VERSION_CODENAME")
Components: stable
Architectures: $(dpkg --print-architecture)
Signed-By: /etc/apt/keyrings/docker.asc
EOF

# Refresh index so apt finds docker-ce
apt-get update

# Install Docker
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Add real user to docker group
TARGET_USER="${SUDO_USER:-$(whoami)}"
usermod -aG docker "$TARGET_USER" 2>/dev/null || true

# Configure Docker daemon
mkdir -p /etc/docker
cat > /etc/docker/daemon.json <<'EOF'
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": { "max-size": "100m", "max-file": "3" },
  "storage-driver": "overlay2"
}
EOF

systemctl restart docker


# Install Tailscale
log_info "Installing Tailscale..."
curl -fsSL https://tailscale.com/install.sh | sh

# Install TLDR
log_info "Installing TLDR..."
apt-get install -y pipx
pipx install tldr
pipx ensurepath
