import "../colors.just"
import "./common.just"

desc := "Self-hosted Git forge"
version := forgejo_version

platform := os + "-" + arch
staging_path := repo_staging_path('forgejo')
binary_path := repo_binary_path('forgejo', version)

base_url := "https://codeberg.org/forgejo/forgejo/releases/download/v" + version
binary_name := "forgejo-" + version + "-" + platform
binary_url := base_url + "/" + binary_name
checksum_url := binary_url + ".sha256"

info:
    @echo 'forgejo {{ version }} - {{ desc }}'

verify:
    @just repo _verify-bin forgejo {{ version }}

collect: _download _verify-vendor
    #!/usr/bin/env bash
    set -euo pipefail

    if [ -f "{{ binary_path }}" ]; then
      exit 0
    fi

    mv {{ staging_path }}/forgejo {{ binary_path }}
    chmod +x {{ binary_path }}

    # Store vendor checksum for future verification
    awk '{print $1}' {{ staging_path }}/forgejo.sha256 > {{ binary_path }}.sig

    rm -rf {{ staging_path }}
    echo '{{ SUCCESS }}Collected forgejo.{{ version }}{{ RESET }}'

_download:
    #!/usr/bin/env bash
    set -euo pipefail

    if [ -f "{{ binary_path }}" ]; then
      echo '{{ MUTED }}forgejo.{{ version }} exists, skipping{{ RESET }}'
      exit 0
    fi

    if [ "{{ os }}" != "linux" ]; then
      echo '{{ MUTED }}forgejo only available for linux, skipping{{ RESET }}'
      exit 0
    fi

    echo '{{ ACCENT }}Downloading forgejo {{ version }} ({{ platform }})...{{ RESET }}'

    mkdir -p {{ staging_path }}
    {{ curl_http1 }} {{ binary_url }} -o {{ staging_path }}/forgejo
    {{ curl_http1 }} {{ checksum_url }} -o {{ staging_path }}/forgejo.sha256

_verify-vendor:
    #!/usr/bin/env bash
    set -euo pipefail

    if [ -f "{{ binary_path }}" ]; then
      exit 0
    fi

    if [ "{{ os }}" != "linux" ]; then
      exit 0
    fi

    expected=$(awk '{print $1}' {{ staging_path }}/forgejo.sha256)
    actual=$($SHA256 {{ staging_path }}/forgejo | awk '{print $1}')

    if [ "$expected" != "$actual" ]; then
      echo '{{ ERROR }}Checksum mismatch!{{ RESET }}'
      rm -rf {{ staging_path }}
      exit 1
    fi

    echo '{{ SUCCESS }}Verified against vendor checksum (SHA256){{ RESET }}'
