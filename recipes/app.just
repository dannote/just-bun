import "./ssh.just"
import "./colors.just"
import "./vite.just"

mod caddy "./caddy.just"

root := justfile_directory()

releases_dir := root + "/releases"
configs_dir := root + "/configs"
generated_configs_dir := configs_dir + "/generated"
public_dir := root + "/.output/public"

project_name := env("DEPLOY_PROJECT_NAME", "just-bun")
deploy_project_dir := env("DEPLOY_PROJECTS_DIR", "/opt/projects") + "/" + project_name
deploy_bin_dir := deploy_project_dir + "/bin"
deploy_etc_dir := deploy_project_dir + "/etc"

export DEPLOY_PROJECT_DIR := deploy_project_dir

service := '''
[Unit]
Description=$DEPLOY_PROJECT_NAME app service
After=network.target

[Service]
Type=simple
User=$DEPLOY_USER
Group=$DEPLOY_GROUP

WorkingDirectory=$DEPLOY_PROJECT_DIR
EnvironmentFile=-$DEPLOY_PROJECT_DIR/.env
EnvironmentFile=-$DEPLOY_PROJECT_DIR/.env.production
ExecStart=$DEPLOY_PROJECT_DIR/bin/server

Restart=on-failure

ProtectSystem=strict
ProtectHome=yes
PrivateTmp=yes
PrivateDevices=yes
ProtectKernelTunables=yes
ProtectKernelModules=yes
ProtectControlGroups=yes

[Install]
WantedBy=multi-user.target
'''

caddy_vars := '''
vars {
  public $DEPLOY_PROJECT_DIR/public
}
'''

hash := `git rev-parse --short HEAD`

install:
  bun install

release platform='': build
  mkdir -p {{releases_dir}}

  bun build \
    --compile {{root}}/.output/server/index.mjs \
    --outfile {{releases_dir}}/server{{ if platform != '' { "." + platform } else { "" } }} \
    {{ if platform != '' { "--target=bun-" + platform } else { "" } }}

release-production:
  @echo '{{ACCENT}}Building release for target: $DEPLOY_TARGET{{RESET}}'
  
  just app release $DEPLOY_TARGET

upload: _ssh-open
  @echo '{{ACCENT}}Uploading release artifacts and configuration{{RESET}}'
  
  {{ssh-run}} sudo mkdir -p {{deploy_project_dir}} {{deploy_bin_dir}} {{deploy_etc_dir}}
  {{ssh-run}} sudo chown -R $DEPLOY_USER:$DEPLOY_GROUP {{deploy_project_dir}}
  {{ssh-run}} sudo chmod g+s {{deploy_project_dir}} {{deploy_bin_dir}} {{deploy_etc_dir}}

  {{rsync}} {{root}}/Caddyfile {{ssh_user_host}}:{{deploy_etc_dir}}/Caddyfile
  if [ -f "{{root}}/.env.production" ]; then {{rsync}} {{root}}/.env.production {{ssh_user_host}}:{{deploy_project_dir}}; fi

  {{rsync}} {{releases_dir}}/server.$DEPLOY_TARGET {{ssh_user_host}}:{{deploy_bin_dir}}/server.latest

  {{rsync}} {{public_dir}}/ {{ssh_user_host}}:{{deploy_project_dir}}/public/

  {{ssh-run}} chmod +x {{deploy_bin_dir}}/server.latest
  {{ssh-run}} cp -n {{deploy_bin_dir}}/server.latest {{deploy_bin_dir}}/server.{{hash}}
  {{ssh-run}} ln -sfn {{deploy_bin_dir}}/server.{{hash}} {{deploy_bin_dir}}/server

_generate-service:
  printf "%s" "{{service}}" > {{generated_configs_dir}}/app.service

_generate-caddy-vars:
  printf "%s" "{{caddy_vars}}" > {{generated_configs_dir}}/vars.caddy

setup-systemd: _generate-service _generate-caddy-vars
  @echo '{{ACCENT}}Updating systemd configuration{{RESET}}'
  
  {{rsync}} {{generated_configs_dir}}/app.service {{ssh_user_host}}:{{deploy_project_dir}}/app.service
  {{rsync}} {{generated_configs_dir}}/vars.caddy {{ssh_user_host}}:{{deploy_etc_dir}}/vars.caddy

  {{ssh-run}} sudo ln -sfn {{deploy_project_dir}}/app.service /etc/systemd/system/{{project_name}}.service

  {{systemctl}} daemon-reload
  {{systemctl}} enable {{project_name}}

restart: _ssh-open
  @echo '{{ACCENT}}Restarting service {{project_name}}{{RESET}}'
  
  {{systemctl}} restart {{project_name}}

start: _ssh-open
  {{systemctl}} start {{project_name}}

stop: _ssh-open
  {{systemctl}} stop {{project_name}}

status: _ssh-open
  {{systemctl}} status {{project_name}}

logs *args: _ssh-open
  {{ssh-run}} journalctl -u {{project_name}} {{args}}

deploy: caddy::require release-production upload setup-systemd restart status
  @echo '{{ACCENT}}Restarting caddy to reload configs{{RESET}}'
  
  just caddy restart

version: _ssh-open
  {{ssh-run}} "cd {{deploy_bin_dir}} && basename \$(readlink server) | sed 's/^server\.//'"

prune: _ssh-open
  #!/bin/bash

  {{ssh-run}} '
    ls -1t {{deploy_bin_dir}}/server.* 2>/dev/null \
    | tail -n +4 \
    | grep -v \"server.{{hash}}\" \
    | xargs -r rm -f
  '
