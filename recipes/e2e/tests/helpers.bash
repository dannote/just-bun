# Shared test helpers for e2e tests
# Load with: load helpers

# Export common environment variables
_setup_env() {
  # Re-export deploy variables
  export DEPLOY_HOST="${DEPLOY_HOST:-localhost}"
  export DEPLOY_USER="${DEPLOY_USER:-fedora}"
  export DEPLOY_GROUP="${DEPLOY_GROUP:-fedora}"
  export DEPLOY_SSH_PORT="${DEPLOY_SSH_PORT:-2222}"
  export DEPLOY_SSH_KEY="${DEPLOY_SSH_KEY:-recipes/e2e/id_ed25519}"
  [[ "$DEPLOY_SSH_KEY" != /* ]] && export DEPLOY_SSH_KEY="$PWD/$DEPLOY_SSH_KEY"
  export DEPLOY_SSH_OPTS="${DEPLOY_SSH_OPTS:--o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null}"

  # Forgejo settings
  export FORGEJO_DOMAIN="${FORGEJO_DOMAIN:-localhost}"
  export FORGEJO_HTTP_PORT="${FORGEJO_HTTP_PORT:-3001}"

  # Litestream settings
  export LITESTREAM_ACCESS_KEY_ID="${LITESTREAM_ACCESS_KEY_ID:-minioadmin}"
  export LITESTREAM_SECRET_ACCESS_KEY="${LITESTREAM_SECRET_ACCESS_KEY:-minioadmin}"
  export LITESTREAM_BUCKET="${LITESTREAM_BUCKET:-backups}"
  export LITESTREAM_ENDPOINT="${LITESTREAM_ENDPOINT:-http://just-bun-s3:9000}"
  export LITESTREAM_SYNC_INTERVAL="${LITESTREAM_SYNC_INTERVAL:-1s}"

  # Deploy paths (matching recipes/ssh.just defaults)
  export DEPLOY_PROJECT_NAME="${DEPLOY_PROJECT_NAME:-just-bun-test}"
  export BIN_DIR="/usr/local/bin"
  export ETC_DIR="/etc"
  export LIB_DIR="/var/lib"
  export WWW_DIR="/var/www/$DEPLOY_PROJECT_NAME"

  # SSH helper variables
  export SSH_KEY="$DEPLOY_SSH_KEY"
  export SSH_PORT="$DEPLOY_SSH_PORT"
  export SSH_HOST="$DEPLOY_HOST"
  export SSH_USER="$DEPLOY_USER"
  export SSH_OPTS="$DEPLOY_SSH_OPTS"

  # Git commit info
  export CURRENT_COMMIT=$(git rev-parse --short HEAD)
  export PREV_COMMIT=$(git rev-parse --short HEAD~1 2>/dev/null || echo "")
}

# Default setup_file - can be overridden by test files
setup_file() {
  _setup_env
}

# Run command on remote server via SSH (suppress SSH warnings)
remote() {
  ssh $SSH_OPTS -i "$SSH_KEY" -p "$SSH_PORT" "$SSH_USER@$SSH_HOST" "$@" 2>/dev/null
}
