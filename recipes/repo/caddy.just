import "../colors.just"

desc := "Fast, multi-platform web server"
root := justfile_directory()

os := env('REPO_OS', 'linux')
arch := env('REPO_ARCH', 'amd64')
version := env('CADDY_VERSION', '2.10.2')

# Caddy uses 'mac' not 'darwin'
caddy_os := if os == "darwin" { "mac" } else { os }
platform := caddy_os + "_" + arch
repo_path := root + "/repo/" + os + "/" + arch
staging_path := repo_path + "/.staging/caddy"
binary_path := repo_path + "/caddy." + version

base_url := "https://github.com/caddyserver/caddy/releases/download/v" + version
archive_name := "caddy_" + version + "_" + platform + ".tar.gz"
archive_url := base_url + "/" + archive_name
checksums_url := base_url + "/caddy_" + version + "_checksums.txt"

info:
  @echo 'caddy {{version}} - {{desc}}'

verify:
  @just repo _verify-bin caddy {{version}}

collect: _download _verify-vendor
  #!/usr/bin/env bash
  set -euo pipefail

  if [ -f "{{binary_path}}" ]; then
    exit 0
  fi

  mv {{staging_path}}/caddy {{binary_path}}
  chmod +x {{binary_path}}

  # Store vendor checksum for future verification
  grep "{{archive_name}}" {{staging_path}}/checksums.txt | awk '{print $1}' > {{binary_path}}.sig

  rm -rf {{staging_path}}
  echo '{{SUCCESS}}Collected caddy.{{version}}{{RESET}}'

_download:
  #!/usr/bin/env bash
  set -euo pipefail

  if [ -f "{{binary_path}}" ]; then
    echo '{{MUTED}}caddy.{{version}} exists, skipping{{RESET}}'
    exit 0
  fi

  echo '{{ACCENT}}Downloading caddy {{version}} ({{platform}})...{{RESET}}'

  mkdir -p {{staging_path}}
  curl -fsSL {{archive_url}} -o {{staging_path}}/archive.tar.gz
  curl -fsSL {{checksums_url}} -o {{staging_path}}/checksums.txt
  tar -xzf {{staging_path}}/archive.tar.gz -C {{staging_path}}

_verify-vendor:
  #!/usr/bin/env bash
  set -euo pipefail

  if [ -f "{{binary_path}}" ]; then
    exit 0
  fi

  expected=$(grep "{{archive_name}}" {{staging_path}}/checksums.txt | awk '{print $1}')
  actual=$($SHA512 {{staging_path}}/archive.tar.gz | awk '{print $1}')

  if [ "$expected" != "$actual" ]; then
    echo '{{ERROR}}Checksum mismatch!{{RESET}}'
    rm -rf {{staging_path}}
    exit 1
  fi

  echo '{{SUCCESS}}Verified against vendor checksum (SHA512){{RESET}}'
