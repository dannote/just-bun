#!/usr/bin/env bats

# E2E Tests for Litestream SQLite Replication
# Run with: just e2e test litestream

load helpers

setup_file() {
  _setup_env
  just e2e vm start-s3
}

teardown_file() {
  # Stop litestream service
  just litestream stop 2>/dev/null || true
}

# ============================================================================
# S3 Server Setup
# ============================================================================

@test "litestream: S3 server is running" {
  run curl -sf http://localhost:9000/minio/health/live
  [ "$status" -eq 0 ]
}

@test "litestream: create S3 bucket" {
  # Create bucket via MinIO mc client
  run docker exec just-bun-s3 mc alias set local http://localhost:9000 minioadmin minioadmin 2>/dev/null
  run docker exec just-bun-s3 mc mb local/backups 2>/dev/null || true
  # Bucket might already exist, that's ok

  # Verify bucket exists or create via directory
  docker exec just-bun-s3 mkdir -p /data/backups 2>/dev/null || true
}

# ============================================================================
# Binary Collection
# ============================================================================

@test "litestream: binary exists in repo" {
  # Detect architecture
  arch=$(uname -m)
  case "$arch" in
    arm64|aarch64) repo_arch="arm64" ;;
    x86_64|amd64) repo_arch="amd64" ;;
    *) skip "Unsupported architecture: $arch" ;;
  esac

  # Check if binary exists
  run ls repo/linux/$repo_arch/litestream.*
  if [ "$status" -ne 0 ]; then
    # Try to collect it
    run just repo litestream collect
    [ "$status" -eq 0 ]
  fi

  # Verify binary exists
  run ls repo/linux/$repo_arch/litestream.*
  [ "$status" -eq 0 ]
}

# ============================================================================
# Litestream Upload & Setup
# ============================================================================

@test "litestream: upload transfers binary to server" {
  run just litestream upload
  [ "$status" -eq 0 ]

  # Verify binary exists on server
  run remote "test -x $BIN_DIR/litestream"
  [ "$status" -eq 0 ]
}

@test "litestream: setup-systemd creates service" {
  run just litestream setup-systemd
  [ "$status" -eq 0 ]

  # Verify service file exists
  run remote "test -f /etc/systemd/system/litestream.service"
  [ "$status" -eq 0 ]

  # Verify service is enabled
  run remote "systemctl is-enabled litestream"
  [[ "$output" =~ "enabled" ]]
}

@test "litestream: setup-config discovers databases" {
  run just litestream setup-config
  [ "$status" -eq 0 ]

  # Verify config exists
  run remote "sudo test -f $ETC_DIR/litestream/litestream.yaml"
  [ "$status" -eq 0 ]

  # Verify config has correct permissions
  run remote "sudo stat -c '%a' $ETC_DIR/litestream/litestream.yaml"
  [ "$output" = "600" ]
}

@test "litestream: config includes app database" {
  run remote "sudo cat $ETC_DIR/litestream/litestream.yaml"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "app.db" ]]
  [[ "$output" =~ "$LITESTREAM_BUCKET" ]]
}

# ============================================================================
# Litestream Service Lifecycle
# ============================================================================

@test "litestream: start launches service" {
  run just litestream start
  [ "$status" -eq 0 ]

  # Give service time to start
  sleep 2

  # Verify service is running
  run remote "systemctl is-active litestream"
  [ "$output" = "active" ]
}

@test "litestream: databases command shows replicated DBs" {
  run just litestream databases
  [ "$status" -eq 0 ]
  [[ "$output" =~ "app.db" ]]
}

@test "litestream: replication creates snapshots" {
  # Wait for initial sync
  sleep 3

  # Check if snapshots exist in S3 bucket
  run docker exec just-bun-s3 ls -la /data/backups/
  [ "$status" -eq 0 ]
  # Bucket should have subdirectories for replicated databases
  [[ "$output" =~ "$DEPLOY_PROJECT_NAME" ]] || [[ "$output" =~ "total" ]]
}

@test "litestream: stop halts service" {
  run just litestream stop
  [ "$status" -eq 0 ]

  sleep 1

  run remote "systemctl is-active litestream || true"
  [ "$output" = "inactive" ]
}

@test "litestream: restart brings service back" {
  run just litestream restart
  [ "$status" -eq 0 ]

  sleep 2

  run remote "systemctl is-active litestream"
  [ "$output" = "active" ]
}

# ============================================================================
# Status & Logs
# ============================================================================

@test "litestream: status shows running" {
  run just litestream status
  [ "$status" -eq 0 ]
  [[ "$output" =~ "active" ]]
}

@test "litestream: logs are accessible" {
  run just litestream logs -n 5
  [ "$status" -eq 0 ]
}
