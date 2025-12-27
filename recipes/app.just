import "./ssh.just"
import "./colors.just"
import "./vite.just"
import "./config.just"

# Caddy reverse proxy
mod caddy "./accessories/caddy.just"
# Vector log aggregator
mod vector "./accessories/vector.just"
# MinIO client
mod mc "./accessories/mc.just"

repo_dir := root + "/repo"
public_dir := root + "/.output/public"

etc_dir := deploy_etc + "/" + DEPLOY_PROJECT_NAME
www_dir := deploy_www + "/" + DEPLOY_PROJECT_NAME
lib_dir := deploy_lib + "/" + DEPLOY_PROJECT_NAME
cache_dir := deploy_cache + "/" + DEPLOY_PROJECT_NAME

hash := `git rev-parse --short HEAD`

# Install project dependencies
install:
  bun install

_bun-target target:
  #!/usr/bin/env bash
  set -euo pipefail
  IFS='-' read -r os arch <<< "{{target}}"
  [[ "$arch" == "amd64" ]] && arch="x64"
  [[ "$os" == "linux" && "$arch" == "x64" ]] && arch="x64-baseline"
  echo "bun-$os-$arch"

# Build and compile binary for target platform (e.g., linux-amd64)
release target='': build
  #!/usr/bin/env bash
  set -euo pipefail

  if [ -n "{{target}}" ]; then
    repo_path="{{repo_dir}}/{{replace(target, "-", "/")}}"
    bun_target=$(just app _bun-target {{target}})
    target_flag="--target=$bun_target"
  else
    repo_path="{{repo_dir}}/local"
    target_flag=""
  fi

  mkdir -p "$repo_path"

  bun build --compile {{root}}/.output/server/index.mjs \
    --compile-autoload-dotenv \
    $target_flag \
    --outfile "$repo_path/{{DEPLOY_PROJECT_NAME}}.{{hash}}"

  echo '{{SUCCESS}}Built {{DEPLOY_PROJECT_NAME}}.{{hash}}{{RESET}}'

# Build release for production target
release-production:
  @echo '{{ACCENT}}Building release for target: $DEPLOY_TARGET{{RESET}}'
  just app release $DEPLOY_TARGET

# Upload binary, configs, and static files to server
# Use --force to overwrite existing binary (stops service temporarily)
upload *args: _ssh-open (_generate-config "app.caddy")
  #!/usr/bin/env bash
  set -euo pipefail

  force=false
  for arg in {{args}}; do
    [[ "$arg" == "--force" || "$arg" == "-f" ]] && force=true
  done

  echo '{{ACCENT}}Uploading release{{RESET}}'

  repo_path="{{repo_dir}}/${DEPLOY_TARGET/-//}"

  # Create directories
  {{ssh-run}} sudo mkdir -p {{etc_dir}} {{deploy_etc}}/caddy/sites.d {{www_dir}} {{lib_dir}} {{cache_dir}}
  {{ssh-run}} sudo chown $DEPLOY_USER:$DEPLOY_GROUP {{etc_dir}} {{deploy_etc}}/caddy/sites.d {{www_dir}} {{lib_dir}} {{cache_dir}}

  # Upload binary to cache_dir with stable name for delta transfer, then copy to bin
  {{rsync}} "$repo_path/{{DEPLOY_PROJECT_NAME}}.{{hash}}" {{ssh_user_host}}:{{cache_dir}}/{{DEPLOY_PROJECT_NAME}}

  # Copy binary unless it already exists (use --force to overwrite)
  if {{ssh-run}} test -f {{deploy_bin}}/{{DEPLOY_PROJECT_NAME}}.{{hash}} && ! $force; then
    echo '{{SUCCESS}}Binary already exists, skipping copy{{RESET}}'
  else
    $force && echo '{{WARNING}}Force mode: stopping service to overwrite binary{{RESET}}'
    $force && {{systemctl}} stop {{DEPLOY_PROJECT_NAME}} 2>/dev/null || true
    {{ssh-run}} sudo cp {{cache_dir}}/{{DEPLOY_PROJECT_NAME}} {{deploy_bin}}/{{DEPLOY_PROJECT_NAME}}.{{hash}}
    {{ssh-run}} sudo chmod +x {{deploy_bin}}/{{DEPLOY_PROJECT_NAME}}.{{hash}}
    $force && {{systemctl}} start {{DEPLOY_PROJECT_NAME}} 2>/dev/null || true
  fi
  {{ssh-run}} sudo ln -sfn {{deploy_bin}}/{{DEPLOY_PROJECT_NAME}}.{{hash}} {{deploy_bin}}/{{DEPLOY_PROJECT_NAME}}

  # Upload configs
  {{rsync}} {{generated_dir}}/app.caddy {{ssh_user_host}}:{{deploy_etc}}/caddy/sites.d/{{DEPLOY_PROJECT_NAME}}.caddy
  if [ -f "{{root}}/.env.production" ]; then
    {{rsync}} {{root}}/.env.production {{ssh_user_host}}:{{etc_dir}}/.env.production
  fi

  # Upload static files
  {{rsync}} {{public_dir}}/ {{ssh_user_host}}:{{www_dir}}/

