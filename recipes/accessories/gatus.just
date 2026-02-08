service_name := "gatus"

import "./service.just"
import "../config.just"

version := env('GATUS_VERSION', '5.34.0')
repo_path := root + "/repo/linux/amd64"

etc_dir := deploy_etc + "/gatus"
lib_dir := deploy_lib + "/gatus"

# Ensure Gatus is installed
require: _ssh-open
  #!/usr/bin/env bash
  set -euo pipefail

  if {{ssh-run}} test -x {{deploy_bin}}/gatus; then
    echo '{{SUCCESS}}Gatus installed at {{deploy_bin}}/gatus{{RESET}}'
    exit 0
  fi

  echo '{{WARNING}}Gatus not found, installing...{{RESET}}'
  just gatus deploy

# Build Gatus from source for linux/amd64
build:
  #!/usr/bin/env bash
  set -euo pipefail

  echo '{{ACCENT}}Building Gatus {{version}} for linux/amd64...{{RESET}}'

  tmpdir=$(mktemp -d)
  trap "rm -rf $tmpdir" EXIT

  git clone --depth 1 --branch v{{version}} https://github.com/TwiN/gatus.git "$tmpdir/gatus"
  cd "$tmpdir/gatus"

  GOOS=linux GOARCH=amd64 CGO_ENABLED=0 go build -ldflags="-s -w" -o "{{repo_path}}/gatus.{{version}}" .

  echo '{{SUCCESS}}Built {{repo_path}}/gatus.{{version}}{{RESET}}'

# Upload Gatus binary to server
upload: _ssh-open
  {{ssh-run}} sudo mkdir -p {{etc_dir}} {{lib_dir}}
  {{ssh-run}} sudo chown $DEPLOY_USER:$DEPLOY_GROUP {{lib_dir}}

  {{rsync}} {{repo_path}}/gatus.{{version}} {{ssh_user_host}}:/tmp/gatus.{{version}}

  {{ssh-run}} sudo mv /tmp/gatus.{{version}} {{deploy_bin}}/gatus.{{version}}
  {{ssh-run}} sudo chmod +x {{deploy_bin}}/gatus.{{version}}
  {{ssh-run}} sudo ln -sfn {{deploy_bin}}/gatus.{{version}} {{deploy_bin}}/gatus

# Install systemd service
setup-systemd: _ssh-open (_generate-config "gatus.service") (_generate-config "gatus.yaml")
  {{rsync}} {{generated_dir}}/gatus.service {{ssh_user_host}}:/tmp/gatus.service
  {{rsync}} {{generated_dir}}/gatus.yaml {{ssh_user_host}}:/tmp/gatus.yaml

  {{ssh-run}} sudo mv /tmp/gatus.service /etc/systemd/system/gatus.service
  {{ssh-run}} sudo mv /tmp/gatus.yaml {{etc_dir}}/gatus.yaml

  {{systemctl}} daemon-reload
  {{systemctl}} enable gatus

# Deploy Gatus to server
deploy: upload setup-systemd

# Remove Gatus from server
uninstall: _ssh-open
  #!/usr/bin/env bash
  set -euo pipefail

  echo '{{WARNING}}Uninstalling Gatus...{{RESET}}'

  {{systemctl}} stop gatus || true
  {{systemctl}} disable gatus || true

  {{ssh-run}} sudo rm -f /etc/systemd/system/gatus.service
  {{ssh-run}} sudo rm -f {{deploy_bin}}/gatus {{deploy_bin}}/gatus.*
  {{ssh-run}} sudo rm -rf {{etc_dir}} {{lib_dir}}

  {{systemctl}} daemon-reload

  echo '{{SUCCESS}}Gatus uninstalled{{RESET}}'
