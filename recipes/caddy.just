import "./ssh.just"
import "./colors.just"

root := justfile_directory()

releases_dir := root + "/releases"
configs_dir := root + "/configs"
generated_configs_dir := configs_dir + "/generated"
deployment_dir := "/opt/caddy"
projects_dir := env("DEPLOY_PROJECTS_DIR", "/opt/projects")

version := "2.10.2"
platform := "linux_amd64"

download_url := "https://github.com/caddyserver/caddy/releases/download" + \
  "/v" + version + "/caddy_" + version + "_" + platform + ".tar.gz"

export DEPLOY_CADDY_DIR := deployment_dir

service := '''
[Unit]
Description=Caddy
After=network.target

[Service]
Type=simple
User=$DEPLOY_USER
Group=$DEPLOY_GROUP
WorkingDirectory=$DEPLOY_CADDY_DIR
ExecStart=$DEPLOY_CADDY_DIR/caddy run --config $DEPLOY_CADDY_DIR/Caddyfile
Restart=on-failure

[Install]
WantedBy=multi-user.target
'''

config := '''
import "$DEPLOY_PROJECTS_DIR/*/etc/Caddyfile"
'''

require: _ssh-open
  #!/usr/bin/env bash

  set -euo pipefail

  if {{ssh-run}} test -x {{deployment_dir}}/caddy; then
    echo '{{SUCCESS}}Caddy already installed at {{deployment_dir}}/caddy{{RESET}}'
    exit 0
  fi

  echo '{{WARNING}}Caddy not found, installing...{{RESET}}'

  cd {{root}}

  just caddy deploy

download:
  #!/usr/bin/env bash

  set -euo pipefail

  if [ -f "{{releases_dir}}/caddy.{{platform}}" ]; then
    echo '{{MUTED}}Already have {{releases_dir}}/caddy.{{platform}}, skipping download{{RESET}}'
    exit 0
  fi

  curl -L {{download_url}} -o /tmp/caddy_{{version}}.tar.gz
  tar -xzf /tmp/caddy_{{version}}.tar.gz -C /tmp
  cp /tmp/caddy {{releases_dir}}/caddy.{{platform}}

_generate-service:
  printf "%s" "{{service}}" > {{generated_configs_dir}}/caddy.service

_generate-config:
  printf "%s" "{{config}}" > {{generated_configs_dir}}/caddy.config

upload: _ssh-open
  {{ssh-run}} sudo mkdir -p {{deployment_dir}} {{projects_dir}}
  {{ssh-run}} sudo chown -R $DEPLOY_USER:$DEPLOY_GROUP {{deployment_dir}} {{projects_dir}}
  {{ssh-run}} sudo chmod g+s {{deployment_dir}} {{projects_dir}}

  {{rsync}} {{releases_dir}}/caddy.{{platform}} {{ssh_user_host}}:{{deployment_dir}}/caddy

  {{ssh-run}} chmod +x {{deployment_dir}}/caddy

  {{ssh-run}} sudo setcap 'cap_net_bind_service=+ep' {{deployment_dir}}/caddy

setup-systemd: _generate-service _generate-config
  {{rsync}} {{generated_configs_dir}}/caddy.service {{ssh_user_host}}:{{deployment_dir}}
  {{rsync}} {{generated_configs_dir}}/caddy.config {{ssh_user_host}}:{{deployment_dir}}/Caddyfile

  {{ssh-run}} sudo ln -sfn {{deployment_dir}}/caddy.service /etc/systemd/system/caddy.service

  {{systemctl}} daemon-reload
  {{systemctl}} enable caddy

deploy: download upload setup-systemd

start: _ssh-open
  {{systemctl}} start caddy

stop: _ssh-open
  {{systemctl}} stop caddy

status: _ssh-open
  {{systemctl}} status caddy

restart: _ssh-open
  {{systemctl}} restart caddy
