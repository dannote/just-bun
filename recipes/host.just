# Host discovery and management commands
# Discover apps and databases on the deployment server

import "./ssh.just"
import "./colors.just"
import "./config.just"

lib_dir := deploy_lib
host := env("DEPLOY_HOST", "localhost")

# List all apps on the server (directories with app.db)
apps: _ssh-open
  #!/usr/bin/env bash
  set -euo pipefail

  echo '{{ACCENT}}Apps on {{host}}:{{RESET}}'
  {{ssh-run}} "find {{lib_dir}} -maxdepth 2 -name 'app.db' -type f 2>/dev/null" | while read -r db; do
    app=$(dirname "$db" | xargs basename)
    echo "  $app"
  done || true

# Get database paths (machine-readable, one per line)
_database-paths: _ssh-open
  #!/usr/bin/env bash
  set -euo pipefail

  # App databases
  {{ssh-run}} "find {{lib_dir}} -maxdepth 2 -name 'app.db' -type f 2>/dev/null" || true

  # Forgejo database
  if {{ssh-run}} "test -f {{lib_dir}}/forgejo/data/forgejo.db" 2>/dev/null; then
    echo "{{lib_dir}}/forgejo/data/forgejo.db"
  fi

# List all SQLite databases on the server
databases: _ssh-open
  #!/usr/bin/env bash
  set -euo pipefail

  echo '{{ACCENT}}Databases on {{host}}:{{RESET}}'

  just host _database-paths | while read -r db; do
    [ -z "$db" ] && continue
    app=$(dirname "$db" | xargs basename)
    echo "  $db ($app)"
  done

# List all systemd services for apps
services: _ssh-open
  #!/usr/bin/env bash
  set -euo pipefail

  echo '{{ACCENT}}App services on {{host}}:{{RESET}}'

  # Find services that match our app pattern
  {{ssh-run}} "systemctl list-units --type=service --state=running --no-pager --plain" | \
    grep -E "^(caddy|forgejo|litestream|vector|{{DEPLOY_PROJECT_NAME}})" | \
    awk '{print "  " $1 " (" $4 ")"}'
