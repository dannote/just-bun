import "./colors.just"

bun:
  #!/usr/bin/env bash

  if command -v bun >/dev/null; then
    echo '{{SUCCESS}}Bun is already installed.{{RESET}}'
  else
    echo '{{ACCENT}}Installing Bun{{RESET}}'

    curl -fsSL https://bun.sh/install | bash
  fi
