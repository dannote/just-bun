#!/usr/bin/env bats

# E2E Tests for Deployment Commands
# Run with: just e2e test

load helpers

# ============================================================================
# Initial Deploy - Build & Release
# ============================================================================

@test "deploy: build project creates output" {
  run just app build
  [ "$status" -eq 0 ]

  # Verify output directory exists
  [ -d ".output" ]
  [ -d ".output/public" ]
  [ -d ".output/server" ]
}

@test "deploy: release creates binary with commit hash" {
  run just app release linux-amd64
  [ "$status" -eq 0 ]

  # Verify binary exists with correct name
  [ -f "repo/linux/amd64/$DEPLOY_PROJECT_NAME.$CURRENT_COMMIT" ]

  # Verify binary is executable
  [ -x "repo/linux/amd64/$DEPLOY_PROJECT_NAME.$CURRENT_COMMIT" ]
}

# ============================================================================
# Upload & Setup
# ============================================================================

@test "deploy: upload transfers binary to server" {
  run just app upload
  [ "$status" -eq 0 ]

  # Verify binary exists on server
  run remote "test -f $BIN_DIR/$DEPLOY_PROJECT_NAME.$CURRENT_COMMIT"
  [ "$status" -eq 0 ]

  # Verify binary is executable on server
  run remote "test -x $BIN_DIR/$DEPLOY_PROJECT_NAME.$CURRENT_COMMIT"
  [ "$status" -eq 0 ]
}

@test "deploy: upload creates symlink" {
  run remote "readlink $BIN_DIR/$DEPLOY_PROJECT_NAME"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "$DEPLOY_PROJECT_NAME.$CURRENT_COMMIT" ]]
}

@test "deploy: upload transfers static files" {
  run remote "test -d $WWW_DIR"
  [ "$status" -eq 0 ]

  # Verify favicon exists
  run remote "test -f $WWW_DIR/favicon.svg"
  [ "$status" -eq 0 ]

  # Verify assets uploaded
  run remote "ls $WWW_DIR/assets/*.js"
  [ "$status" -eq 0 ]
}

@test "deploy: setup-systemd creates valid service file" {
  run just app setup-systemd
  [ "$status" -eq 0 ]

  # Verify service file exists
  run remote "test -f $ETC_DIR/systemd/system/$DEPLOY_PROJECT_NAME.service"
  [ "$status" -eq 0 ]

  # Verify service file contains ExecStart
  run remote "grep -q 'ExecStart=' $ETC_DIR/systemd/system/$DEPLOY_PROJECT_NAME.service"
  [ "$status" -eq 0 ]

  # Verify service is enabled
  run remote "systemctl is-enabled $DEPLOY_PROJECT_NAME"
  [[ "$output" =~ "enabled" ]]
}

@test "deploy: restart starts service successfully" {
  run just app restart
  [ "$status" -eq 0 ]

  # Give service time to start
  sleep 2

  # Verify service is active
  run remote "systemctl is-active $DEPLOY_PROJECT_NAME"
  [ "$output" = "active" ]
}

# ============================================================================
# Verify Deployment
# ============================================================================

@test "verify: service is running with correct status" {
  run just app status
  [ "$status" -eq 0 ]
  [[ "$output" =~ "active (running)" ]]
}

@test "verify: deployed version matches current commit" {
  run just app version
  [ "$status" -eq 0 ]

  # Extract version hash (last 7 hex chars) filtering out SSH warnings
  deployed_version=$(echo "$output" | grep -oE '[0-9a-f]{7}$' | tail -1)
  [ "$deployed_version" = "$CURRENT_COMMIT" ]
}

@test "verify: version appears in versions list" {
  run just app versions
  [ "$status" -eq 0 ]
  [[ "$output" =~ $CURRENT_COMMIT ]]
}

@test "verify: symlink points to deployed version" {
  run remote "readlink $BIN_DIR/$DEPLOY_PROJECT_NAME"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "$CURRENT_COMMIT" ]]
}

@test "verify: service responds to HTTP requests" {
  run remote "curl -sf http://localhost:3000/api/hello?id=123"
  [ "$status" -eq 0 ]

  # Verify response contains expected text
  [[ "$output" =~ "Hello" ]]
  [[ "$output" =~ "123" ]]
}

@test "verify: service responds to root path" {
  run remote "curl -sf http://localhost:3000/"
  [ "$status" -eq 0 ]

  # Should return HTML
  [[ "$output" =~ "html" ]]
}

@test "verify: logs are accessible" {
  run just app logs -n 10
  [ "$status" -eq 0 ]

  # Logs should not be empty
  [ -n "$output" ]
}

# ============================================================================
# Service Lifecycle
# ============================================================================

@test "lifecycle: stop halts the service" {
  run just app stop
  [ "$status" -eq 0 ]

  sleep 1

  # Verify service is stopped
  run remote "systemctl is-active $DEPLOY_PROJECT_NAME || true"
  [ "$output" = "inactive" ]
}

@test "lifecycle: start resumes the service" {
  run just app start
  [ "$status" -eq 0 ]

  sleep 2

  # Verify service is running
  run remote "systemctl is-active $DEPLOY_PROJECT_NAME"
  [ "$output" = "active" ]
}

@test "lifecycle: service responds after start" {
  run remote "curl -sf http://localhost:3000/api/hello?id=456"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "456" ]]
}

@test "lifecycle: disable stops and disables service" {
  run just app disable
  [ "$status" -eq 0 ]

  sleep 1

  # Verify service is disabled
  run remote "systemctl is-enabled $DEPLOY_PROJECT_NAME || echo disabled"
  [[ "$output" =~ "disabled" ]]

  # Verify service is not running
  run remote "systemctl is-active $DEPLOY_PROJECT_NAME || true"
  [ "$output" = "inactive" ]
}

