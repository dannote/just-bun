service_name := "forgejo"

import "./service.just"
import "../config.just"

version := env('FORGEJO_VERSION', '13.0.3')
repo_path := root + "/repo/linux/amd64"

etc_dir := deploy_etc + "/forgejo"
lib_dir := deploy_lib + "/forgejo"

# Ensure Forgejo is installed
require: _ssh-open
  #!/usr/bin/env bash
  set -euo pipefail

  if {{ssh-run}} test -x {{deploy_bin}}/forgejo; then
    echo '{{SUCCESS}}Forgejo installed at {{deploy_bin}}/forgejo{{RESET}}'
    exit 0
  fi

  echo '{{WARNING}}Forgejo not found, installing...{{RESET}}'
  just forgejo deploy

# Upload Forgejo binary to server
upload: _ssh-open
  # Create git user if it doesn't exist
  {{ssh-run}} id -u git &>/dev/null || {{ssh-run}} sudo useradd -r -m -d {{lib_dir}} -s /bin/bash git

  {{ssh-run}} sudo mkdir -p {{etc_dir}} {{lib_dir}} {{lib_dir}}/custom {{lib_dir}}/data {{lib_dir}}/log
  {{ssh-run}} sudo chown -R git:git {{lib_dir}}
  {{ssh-run}} sudo chown root:git {{etc_dir}}
  {{ssh-run}} sudo chmod 770 {{etc_dir}}

  {{rsync}} {{repo_path}}/forgejo.{{version}} {{ssh_user_host}}:/tmp/forgejo.{{version}}

  {{ssh-run}} sudo mv /tmp/forgejo.{{version}} {{deploy_bin}}/forgejo.{{version}}
  {{ssh-run}} sudo chmod +x {{deploy_bin}}/forgejo.{{version}}
  {{ssh-run}} sudo ln -sfn {{deploy_bin}}/forgejo.{{version}} {{deploy_bin}}/forgejo

# Install systemd service
setup-systemd: _ssh-open (_generate-config "forgejo.service")
  {{rsync}} {{generated_dir}}/forgejo.service {{ssh_user_host}}:/tmp/forgejo.service

  {{ssh-run}} sudo mv /tmp/forgejo.service /etc/systemd/system/forgejo.service

  {{systemctl}} daemon-reload
  {{systemctl}} enable forgejo

# Upload app.ini configuration
setup-config: _ssh-open (_generate-config "forgejo.ini")
  {{rsync}} {{generated_dir}}/forgejo.ini {{ssh_user_host}}:/tmp/app.ini

  {{ssh-run}} sudo mv /tmp/app.ini {{etc_dir}}/app.ini
  {{ssh-run}} sudo chown root:git {{etc_dir}}/app.ini
  # 660 allows Forgejo to write JWT_SECRET on first startup
  {{ssh-run}} sudo chmod 660 {{etc_dir}}/app.ini

# Upload Caddy site configuration (requires Caddy to be deployed)
setup-caddy: _ssh-open (_generate-config "forgejo.caddy")
  #!/usr/bin/env bash
  set -euo pipefail

  if ! {{ssh-run}} test -d {{deploy_etc}}/caddy/sites.d; then
    echo '{{WARNING}}Caddy not deployed, skipping site config{{RESET}}'
    exit 0
  fi

  {{rsync}} {{generated_dir}}/forgejo.caddy {{ssh_user_host}}:/tmp/forgejo.caddy
  {{ssh-run}} sudo mv /tmp/forgejo.caddy {{deploy_etc}}/caddy/sites.d/forgejo.caddy
  {{systemctl}} reload caddy
  echo '{{SUCCESS}}Caddy site configured{{RESET}}'

# Deploy Forgejo to server
deploy: upload setup-systemd setup-config setup-caddy

# Add Forgejo as Git remote (creates repo if needed)
add-remote repo_name="": _ssh-open
  #!/usr/bin/env bash
  set -euo pipefail

  # Use provided name or derive from current directory
  name="${1:-$(basename "$PWD")}"
  domain="$FORGEJO_DOMAIN"

  # Check if Forgejo is running
  if ! {{ssh-run}} systemctl is-active forgejo >/dev/null 2>&1; then
    echo '{{ERROR}}Forgejo is not running. Deploy it first with: just forgejo deploy{{RESET}}'
    exit 1
  fi

  # Git remote URL (SSH)
  remote_url="git@${domain}:${DEPLOY_USER}/${name}.git"

  # Check if origin already exists
  if git remote get-url origin >/dev/null 2>&1; then
    current=$(git remote get-url origin)
    if [ "$current" = "$remote_url" ]; then
      echo '{{SUCCESS}}Origin already set to {{ACCENT}}'"$remote_url"'{{RESET}}'
      exit 0
    fi
    echo '{{WARNING}}Origin exists: '"$current"'{{RESET}}'
    echo '{{ACCENT}}Updating to: '"$remote_url"'{{RESET}}'
    git remote set-url origin "$remote_url"
  else
    echo '{{ACCENT}}Adding origin: '"$remote_url"'{{RESET}}'
    git remote add origin "$remote_url"
  fi

  echo '{{SUCCESS}}Git origin configured{{RESET}}'
  echo ''
  echo '{{ACCENT}}Next steps:{{RESET}}'
  echo '  1. Create the repository in Forgejo web UI: https://'"$domain"
  echo '  2. Push your code: git push -u origin main'

# Generate secrets for app.ini (run locally, add to .env.production)
generate-secrets:
  #!/usr/bin/env bash
  set -euo pipefail

  bin="{{repo_path}}/forgejo.{{version}}"
  if [ ! -x "$bin" ]; then
    echo '{{ERROR}}Run "just repo forgejo collect" first{{RESET}}'
    exit 1
  fi

  echo "FORGEJO_SECRET_KEY=$($bin generate secret SECRET_KEY)"
  echo "FORGEJO_INTERNAL_TOKEN=$($bin generate secret INTERNAL_TOKEN)"

# Remove Forgejo from server
uninstall: _ssh-open
  #!/usr/bin/env bash
  set -euo pipefail

  echo '{{WARNING}}Uninstalling Forgejo...{{RESET}}'

  {{systemctl}} stop forgejo || true
  {{systemctl}} disable forgejo || true

  {{ssh-run}} sudo rm -f /etc/systemd/system/forgejo.service
  {{ssh-run}} sudo rm -f {{deploy_bin}}/forgejo {{deploy_bin}}/forgejo.*
  {{ssh-run}} sudo rm -f {{deploy_etc}}/caddy/sites.d/forgejo.caddy
  {{ssh-run}} sudo rm -rf {{etc_dir}} {{lib_dir}}

  {{systemctl}} daemon-reload
  {{systemctl}} reload caddy || true

  echo '{{SUCCESS}}Forgejo uninstalled{{RESET}}'
