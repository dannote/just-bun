service_name := "vector"

import "./service.just"
import "../config.just"

version := env('VECTOR_VERSION', '0.52.0')
repo_path := root + "/repo/linux/amd64"

etc_dir := deploy_etc + "/vector"
lib_dir := deploy_lib + "/vector"

require: _ssh-open
  #!/usr/bin/env bash
  set -euo pipefail

  if {{ssh-run}} test -x {{deploy_bin}}/vector; then
    echo '{{SUCCESS}}Vector installed at {{deploy_bin}}/vector{{RESET}}'
    exit 0
  fi

  echo '{{WARNING}}Vector not found, installing...{{RESET}}'
  just vector deploy

upload: _ssh-open
  {{ssh-run}} sudo mkdir -p {{etc_dir}} {{lib_dir}}
  {{ssh-run}} sudo chown $DEPLOY_USER:$DEPLOY_GROUP {{lib_dir}}

  {{rsync}} {{repo_path}}/vector.{{version}} {{ssh_user_host}}:/tmp/vector.{{version}}

  {{ssh-run}} sudo mv /tmp/vector.{{version}} {{deploy_bin}}/vector.{{version}}
  {{ssh-run}} sudo chmod +x {{deploy_bin}}/vector.{{version}}
  {{ssh-run}} sudo ln -sfn {{deploy_bin}}/vector.{{version}} {{deploy_bin}}/vector

setup-systemd: _ssh-open (_generate-config "vector.service") (_generate-config "vector.yaml")
  {{rsync}} {{generated_dir}}/vector.service {{ssh_user_host}}:/tmp/vector.service
  {{rsync}} {{generated_dir}}/vector.yaml {{ssh_user_host}}:/tmp/vector.yaml

  {{ssh-run}} sudo mv /tmp/vector.service /etc/systemd/system/vector.service
  {{ssh-run}} sudo mv /tmp/vector.yaml {{etc_dir}}/vector.yaml

  {{systemctl}} daemon-reload
  {{systemctl}} enable vector

deploy: upload setup-systemd

uninstall: _ssh-open
  #!/usr/bin/env bash
  set -euo pipefail

  echo '{{WARNING}}Uninstalling Vector...{{RESET}}'

  {{systemctl}} stop vector || true
  {{systemctl}} disable vector || true

  {{ssh-run}} sudo rm -f /etc/systemd/system/vector.service
  {{ssh-run}} sudo rm -f {{deploy_bin}}/vector {{deploy_bin}}/vector.*
  {{ssh-run}} sudo rm -rf {{etc_dir}} {{lib_dir}}

  {{systemctl}} daemon-reload

  echo '{{SUCCESS}}Vector uninstalled{{RESET}}'
