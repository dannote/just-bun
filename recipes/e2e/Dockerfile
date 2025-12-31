FROM docker.io/jrei/systemd-fedora:latest

# Install dependencies
RUN dnf install -y openssh-server sudo rsync curl git && dnf clean all

# Create deploy user with sudo access
RUN useradd -m -s /bin/bash fedora && \
    echo 'fedora:fedora' | chpasswd && \
    echo 'fedora ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/fedora && \
    usermod -aG systemd-journal,adm fedora

# Prepare SSH directory
RUN mkdir -p /home/fedora/.ssh && \
    chmod 700 /home/fedora/.ssh && \
    chown -R fedora:fedora /home/fedora/.ssh

# Enable SSH
RUN systemctl enable sshd
