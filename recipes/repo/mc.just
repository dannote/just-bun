import "../colors.just"

desc := "MinIO client for S3-compatible storage"
root := justfile_directory()

os := env('REPO_OS', 'linux')
arch := env('REPO_ARCH', 'amd64')
version := env('MC_VERSION', '2025-08-13T08-35-41Z')

platform := os + "-" + arch
repo_path := root + "/repo/" + os + "/" + arch
staging_path := repo_path + "/.staging/mc"
binary_path := repo_path + "/mc." + version

base_url := "https://dl.min.io/client/mc/release/" + platform + "/archive"
binary_url := base_url + "/mc.RELEASE." + version
checksum_url := binary_url + ".sha256sum"

info:
  @echo 'mc {{version}} - {{desc}}'

verify:
  @just repo _verify-bin mc {{version}}

collect: _download _verify-vendor
  #!/usr/bin/env bash
  set -euo pipefail

  if [ -f "{{binary_path}}" ]; then
    exit 0
  fi

  mv {{staging_path}}/mc {{binary_path}}
  chmod +x {{binary_path}}

  # Store vendor checksum for future verification
  awk '{print $1}' {{staging_path}}/mc.sha256sum > {{binary_path}}.sig

  rm -rf {{staging_path}}
  echo '{{SUCCESS}}Collected mc.{{version}}{{RESET}}'

_download:
  #!/usr/bin/env bash
  set -euo pipefail

  if [ -f "{{binary_path}}" ]; then
    echo '{{MUTED}}mc.{{version}} exists, skipping{{RESET}}'
    exit 0
  fi

  echo '{{ACCENT}}Downloading mc {{version}} ({{platform}})...{{RESET}}'

  mkdir -p {{staging_path}}
  curl -fsSL {{binary_url}} -o {{staging_path}}/mc
  curl -fsSL {{checksum_url}} -o {{staging_path}}/mc.sha256sum

_verify-vendor:
  #!/usr/bin/env bash
  set -euo pipefail

  if [ -f "{{binary_path}}" ]; then
    exit 0
  fi

  expected=$(awk '{print $1}' {{staging_path}}/mc.sha256sum)
  actual=$($SHA256 {{staging_path}}/mc | awk '{print $1}')

  if [ "$expected" != "$actual" ]; then
    echo '{{ERROR}}Checksum mismatch!{{RESET}}'
    rm -rf {{staging_path}}
    exit 1
  fi

  echo '{{SUCCESS}}Verified against vendor checksum (SHA256){{RESET}}'
