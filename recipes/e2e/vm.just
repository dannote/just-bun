import "../colors.just"

e2e_dir := invocation_directory() + "/recipes/e2e"
container_name := "just-bun-e2e"
ssh_port := env("E2E_SSH_PORT", "2222")
ssh_opts := "-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"
ssh_key_path := e2e_dir + "/id_ed25519"

# Start container with systemd
start:
  #!/usr/bin/env bash
  set -euo pipefail

  if docker ps --format '{{{{.Names}}' | grep -q "^{{container_name}}$"; then
    echo "{{SUCCESS}}Container already running{{RESET}}"
    exit 0
  fi

  # Remove old container if exists
  docker rm -f {{container_name}} 2>/dev/null || true

  echo "{{ACCENT}}Starting systemd container...{{RESET}}"

  docker run -d \
    --name {{container_name}} \
    --hostname e2e-test \
    --privileged \
    --cgroupns=host \
    -v /sys/fs/cgroup:/sys/fs/cgroup:rw \
    -p {{ssh_port}}:22 \
    docker.io/jrei/systemd-fedora:latest \
    /usr/lib/systemd/systemd

  echo "{{SUCCESS}}Container started{{RESET}}"

# Wait for systemd and SSH to be ready
wait:
  #!/usr/bin/env bash
  set -euo pipefail

  echo "{{ACCENT}}Waiting for systemd...{{RESET}}"

  # Wait for systemd to be ready
  for i in {1..30}; do
    if docker exec {{container_name}} systemctl is-system-running 2>/dev/null | grep -qE "running|degraded"; then
      break
    fi
    sleep 1
  done

  # Install SSH, rsync, and curl
  echo "{{ACCENT}}Installing dependencies...{{RESET}}"
  docker exec {{container_name}} dnf install -y openssh-server sudo rsync curl > /dev/null
  docker exec {{container_name}} systemctl enable --now sshd

  # Create deploy user with sudo access and password
  docker exec {{container_name}} useradd -m -s /bin/bash fedora 2>/dev/null || true
  docker exec {{container_name}} bash -c "echo 'fedora:fedora' | chpasswd"
  docker exec {{container_name}} passwd -u fedora
  docker exec {{container_name}} bash -c "echo 'fedora ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/fedora"
  docker exec {{container_name}} usermod -aG systemd-journal,adm fedora

  # Remove nologin if present (blocks login during boot)
  docker exec {{container_name}} rm -f /run/nologin /etc/nologin 2>/dev/null || true

  # Setup SSH key auth
  docker exec {{container_name}} mkdir -p /home/fedora/.ssh
  docker exec {{container_name}} chmod 700 /home/fedora/.ssh

  # Generate and install SSH key
  if [ ! -f "{{ssh_key_path}}" ]; then
    ssh-keygen -t ed25519 -f "{{ssh_key_path}}" -N "" -C "e2e-test"
  fi

  docker cp "{{ssh_key_path}}.pub" {{container_name}}:/home/fedora/.ssh/authorized_keys
  docker exec {{container_name}} chown -R fedora:fedora /home/fedora/.ssh
  docker exec {{container_name}} chmod 600 /home/fedora/.ssh/authorized_keys

  # Wait for SSH
  echo "{{ACCENT}}Waiting for SSH...{{RESET}}"
  for i in {1..30}; do
    if ssh -q {{ssh_opts}} -o ConnectTimeout=2 \
         -i "{{ssh_key_path}}" -p {{ssh_port}} fedora@localhost exit 2>/dev/null; then
      echo "{{SUCCESS}}SSH ready{{RESET}}"
      exit 0
    fi
    sleep 1
  done

  echo "{{ERROR}}SSH timeout{{RESET}}"
  exit 1

# Stop and remove container
stop:
  #!/usr/bin/env bash
  set -euo pipefail

  if docker ps -a --format '{{{{.Names}}' | grep -q "^{{container_name}}$"; then
    echo "{{ACCENT}}Stopping container...{{RESET}}"
    docker rm -f {{container_name}}
    echo "{{SUCCESS}}Container stopped{{RESET}}"
  else
    echo "{{WARNING}}Container not running{{RESET}}"
  fi

# Full lifecycle: start and wait
up: start wait

# Alias for stop
down: stop

# Show container status
status:
  #!/usr/bin/env bash
  if docker ps --format '{{{{.Names}}' | grep -q "^{{container_name}}$"; then
    echo "{{SUCCESS}}Container running{{RESET}}"
    docker ps --filter name={{container_name}} --format "table {{{{.Names}}\t{{{{.Status}}\t{{{{.Ports}}"
  else
    echo "{{WARNING}}Container not running{{RESET}}"
  fi

# SSH into the container
ssh *args:
  ssh {{ssh_opts}} -i "{{ssh_key_path}}" -p {{ssh_port}} fedora@localhost {{args}}

# Execute command in container directly
exec *args:
  docker exec -it {{container_name}} {{args}}
