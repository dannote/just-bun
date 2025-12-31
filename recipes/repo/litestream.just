import "../colors.just"

desc := "Streaming SQLite replication to S3"
root := justfile_directory()

os := env('REPO_OS', 'linux')
arch := env('REPO_ARCH', 'amd64')
version := env('LITESTREAM_VERSION', '0.5.5')

# Litestream uses x86_64 not amd64
litestream_arch := if arch == "amd64" { "x86_64" } else { arch }
platform := os + "-" + litestream_arch
repo_path := root + "/repo/" + os + "/" + arch
staging_path := repo_path + "/.staging/litestream"
binary_path := repo_path + "/litestream." + version

base_url := "https://github.com/benbjohnson/litestream/releases/download/v" + version
archive_name := "litestream-" + version + "-" + platform + ".tar.gz"
archive_url := base_url + "/" + archive_name
checksums_url := base_url + "/checksums.txt"

info:
  @echo 'litestream {{version}} - {{desc}}'

verify:
  @just repo _verify-bin litestream {{version}}

collect: _download _verify-vendor
  #!/usr/bin/env bash
  set -euo pipefail

  if [ -f "{{binary_path}}" ]; then
    exit 0
  fi

  mv {{staging_path}}/litestream {{binary_path}}
  chmod +x {{binary_path}}

  # Store vendor checksum for future verification
  grep "{{archive_name}}" {{staging_path}}/checksums.txt | awk '{print $1}' > {{binary_path}}.sig

  rm -rf {{staging_path}}
  echo '{{SUCCESS}}Collected litestream.{{version}}{{RESET}}'

_download:
  #!/usr/bin/env bash
  set -euo pipefail

  if [ -f "{{binary_path}}" ]; then
    echo '{{MUTED}}litestream.{{version}} exists, skipping{{RESET}}'
    exit 0
  fi

  echo '{{ACCENT}}Downloading litestream {{version}} ({{platform}})...{{RESET}}'

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

  expected=$(grep "{{archive_name}}$" {{staging_path}}/checksums.txt | awk '{print $1}')
  actual=$($SHA256 {{staging_path}}/archive.tar.gz | awk '{print $1}')

  if [ "$expected" != "$actual" ]; then
    echo '{{ERROR}}Checksum mismatch!{{RESET}}'
    rm -rf {{staging_path}}
    exit 1
  fi

  echo '{{SUCCESS}}Verified against vendor checksum (SHA256){{RESET}}'
