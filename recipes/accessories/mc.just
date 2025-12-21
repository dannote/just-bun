import "../ssh.just"
import "../colors.just"

root := justfile_directory()

version := env('MC_VERSION', '2025-08-13T08-35-41Z')
repo_path := root + "/repo/linux/amd64"

export DEPLOY_BIN := deploy_bin

require: _ssh-open
  #!/usr/bin/env bash
  set -euo pipefail

  if {{ssh-run}} test -x {{deploy_bin}}/mc; then
    echo '{{SUCCESS}}mc installed at {{deploy_bin}}/mc{{RESET}}'
    exit 0
  fi

  echo '{{WARNING}}mc not found, installing...{{RESET}}'
  just mc deploy

deploy: _ssh-open
  {{rsync}} {{repo_path}}/mc.{{version}} {{ssh_user_host}}:/tmp/mc.{{version}}

  {{ssh-run}} sudo mv /tmp/mc.{{version}} {{deploy_bin}}/mc.{{version}}
  {{ssh-run}} sudo chmod +x {{deploy_bin}}/mc.{{version}}
  {{ssh-run}} sudo ln -sfn {{deploy_bin}}/mc.{{version}} {{deploy_bin}}/mc

  echo '{{SUCCESS}}mc deployed{{RESET}}'

uninstall: _ssh-open
  #!/usr/bin/env bash
  set -euo pipefail

  echo '{{WARNING}}Uninstalling mc...{{RESET}}'

  {{ssh-run}} sudo rm -f {{deploy_bin}}/mc {{deploy_bin}}/mc.*

  echo '{{SUCCESS}}mc uninstalled{{RESET}}'
