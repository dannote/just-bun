import "../colors.just"

e2e_dir := source_directory()
image_name := "just-bun-e2e"
container_name := "just-bun-e2e"
s3_container := "just-bun-s3"
ssh_port := env("E2E_SSH_PORT", "2222")
s3_port := env("E2E_S3_PORT", "9000")
ssh_opts := "-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"
ssh_key_path := e2e_dir + "/id_ed25519"

# Build the e2e test image (run once)
build:
  #!/usr/bin/env bash
  set -euo pipefail
  echo "{{ACCENT}}Building e2e image...{{RESET}}"
  docker build -t {{image_name}} -f "{{e2e_dir}}/Dockerfile" "{{e2e_dir}}"
  echo "{{SUCCESS}}Image built{{RESET}}"

# Start container with systemd
start:
  #!/usr/bin/env bash
  set -euo pipefail

  if docker ps --format '{{{{.Names}}' | grep -q "^{{container_name}}$"; then
    echo "{{SUCCESS}}Container already running{{RESET}}"
    exit 0
  fi

  # Build image if not exists
  if ! docker image inspect {{image_name}} &>/dev/null; then
    just e2e vm build
  fi

  # Create network if not exists
  docker network create e2e-net 2>/dev/null || true

  # Remove old container if exists
  docker rm -f {{container_name}} 2>/dev/null || true

  echo "{{ACCENT}}Starting container...{{RESET}}"

  docker run -d \
    --name {{container_name}} \
    --hostname e2e-test \
    --network e2e-net \
    --privileged \
    --cgroupns=host \
    -v /sys/fs/cgroup:/sys/fs/cgroup:rw \
    -p {{ssh_port}}:22 \
    {{image_name}} \
    /usr/lib/systemd/systemd

  echo "{{SUCCESS}}Container started{{RESET}}"

# Start S3 server (MinIO) for Litestream tests
start-s3:
  #!/usr/bin/env bash
  set -euo pipefail

  if docker ps --format '{{{{.Names}}' | grep -q "^{{s3_container}}$"; then
    echo "{{SUCCESS}}S3 container already running{{RESET}}"
    exit 0
  fi

  # Create network if not exists
  docker network create e2e-net 2>/dev/null || true

  # Remove old container if exists
  docker rm -f {{s3_container}} 2>/dev/null || true

  echo "{{ACCENT}}Starting S3 server (MinIO)...{{RESET}}"

  docker run -d \
    --name {{s3_container}} \
    --network e2e-net \
    -p {{s3_port}}:9000 \
    -e MINIO_ROOT_USER=minioadmin \
    -e MINIO_ROOT_PASSWORD=minioadmin \
    minio/minio:latest \
    server /data

  # Wait for S3 to be ready
  for i in {1..30}; do
    if curl -sf http://localhost:{{s3_port}}/minio/health/live >/dev/null 2>&1; then
      echo "{{SUCCESS}}S3 server ready{{RESET}}"
      exit 0
    fi
    sleep 1
  done

  echo "{{ERROR}}S3 server timeout{{RESET}}"
  docker logs {{s3_container}} 2>&1 | tail -10
  exit 1

# Stop S3 container
stop-s3:
  #!/usr/bin/env bash
  docker rm -f {{s3_container}} 2>/dev/null || true
  docker volume rm e2e-s3-data 2>/dev/null || true

# Wait for SSH to be ready
wait:
  #!/usr/bin/env bash
  set -euo pipefail

  echo "{{ACCENT}}Waiting for SSH...{{RESET}}"

  # Generate SSH key if needed
  if [ ! -f "{{ssh_key_path}}" ]; then
    ssh-keygen -t ed25519 -f "{{ssh_key_path}}" -N "" -C "e2e-test"
  fi

  # Wait for systemd then copy SSH key
  for i in {1..30}; do
    if docker exec {{container_name}} systemctl is-system-running 2>/dev/null | grep -qE "running|degraded"; then
      break
    fi
    sleep 1
  done

  # Unlock user and copy SSH key
  docker exec {{container_name}} passwd -u fedora 2>/dev/null || true
  docker exec {{container_name}} rm -f /run/nologin /etc/nologin 2>/dev/null || true
  docker cp "{{ssh_key_path}}.pub" {{container_name}}:/home/fedora/.ssh/authorized_keys
  docker exec {{container_name}} chown fedora:fedora /home/fedora/.ssh/authorized_keys
  docker exec {{container_name}} chmod 600 /home/fedora/.ssh/authorized_keys

  # Wait for SSH connection
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

  # Also stop S3 if running
  docker rm -f {{s3_container}} 2>/dev/null || true

  # Remove network if empty
  docker network rm e2e-net 2>/dev/null || true

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
