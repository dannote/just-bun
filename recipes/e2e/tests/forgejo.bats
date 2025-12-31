#!/usr/bin/env bats

# E2E Tests for Forgejo Deployment
# Run with: just e2e test

load helpers

# ============================================================================
# Forgejo Binary Collection
# ============================================================================

@test "forgejo: binary exists in repo" {
  # Detect architecture (arm64 on Apple Silicon)
  arch=$(uname -m)
  case "$arch" in
    arm64|aarch64) repo_arch="arm64" ;;
    x86_64|amd64) repo_arch="amd64" ;;
    *) skip "Unsupported architecture: $arch" ;;
  esac

  # Check if binary exists
  run ls repo/linux/$repo_arch/forgejo.*
  if [ "$status" -ne 0 ]; then
    # Try to collect it
    run just repo forgejo collect
    [ "$status" -eq 0 ]
  fi

  # Verify binary exists
  run ls repo/linux/$repo_arch/forgejo.*
  [ "$status" -eq 0 ]
}

# ============================================================================
# Forgejo Upload & Setup
# ============================================================================

@test "forgejo: upload transfers binary to server" {
  run just forgejo upload
  [ "$status" -eq 0 ]

  # Verify binary exists on server
  run remote "test -x $BIN_DIR/forgejo"
  [ "$status" -eq 0 ]
}

@test "forgejo: git user created" {
  run remote "id git"
  [ "$status" -eq 0 ]
}

@test "forgejo: directories have correct permissions" {
  # Check /etc/forgejo
  run remote "test -d $ETC_DIR/forgejo"
  [ "$status" -eq 0 ]

  # Check /var/lib/forgejo
  run remote "test -d $LIB_DIR/forgejo"
  [ "$status" -eq 0 ]

  # Check ownership
  run remote "stat -c '%U' $LIB_DIR/forgejo"
  [ "$output" = "git" ]
}

@test "forgejo: setup-config creates app.ini" {
  run just forgejo setup-config
  [ "$status" -eq 0 ]
}

@test "forgejo: app.ini exists with correct permissions" {
  # Verify config exists
  run remote "sudo test -f $ETC_DIR/forgejo/app.ini"
  [ "$status" -eq 0 ]

  # Verify config has correct permissions (660 allows Forgejo to write JWT_SECRET)
  run remote "sudo stat -c '%a' $ETC_DIR/forgejo/app.ini"
  [ "$output" = "660" ]
}

@test "forgejo: setup-systemd creates service" {
  run just forgejo setup-systemd
  [ "$status" -eq 0 ]

  # Verify service file exists
  run remote "test -f /etc/systemd/system/forgejo.service"
  [ "$status" -eq 0 ]

  # Verify service is enabled
  run remote "systemctl is-enabled forgejo"
  [[ "$output" =~ "enabled" ]]
}

# ============================================================================
# Forgejo Service Lifecycle
# ============================================================================

@test "forgejo: start launches service" {
  run just forgejo start
  [ "$status" -eq 0 ]

  # Give service time to start
  sleep 3

  # Verify service is running
  run remote "systemctl is-active forgejo"
  [ "$output" = "active" ]
}

@test "forgejo: responds to HTTP requests" {
  # Wait for Forgejo to be ready
  for i in {1..10}; do
    if remote "curl -sf http://localhost:$FORGEJO_HTTP_PORT/" >/dev/null 2>&1; then
      break
    fi
    sleep 2
  done

  run remote "curl -sf http://localhost:$FORGEJO_HTTP_PORT/"
  [ "$status" -eq 0 ]

  # Should return HTML with Forgejo
  [[ "$output" =~ "Forgejo" ]] || [[ "$output" =~ "html" ]]
}

@test "forgejo: API is accessible" {
  run remote "curl -sf http://localhost:$FORGEJO_HTTP_PORT/api/v1/version"
  [ "$status" -eq 0 ]

  # Should return version info
  [[ "$output" =~ "version" ]]
}

@test "forgejo: stop halts service" {
  run just forgejo stop
  [ "$status" -eq 0 ]

  sleep 1

  run remote "systemctl is-active forgejo || true"
  [ "$output" = "inactive" ]
}

@test "forgejo: restart brings service back" {
  run just forgejo restart
  [ "$status" -eq 0 ]

  sleep 3

  run remote "systemctl is-active forgejo"
  [ "$output" = "active" ]
}

# ============================================================================
# Forgejo Status & Logs
# ============================================================================

@test "forgejo: status shows running" {
  run just forgejo status
  [ "$status" -eq 0 ]
  [[ "$output" =~ "active" ]]
}

@test "forgejo: logs are accessible" {
  run just forgejo logs -n 5
  [ "$status" -eq 0 ]
}

