FROM docker.io/antmelekhin/docker-systemd:fedora-43@sha256:4d6f339a3e62a6d94a6da312bb6cbaf6317f0dd6e39ea7f115c5ccf33ef777e3

# Install dependencies
RUN dnf install -y --setopt=install_weak_deps=False openssh-server rsync \
    && dnf clean all

# Create deploy user with sudo access
RUN useradd -m -s /bin/bash fedora && \
    echo 'fedora:fedora' | chpasswd && \
    echo 'fedora ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/fedora && \
    usermod -aG systemd-journal,adm fedora

# Prepare SSH directory
RUN mkdir -p /home/fedora/.ssh && \
    chmod 700 /home/fedora/.ssh && \
    chown -R fedora:fedora /home/fedora/.ssh

# Enable SSH and the system D-Bus socket used by systemctl over SSH
RUN systemctl enable sshd dbus.socket