# Install and enable systemd service
setup-systemd: _ssh-open (_generate-config "app.service")
  @echo '{{ACCENT}}Updating systemd configuration{{RESET}}'

  {{rsync}} {{generated_dir}}/app.service {{ssh_user_host}}:/tmp/{{DEPLOY_PROJECT_NAME}}.service

  {{ssh-run}} sudo mv /tmp/{{DEPLOY_PROJECT_NAME}}.service /etc/systemd/system/{{DEPLOY_PROJECT_NAME}}.service

  {{systemctl}} daemon-reload
  {{systemctl}} enable {{DEPLOY_PROJECT_NAME}}

# Restart the service
restart: _ssh-open
  @echo '{{ACCENT}}Restarting {{DEPLOY_PROJECT_NAME}}{{RESET}}'
  {{systemctl}} restart {{DEPLOY_PROJECT_NAME}}

# Start the service
start: _ssh-open
  {{systemctl}} start {{DEPLOY_PROJECT_NAME}}

# Stop the service
stop: _ssh-open
  {{systemctl}} stop {{DEPLOY_PROJECT_NAME}}

# Stop and disable the service (keeps files)
disable: _ssh-open
  @echo '{{ACCENT}}Disabling {{DEPLOY_PROJECT_NAME}}{{RESET}}'
  {{systemctl}} stop {{DEPLOY_PROJECT_NAME}} || true
  {{systemctl}} disable {{DEPLOY_PROJECT_NAME}}

# Enable and start the service
enable: _ssh-open
  @echo '{{ACCENT}}Enabling {{DEPLOY_PROJECT_NAME}}{{RESET}}'
  {{systemctl}} enable {{DEPLOY_PROJECT_NAME}}
  {{systemctl}} start {{DEPLOY_PROJECT_NAME}}

# Show service status
status: _ssh-open
  {{systemctl}} status {{DEPLOY_PROJECT_NAME}}

# Show service logs (pass args like -f, -n 100)
logs *args: _ssh-open
  {{ssh-run}} journalctl -u {{DEPLOY_PROJECT_NAME}} {{args}}

# Full deployment: build, upload, configure, and restart
# Use --force/-f to overwrite existing binary (stops service temporarily)
deploy *args: caddy::require vector::require mc::require release-production (upload args) setup-systemd restart status caddy::restart vector::restart
  @echo '{{ACCENT}}Deploy complete{{RESET}}'

# Show currently deployed version hash
version: _ssh-open
  @{{ssh-run}} "readlink {{deploy_bin}}/{{DEPLOY_PROJECT_NAME}} | sed 's|.*/||;s|^{{DEPLOY_PROJECT_NAME}}\.||'"

# List available versions on server
versions: _ssh-open
  @{{ssh-run}} "ls -1t {{deploy_bin}}/{{DEPLOY_PROJECT_NAME}}.* 2>/dev/null | sed 's|.*/{{DEPLOY_PROJECT_NAME}}\.||'"

# Rollback to a previous version (defaults to previous git commit)
rollback commit='': _ssh-open
  #!/usr/bin/env bash
  set -euo pipefail

  if [ -n "{{commit}}" ]; then
    target_hash="{{commit}}"
  else
    target_hash=$(git rev-parse --short HEAD~1)
  fi

  target_bin="{{deploy_bin}}/{{DEPLOY_PROJECT_NAME}}.$target_hash"

  # Check if target binary exists
  if ! {{ssh-run}} "test -f $target_bin"; then
    echo "{{ERROR}}Version $target_hash not found{{RESET}}"
    exit 1
  fi

  echo "{{ACCENT}}Rolling back to $target_hash{{RESET}}"

  {{ssh-run}} sudo ln -sfn "$target_bin" {{deploy_bin}}/{{DEPLOY_PROJECT_NAME}}
  {{systemctl}} restart {{DEPLOY_PROJECT_NAME}}

  echo "{{SUCCESS}}Rolled back to $target_hash{{RESET}}"

# Remove old binary versions, keeping latest 3
prune: _ssh-open
  #!/usr/bin/env bash
  set -euo pipefail

  echo '{{ACCENT}}Pruning old versions{{RESET}}'

  {{ssh-run}} 'ls -1t {{deploy_bin}}/{{DEPLOY_PROJECT_NAME}}.* 2>/dev/null | tail -n +4 | xargs -r sudo rm -f'

  echo '{{SUCCESS}}Done{{RESET}}'

# Remove service, configs, binaries, and all app data
uninstall: _ssh-open
  #!/usr/bin/env bash
  set -euo pipefail

  echo '{{WARNING}}Uninstalling {{DEPLOY_PROJECT_NAME}}...{{RESET}}'

  {{systemctl}} stop {{DEPLOY_PROJECT_NAME}} || true
  {{systemctl}} disable {{DEPLOY_PROJECT_NAME}} || true

  {{ssh-run}} sudo rm -f /etc/systemd/system/{{DEPLOY_PROJECT_NAME}}.service
  {{ssh-run}} sudo rm -f {{deploy_etc}}/caddy/sites.d/{{DEPLOY_PROJECT_NAME}}.caddy
  {{ssh-run}} sudo rm -f {{deploy_bin}}/{{DEPLOY_PROJECT_NAME}} {{deploy_bin}}/{{DEPLOY_PROJECT_NAME}}.*
  {{ssh-run}} sudo rm -rf {{etc_dir}} {{www_dir}} {{lib_dir}} {{cache_dir}}

  {{systemctl}} daemon-reload

  echo '{{SUCCESS}}{{DEPLOY_PROJECT_NAME}} uninstalled{{RESET}}'
