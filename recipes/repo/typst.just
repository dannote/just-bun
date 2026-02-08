import "../colors.just"

desc := "Markup-based typesetting system"
root := justfile_directory()

os := env('REPO_OS', 'linux')
arch := env('REPO_ARCH', 'amd64')
version := env('TYPST_VERSION', '0.14.2')

musl_arch := if arch == "amd64" { "x86_64" } else { "aarch64" }
darwin_arch := if arch == "amd64" { "x86_64" } else { "aarch64" }
platform := if os == "darwin" { darwin_arch + "-apple-darwin" } else { musl_arch + "-unknown-linux-musl" }

repo_path := root + "/repo/" + os + "/" + arch
staging_path := repo_path + "/.staging/typst"
binary_path := repo_path + "/typst." + version

base_url := "https://github.com/typst/typst/releases/download/v" + version
archive_url := base_url + "/typst-" + platform + ".tar.xz"

info:
  @echo 'typst {{version}} - {{desc}}'

verify:
  @just repo _verify-bin typst {{version}}

collect: _download _compute-checksum
  #!/usr/bin/env bash
  set -euo pipefail

  if [ -f "{{binary_path}}" ]; then
    exit 0
  fi

  mv {{staging_path}}/typst-{{platform}}/typst {{binary_path}}
  chmod +x {{binary_path}}

  cat {{staging_path}}/checksum > {{binary_path}}.sig

  rm -rf {{staging_path}}
  echo '{{SUCCESS}}Collected typst.{{version}}{{RESET}}'

_download:
  #!/usr/bin/env bash
  set -euo pipefail

  if [ -f "{{binary_path}}" ]; then
    echo '{{MUTED}}typst.{{version}} exists, skipping{{RESET}}'
    exit 0
  fi

  echo '{{ACCENT}}Downloading typst {{version}} ({{platform}})...{{RESET}}'

  mkdir -p {{staging_path}}
  curl -fsSL {{archive_url}} -o {{staging_path}}/archive.tar.xz
  tar -xJf {{staging_path}}/archive.tar.xz -C {{staging_path}}

_compute-checksum:
  #!/usr/bin/env bash
  set -euo pipefail

  if [ -f "{{binary_path}}" ]; then
    exit 0
  fi

  $SHA256 {{staging_path}}/archive.tar.xz | awk '{print $1}' > {{staging_path}}/checksum
