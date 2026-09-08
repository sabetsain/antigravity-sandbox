# Universal Containerized Agent Sandbox
# Base: Ubuntu 24.04 LTS (Noble Numbat)
FROM ubuntu:24.04

LABEL maintainer="Antigravity Team"
LABEL description="Universal isolated sandbox environment for Google Antigravity (agy) agents"

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8

# Install foundational utilities and dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    gnupg \
    git \
    openssh-client \
    jq \
    postgresql-client \
    sudo \
    fuse-overlayfs \
    podman \
    uidmap \
    slirp4netns \
    passt \
    build-essential \
    python3 \
    python3-pip \
    python3-venv \
    python3-dev \
    libffi-dev \
    libssl-dev \
    iptables \
    iproute2 \
    procps \
    locales \
    && rm -rf /var/lib/apt/lists/*

# Install Node.js 22.x LTS via NodeSource
RUN mkdir -p /etc/apt/keyrings && \
    curl -fsSL --retry 5 --retry-connrefused --retry-delay 2 https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg && \
    echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_22.x nodistro main" > /etc/apt/sources.list.d/nodesource.list && \
    apt-get update && apt-get install -y --no-install-recommends nodejs && \
    rm -rf /var/lib/apt/lists/*

# Create non-root developer user (UID 1000, GID 1000)
# Ubuntu 24.04 includes a default 'ubuntu' user with UID 1000; remove it if present, then add 'developer'
RUN if id -u ubuntu >/dev/null 2>&1; then \
        userdel -r ubuntu 2>/dev/null || true; \
    fi && \
    groupadd -g 1000 developer 2>/dev/null || true && \
    useradd -u 1000 -g 1000 -m -s /bin/bash -c "Developer User" developer && \
    echo "developer ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/developer && \
    chmod 0440 /etc/sudoers.d/developer

# Configure Rootless Podman & Subuid/Subgid ranges for nested container execution
RUN echo "developer:100000:65536" > /etc/subuid && \
    echo "developer:100000:65536" > /etc/subgid && \
    mkdir -p /etc/containers /run/user/1000 /home/developer/.local/share/containers/storage && \
    chown -R developer:developer /run/user/1000 /home/developer/.local && \
    chmod 700 /run/user/1000

# Write /etc/containers/storage.conf for rootless fuse-overlayfs
RUN cat << 'EOF' > /etc/containers/storage.conf
[storage]
driver = "overlay"
runroot = "/run/user/1000/containers"
graphroot = "/home/developer/.local/share/containers/storage"

[storage.options]
additionalimagestores = []

[storage.options.overlay]
mount_program = "/usr/bin/fuse-overlayfs"
mountopt = "nodev,metacopy=on"
EOF

# Write /etc/containers/containers.conf for nested non-systemd cgroup management
RUN cat << 'EOF' > /etc/containers/containers.conf
[containers]
netns = "bridge"
cgroup_manager = "cgroupfs"
events_logger = "file"
default_capabilities = [
    "CHOWN",
    "DAC_OVERRIDE",
    "FOWNER",
    "FSETID",
    "KILL",
    "NET_BIND_SERVICE",
    "SETFCAP",
    "SETGID",
    "SETPCAP",
    "SETUID",
    "SYS_CHROOT"
]
EOF

# Create symlink /usr/local/bin/docker -> /usr/bin/podman
RUN ln -sf /usr/bin/podman /usr/local/bin/docker

# Install Google Antigravity CLI globally
COPY setup-agy.sh /tmp/setup-agy.sh
RUN bash /tmp/setup-agy.sh && rm -f /tmp/setup-agy.sh


# Setup workspace directory
RUN mkdir -p /workspace && chown -R developer:developer /workspace

# Runtime Environment configuration
USER developer
ENV HOME=/home/developer
ENV USER=developer
ENV XDG_RUNTIME_DIR=/run/user/1000
ENV PATH="/home/developer/.local/bin:/usr/local/bin:${PATH}"

WORKDIR /workspace

# Default command runs agy
CMD ["/usr/local/bin/agy"]

