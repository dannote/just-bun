service_name := "caddy"

import "./service.just"
import "../config.just"

version := env('CADDY_VERSION', '2.10.2')
repo_path := root + "/repo/linux/amd64"

etc_dir := deploy_etc + "/caddy"
lib_dir := deploy_lib + "/caddy"

require: _ssh-open
  #!/usr/bin/env bash
  set -euo pipefail

  if {{ssh-run}} test -x {{deploy_bin}}/caddy; then
    echo '{{SUCCESS}}Caddy installed at {{deploy_bin}}/caddy{{RESET}}'
    exit 0
  fi

  echo '{{WARNING}}Caddy not found, installing...{{RESET}}'
  just caddy deploy

upload: _ssh-open
  {{ssh-run}} sudo mkdir -p {{etc_dir}} {{etc_dir}}/sites.d {{lib_dir}}
  {{ssh-run}} sudo chown $DEPLOY_USER:$DEPLOY_GROUP {{etc_dir}}/sites.d {{lib_dir}}

  {{rsync}} {{repo_path}}/caddy.{{version}} {{ssh_user_host}}:/tmp/caddy.{{version}}

  {{ssh-run}} sudo mv /tmp/caddy.{{version}} {{deploy_bin}}/caddy.{{version}}
  {{ssh-run}} sudo chmod +x {{deploy_bin}}/caddy.{{version}}
  {{ssh-run}} sudo ln -sfn {{deploy_bin}}/caddy.{{version}} {{deploy_bin}}/caddy
  {{ssh-run}} sudo setcap 'cap_net_bind_service=+ep' {{deploy_bin}}/caddy.{{version}}

setup-systemd: _ssh-open (_generate-config "caddy.service") (_generate-config "main.caddy")
  {{rsync}} {{generated_dir}}/caddy.service {{ssh_user_host}}:/tmp/caddy.service
  {{rsync}} {{generated_dir}}/main.caddy {{ssh_user_host}}:/tmp/Caddyfile

  {{ssh-run}} sudo mv /tmp/caddy.service /etc/systemd/system/caddy.service
  {{ssh-run}} sudo mv /tmp/Caddyfile {{etc_dir}}/Caddyfile

  {{systemctl}} daemon-reload
  {{systemctl}} enable caddy

deploy: upload setup-systemd

uninstall: _ssh-open
  #!/usr/bin/env bash
  set -euo pipefail

  echo '{{WARNING}}Uninstalling Caddy...{{RESET}}'

  {{systemctl}} stop caddy || true
  {{systemctl}} disable caddy || true

  {{ssh-run}} sudo rm -f /etc/systemd/system/caddy.service
  {{ssh-run}} sudo rm -f {{deploy_bin}}/caddy {{deploy_bin}}/caddy.*
  {{ssh-run}} sudo rm -rf {{etc_dir}} {{lib_dir}}

  {{systemctl}} daemon-reload

  echo '{{SUCCESS}}Caddy uninstalled{{RESET}}'
