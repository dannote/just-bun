import "./ssh.just"
import "./colors.just"
import "./vite.just"
import "./config.just"

mod caddy "./accessories/caddy.just"
mod vector "./accessories/vector.just"
mod mc "./accessories/mc.just"

repo_dir := root + "/repo"
public_dir := root + "/.output/public"

etc_dir := deploy_etc + "/" + DEPLOY_PROJECT_NAME
www_dir := deploy_www + "/" + DEPLOY_PROJECT_NAME
lib_dir := deploy_lib + "/" + DEPLOY_PROJECT_NAME
cache_dir := deploy_cache + "/" + DEPLOY_PROJECT_NAME

hash := `git rev-parse --short HEAD`

install:
  bun install

# Convert linux-amd64 -> bun-linux-x64-baseline
_bun-target target:
  #!/usr/bin/env bash
  set -euo pipefail
  IFS='-' read -r os arch <<< "{{target}}"
  [[ "$arch" == "amd64" ]] && arch="x64"
  [[ "$os" == "linux" && "$arch" == "x64" ]] && arch="x64-baseline"
  echo "bun-$os-$arch"

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

release-production:
  @echo '{{ACCENT}}Building release for target: $DEPLOY_TARGET{{RESET}}'
  just app release $DEPLOY_TARGET

upload: _ssh-open (_generate-config "app.caddy")
  #!/usr/bin/env bash
  set -euo pipefail

  echo '{{ACCENT}}Uploading release{{RESET}}'

  repo_path="{{repo_dir}}/${DEPLOY_TARGET/-//}"

  # Create directories
  {{ssh-run}} sudo mkdir -p {{etc_dir}} {{www_dir}} {{lib_dir}} {{cache_dir}}
  {{ssh-run}} sudo chown $DEPLOY_USER:$DEPLOY_GROUP {{etc_dir}} {{www_dir}} {{lib_dir}} {{cache_dir}}

  # Upload binary to cache_dir with stable name for delta transfer, then copy to bin
  {{rsync}} "$repo_path/{{DEPLOY_PROJECT_NAME}}.{{hash}}" {{ssh_user_host}}:{{cache_dir}}/{{DEPLOY_PROJECT_NAME}}

  # Skip copy if version already exists (e.g. redeploying same commit)
  if ! {{ssh-run}} test -f {{deploy_bin}}/{{DEPLOY_PROJECT_NAME}}.{{hash}}; then
    {{ssh-run}} sudo cp {{cache_dir}}/{{DEPLOY_PROJECT_NAME}} {{deploy_bin}}/{{DEPLOY_PROJECT_NAME}}.{{hash}}
    {{ssh-run}} sudo chmod +x {{deploy_bin}}/{{DEPLOY_PROJECT_NAME}}.{{hash}}
  fi
  {{ssh-run}} sudo ln -sfn {{deploy_bin}}/{{DEPLOY_PROJECT_NAME}}.{{hash}} {{deploy_bin}}/{{DEPLOY_PROJECT_NAME}}

  # Upload configs
  {{rsync}} {{generated_dir}}/app.caddy {{ssh_user_host}}:{{deploy_etc}}/caddy/sites.d/{{DEPLOY_PROJECT_NAME}}.caddy
  if [ -f "{{root}}/.env.production" ]; then
    {{rsync}} {{root}}/.env.production {{ssh_user_host}}:{{etc_dir}}/.env.production
  fi

  # Upload static files
  {{rsync}} {{public_dir}}/ {{ssh_user_host}}:{{www_dir}}/

setup-systemd: _ssh-open (_generate-config "app.service")
  @echo '{{ACCENT}}Updating systemd configuration{{RESET}}'

  {{rsync}} {{generated_dir}}/app.service {{ssh_user_host}}:/tmp/{{DEPLOY_PROJECT_NAME}}.service

  {{ssh-run}} sudo mv /tmp/{{DEPLOY_PROJECT_NAME}}.service /etc/systemd/system/{{DEPLOY_PROJECT_NAME}}.service

  {{systemctl}} daemon-reload
  {{systemctl}} enable {{DEPLOY_PROJECT_NAME}}

restart: _ssh-open
  @echo '{{ACCENT}}Restarting {{DEPLOY_PROJECT_NAME}}{{RESET}}'
  {{systemctl}} restart {{DEPLOY_PROJECT_NAME}}

start: _ssh-open
  {{systemctl}} start {{DEPLOY_PROJECT_NAME}}

stop: _ssh-open
  {{systemctl}} stop {{DEPLOY_PROJECT_NAME}}

status: _ssh-open
  {{systemctl}} status {{DEPLOY_PROJECT_NAME}}

logs *args: _ssh-open
  {{ssh-run}} journalctl -u {{DEPLOY_PROJECT_NAME}} {{args}}

deploy: caddy::require vector::require mc::require release-production upload setup-systemd restart status caddy::restart vector::restart
  @echo '{{ACCENT}}Deploy complete{{RESET}}'

version: _ssh-open
  @{{ssh-run}} "readlink {{deploy_bin}}/{{DEPLOY_PROJECT_NAME}} | sed 's|.*/||;s|^{{DEPLOY_PROJECT_NAME}}\.||'"

prune: _ssh-open
  #!/usr/bin/env bash
  set -euo pipefail

  echo '{{ACCENT}}Pruning old versions{{RESET}}'

  {{ssh-run}} 'ls -1t {{deploy_bin}}/{{DEPLOY_PROJECT_NAME}}.* 2>/dev/null | tail -n +4 | xargs -r sudo rm -f'

  echo '{{SUCCESS}}Done{{RESET}}'

uninstall: _ssh-open
  #!/usr/bin/env bash
  set -euo pipefail

  echo '{{WARNING}}Uninstalling {{DEPLOY_PROJECT_NAME}}...{{RESET}}'

  {{systemctl}} stop {{DEPLOY_PROJECT_NAME}} || true
  {{systemctl}} disable {{DEPLOY_PROJECT_NAME}} || true

  {{ssh-run}} sudo rm -f /etc/systemd/system/{{DEPLOY_PROJECT_NAME}}.service
  {{ssh-run}} sudo rm -f {{deploy_bin}}/{{DEPLOY_PROJECT_NAME}} {{deploy_bin}}/{{DEPLOY_PROJECT_NAME}}.*
  {{ssh-run}} sudo rm -rf {{etc_dir}} {{www_dir}} {{lib_dir}}

  {{systemctl}} daemon-reload

  echo '{{SUCCESS}}{{DEPLOY_PROJECT_NAME}} uninstalled{{RESET}}'
