set unstable
set script-interpreter := ['bun', '--bun', 'run']

import "./colors.just"

root := justfile_directory()
repo_dir := root + "/repo"

# Target configuration (override with REPO_OS=darwin REPO_ARCH=arm64)
export REPO_OS := env('REPO_OS', 'linux')
export REPO_ARCH := env('REPO_ARCH', 'amd64')

# Checksum commands (auto-detect platform)
export SHA256 := if `command -v sha256sum || true` != "" { "sha256sum" } else { "shasum -a 256" }
export SHA512 := if `command -v sha512sum || true` != "" { "sha512sum" } else { "shasum -a 512" }

repo_path := repo_dir + "/" + REPO_OS + "/" + REPO_ARCH

# Available apps (add new apps here and create recipes/repo/{name}.just)
apps := "caddy forgejo litestream mc typst vector"

alias list := info

# Show info about available binaries
info app='all':
  #!/usr/bin/env bash
  set -euo pipefail
  if [ "{{app}}" = "all" ]; then
    echo '{{ACCENT}}Available apps:{{RESET}}'
    for app in {{apps}}; do just repo $app info; done
  else
    just repo {{app}} info
  fi

# Download and verify binaries
collect app='all':
  #!/usr/bin/env bash
  set -euo pipefail
  if [ "{{app}}" = "all" ]; then
    echo '{{ACCENT}}Collecting all apps...{{RESET}}'
    for app in {{apps}}; do just repo $app collect; done
  else
    just repo {{app}} collect
  fi

# Verify binary checksums
verify app='all':
  #!/usr/bin/env bash
  set -euo pipefail
  if [ "{{app}}" = "all" ]; then
    echo '{{ACCENT}}Verifying all apps...{{RESET}}'
    for app in {{apps}}; do just repo $app verify; done
  else
    just repo {{app}} verify
  fi

# Collect and verify all binaries
build: (collect "all") (verify "all")
  @echo '{{SUCCESS}}Repo build complete{{RESET}}'

# Show repository contents
status:
  #!/usr/bin/env bash
  set -euo pipefail
  echo '{{ACCENT}}Repo ($REPO_OS/$REPO_ARCH):{{RESET}}'
  if [ -d "{{repo_path}}" ]; then
    ls -lh {{repo_path}}/ 2>/dev/null || echo '  (empty)'
  else
    echo '  (not initialized)'
  fi

# Shared verify logic
_verify-bin name version:
  #!/usr/bin/env bash
  set -euo pipefail
  bin="{{repo_path}}/{{name}}.{{version}}"
  if [ ! -f "$bin" ] || [ ! -f "$bin.sig" ]; then
    echo '{{ERROR}}{{name}}.{{version}} not found{{RESET}}'
    exit 1
  fi
  if [ -x "$bin" ]; then
    echo '{{SUCCESS}}{{name}}.{{version}} ok{{RESET}}'
  else
    echo '{{ERROR}}{{name}}.{{version}} not executable{{RESET}}'
    exit 1
  fi

# App modules (add new apps by creating recipes/repo/{name}.just)
mod caddy "./repo/caddy.just"
mod forgejo "./repo/forgejo.just"
mod litestream "./repo/litestream.just"
mod mc "./repo/mc.just"
mod typst "./repo/typst.just"
mod vector "./repo/vector.just"
