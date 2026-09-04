import "../colors.just"
import "../accessory.just"
import "../versions.just"

version := typst_version
repo_path := accessory_repo_path

# Ensure Typst is installed
require: _ssh-open
    #!/usr/bin/env bash
    set -euo pipefail
    if {{ ssh-run }} test -x {{ deploy_bin }}/typst; then
      echo '{{ SUCCESS }}Typst installed{{ RESET }}'
      exit 0
    fi
    echo '{{ WARNING }}Typst not found, installing...{{ RESET }}'
    just typst deploy

# Upload Typst binary to server
upload: _ssh-open
    {{ rsync }} {{ repo_path }}/typst.{{ version }} {{ ssh_user_host }}:/tmp/typst.{{ version }}

    {{ ssh-run }} sudo mv /tmp/typst.{{ version }} {{ deploy_bin }}/typst.{{ version }}
    {{ ssh-run }} sudo chmod +x {{ deploy_bin }}/typst.{{ version }}
    {{ ssh-run }} sudo ln -sfn {{ deploy_bin }}/typst.{{ version }} {{ deploy_bin }}/typst

# Deploy Typst to server
deploy: upload
    @echo '{{ SUCCESS }}Typst {{ version }} deployed{{ RESET }}'

# Remove Typst from server
[confirm('Uninstall typst and remove all of its data?')]
uninstall: _ssh-open
    #!/usr/bin/env bash
    set -euo pipefail
    echo '{{ WARNING }}Uninstalling Typst...{{ RESET }}'
    {{ ssh-run }} sudo rm -f {{ deploy_bin }}/typst {{ deploy_bin }}/typst.*
    echo '{{ SUCCESS }}Typst uninstalled{{ RESET }}'