@test "lifecycle: enable re-enables and starts service" {
  run just app enable
  [ "$status" -eq 0 ]

  sleep 2

  # Verify service is enabled
  run remote "systemctl is-enabled $DEPLOY_PROJECT_NAME"
  [[ "$output" =~ "enabled" ]]

  # Verify service is running
  run remote "systemctl is-active $DEPLOY_PROJECT_NAME"
  [ "$output" = "active" ]
}

# ============================================================================
# Full Deploy Command
# ============================================================================

@test "deploy: full deploy command works" {
  run just app deploy
  [ "$status" -eq 0 ]

  sleep 2

  # Verify service is running
  run remote "systemctl is-active $DEPLOY_PROJECT_NAME"
  [ "$output" = "active" ]

  # Verify version (filter SSH warnings)
  run just app version
  deployed=$(echo "$output" | grep -oE '[0-9a-f]{7}$' | tail -1)
  [ "$deployed" = "$CURRENT_COMMIT" ]
}

# ============================================================================
# Rollback
# ============================================================================

@test "rollback: can rollback to previous version" {
  # First ensure previous version exists
  remote "test -f $BIN_DIR/$DEPLOY_PROJECT_NAME.$PREV_COMMIT" || skip "Previous version not deployed"

  run just app rollback "$PREV_COMMIT"
  [ "$status" -eq 0 ]

  sleep 2

  # Verify version changed (filter SSH warnings)
  run just app version
  new_version=$(echo "$output" | grep -oE '[0-9a-f]{7}$' | tail -1)
  [ "$new_version" = "$PREV_COMMIT" ]
}

@test "rollback: service still responds after rollback" {
  run remote "curl -sf http://localhost:3000/api/hello?id=789"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Hello" ]]
}

@test "rollback: can rollback forward to current version" {
  run just app rollback "$CURRENT_COMMIT"
  [ "$status" -eq 0 ]

  sleep 2

  run just app version
  new_version=$(echo "$output" | grep -oE '[0-9a-f]{7}$' | tail -1)
  [ "$new_version" = "$CURRENT_COMMIT" ]
}

# ============================================================================
# Static Files
# ============================================================================

@test "static: public directory has correct structure" {
  run remote "ls -la $WWW_DIR"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "assets" ]]
  [[ "$output" =~ "favicon.svg" ]]
}

@test "static: assets directory contains bundled files" {
  run remote "ls $WWW_DIR/assets/"
  [ "$status" -eq 0 ]

  # Should have CSS and JS files
  [[ "$output" =~ ".css" ]] || [[ "$output" =~ ".js" ]]
}

# ============================================================================
# Version Management & Cleanup
# ============================================================================

@test "cleanup: prune keeps only recent versions" {
  # Run prune
  run just app prune
  [ "$status" -eq 0 ]

  # Verify at most 3 versions remain (filter out SSH warnings)
  count=$(remote "ls $BIN_DIR/$DEPLOY_PROJECT_NAME.* 2>/dev/null | wc -l" 2>/dev/null | tr -d '[:space:]')
  [ "$count" -le 3 ]

  # Verify current version still exists
  run remote "test -f $BIN_DIR/$DEPLOY_PROJECT_NAME.$CURRENT_COMMIT"
  [ "$status" -eq 0 ]
}

@test "cleanup: service remains active after prune" {
  run remote "systemctl is-active $DEPLOY_PROJECT_NAME"
  [ "$output" = "active" ]

  # Verify still responds
  run remote "curl -sf http://localhost:3000/api/hello?id=999"
  [ "$status" -eq 0 ]
}

# ============================================================================
# Final Verification
# ============================================================================

@test "final: all deployment files exist" {
  # Verify binary
  run remote "test -f $BIN_DIR/$DEPLOY_PROJECT_NAME.$CURRENT_COMMIT"
  [ "$status" -eq 0 ]

  # Verify symlink
  run remote "test -L $BIN_DIR/$DEPLOY_PROJECT_NAME"
  [ "$status" -eq 0 ]

  # Verify static files
  run remote "test -d $WWW_DIR"
  [ "$status" -eq 0 ]

  # Verify service file
  run remote "test -f $ETC_DIR/systemd/system/$DEPLOY_PROJECT_NAME.service"
  [ "$status" -eq 0 ]
}

@test "final: service is healthy and responsive" {
  # Check service status
  run just app status
  [ "$status" -eq 0 ]
  [[ "$output" =~ "active (running)" ]]

  # Check HTTP endpoint
  run remote "curl -sf http://localhost:3000/api/hello?id=42"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "42" ]]
}

@test "final: version management is consistent" {
  # Get version from command (filter SSH warnings)
  cmd_version=$(just app version 2>/dev/null | grep -oE '[0-9a-f]{7}$' | tail -1)

  # Get version from symlink
  link_target=$(remote "readlink $BIN_DIR/$DEPLOY_PROJECT_NAME")
  link_version=$(echo "$link_target" | sed "s/.*$DEPLOY_PROJECT_NAME\.//")

  # They should match
  [ "$cmd_version" = "$link_version" ]
}

# ============================================================================
# Host Discovery
# ============================================================================

@test "host: apps lists deployed applications" {
  run just host apps
  [ "$status" -eq 0 ]
  [[ "$output" =~ "$DEPLOY_PROJECT_NAME" ]]
}

@test "host: databases lists app database" {
  run just host databases
  [ "$status" -eq 0 ]
  [[ "$output" =~ "app.db" ]]
}

@test "host: services lists running services" {
  run just host services
  [ "$status" -eq 0 ]
  [[ "$output" =~ "$DEPLOY_PROJECT_NAME" ]]
}
