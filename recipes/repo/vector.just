import "../colors.just"

desc := "Observability data pipeline"
root := justfile_directory()

os := env('REPO_OS', 'linux')
arch := env('REPO_ARCH', 'amd64')
version := env('VECTOR_VERSION', '0.52.0')

# Vector platform: x86_64-unknown-linux-gnu or arm64-apple-darwin
gnu_arch := if arch == "amd64" { "x86_64" } else if os == "darwin" { "arm64" } else { "aarch64" }
platform := if os == "darwin" { gnu_arch + "-apple-darwin" } else { gnu_arch + "-unknown-linux-gnu" }

repo_path := root + "/repo/" + os + "/" + arch
staging_path := repo_path + "/.staging/vector"
binary_path := repo_path + "/vector." + version

base_url := "https://github.com/vectordotdev/vector/releases/download/v" + version
archive_url := base_url + "/vector-" + version + "-" + platform + ".tar.gz"

info:
  @echo 'vector {{version}} - {{desc}}'

verify:
  @just repo _verify-bin vector {{version}}

# Vector doesn't provide vendor checksums, so we compute our own
collect: _download _compute-checksum
  #!/usr/bin/env bash
  set -euo pipefail

  if [ -f "{{binary_path}}" ]; then
    exit 0
  fi

  mv {{staging_path}}/vector-{{platform}}/bin/vector {{binary_path}}
  chmod +x {{binary_path}}

  # Store computed checksum
  cat {{staging_path}}/checksum > {{binary_path}}.sig

  rm -rf {{staging_path}}
  echo '{{SUCCESS}}Collected vector.{{version}}{{RESET}}'

_download:
  #!/usr/bin/env bash
  set -euo pipefail

  if [ -f "{{binary_path}}" ]; then
    echo '{{MUTED}}vector.{{version}} exists, skipping{{RESET}}'
    exit 0
  fi

  echo '{{ACCENT}}Downloading vector {{version}} ({{platform}})...{{RESET}}'

  mkdir -p {{staging_path}}
  curl -fsSL {{archive_url}} -o {{staging_path}}/archive.tar.gz
  tar -xzf {{staging_path}}/archive.tar.gz -C {{staging_path}}

_compute-checksum:
  #!/usr/bin/env bash
  set -euo pipefail

  if [ -f "{{binary_path}}" ]; then
    exit 0
  fi

  $SHA256 {{staging_path}}/archive.tar.gz | awk '{print $1}' > {{staging_path}}/checksum
  echo '{{MUTED}}Computed checksum (SHA256) - no vendor signature available{{RESET}}'
