service_name := "gatus"

set unstable

import "./service.just"
import "../config.just"
import "../accessory.just"
import "../versions.just"

version := gatus_version
repo_path := accessory_repo_path

etc_dir := deploy_etc + "/gatus"
lib_dir := deploy_lib + "/gatus"

# Ensure Gatus is installed
require: _ssh-open
    #!/usr/bin/env bash
    set -euo pipefail

    if {{ ssh-run }} test -x {{ deploy_bin }}/gatus; then
      echo '{{ SUCCESS }}Gatus installed at {{ deploy_bin }}/gatus{{ RESET }}'
      exit 0
    fi

    echo '{{ WARNING }}Gatus not found, installing...{{ RESET }}'
    just gatus deploy

# Build Gatus from source for the deployment target
[cache(extra=DEPLOY_TARGET + ':' + version, outputs=repo_path + '/gatus.' + version)]
[env('CGO_ENABLED', '0')]
build:
    #!/usr/bin/env bash
    set -euo pipefail

    IFS='-' read -r goos arch <<< "$DEPLOY_TARGET"
    [[ "$arch" == "arm64" ]] && arch="arm64"
    [[ "$arch" == "amd64" ]] && arch="amd64"

    echo '{{ ACCENT }}Building Gatus {{ version }} for '"$goos/$arch"'...{{ RESET }}'

    tmpdir=$(mktemp -d)
    trap "rm -rf $tmpdir" EXIT

    git clone --depth 1 --branch v{{ version }} https://github.com/TwiN/gatus.git "$tmpdir/gatus"
    cd "$tmpdir/gatus"

    GOOS="$goos" GOARCH="$arch" go build -ldflags="-s -w" -o "{{ repo_path }}/gatus.{{ version }}" .

    echo '{{ SUCCESS }}Built {{ repo_path }}/gatus.{{ version }}{{ RESET }}'

# Upload Gatus binary to server
upload: _ssh-open
    {{ ssh-run }} sudo mkdir -p {{ etc_dir }} {{ lib_dir }}
    {{ ssh-run }} sudo chown $DEPLOY_USER:$DEPLOY_GROUP {{ lib_dir }}

    {{ rsync }} {{ repo_path }}/gatus.{{ version }} {{ ssh_user_host }}:/tmp/gatus.{{ version }}

    {{ ssh-run }} sudo mv /tmp/gatus.{{ version }} {{ deploy_bin }}/gatus.{{ version }}
    {{ ssh-run }} sudo chmod +x {{ deploy_bin }}/gatus.{{ version }}
    {{ ssh-run }} sudo ln -sfn {{ deploy_bin }}/gatus.{{ version }} {{ deploy_bin }}/gatus

# Install systemd service
setup-systemd: _ssh-open (_generate-config "gatus.service") (_generate-config "gatus.yaml")
    {{ rsync }} {{ generated_dir }}/gatus.service {{ ssh_user_host }}:/tmp/gatus.service
    {{ rsync }} {{ generated_dir }}/gatus.yaml {{ ssh_user_host }}:/tmp/gatus.yaml

    {{ ssh-run }} sudo mv /tmp/gatus.service /etc/systemd/system/gatus.service
    {{ ssh-run }} sudo mv /tmp/gatus.yaml {{ etc_dir }}/gatus.yaml

    {{ systemctl }} daemon-reload
    {{ systemctl }} enable gatus

# Deploy Gatus to server
deploy: upload setup-systemd

# Remove Gatus from server
[confirm('Uninstall gatus and remove all of its data?')]
uninstall: _ssh-open
    #!/usr/bin/env bash
    set -euo pipefail

    echo '{{ WARNING }}Uninstalling Gatus...{{ RESET }}'

    {{ systemctl }} stop gatus || true
    {{ systemctl }} disable gatus || true

    {{ ssh-run }} sudo rm -f /etc/systemd/system/gatus.service
    {{ ssh-run }} sudo rm -f {{ deploy_bin }}/gatus {{ deploy_bin }}/gatus.*
    {{ ssh-run }} sudo rm -rf {{ etc_dir }} {{ lib_dir }}

    {{ systemctl }} daemon-reload

    echo '{{ SUCCESS }}Gatus uninstalled{{ RESET }}'
