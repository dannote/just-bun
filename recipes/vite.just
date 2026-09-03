bun := "bun --bun"

# Start development server
dev *args:
    {{ bun }} run dev {{ args }}

# Build for production
build *args:
    {{ bun }} run build {{ args }}

# Preview production build
preview *args:
    {{ bun }} run preview {{ args }}

# Format code with Biome
format *args:
    {{ bun }} run format {{ args }}
    just justfile-format

# Check all Just modules are canonically formatted
justfile-format-check:
    #!/usr/bin/env bash
    set -euo pipefail

    while IFS= read -r file; do
      just --justfile "$file" --fmt --check
    done < <(find Justfile recipes -type f \( -name 'Justfile' -o -name '*.just' \) | sort)

# Format all Just modules
justfile-format:
    #!/usr/bin/env bash
    set -euo pipefail

    while IFS= read -r file; do
      just --justfile "$file" --fmt
    done < <(find Justfile recipes -type f \( -name 'Justfile' -o -name '*.just' \) | sort)

# Lint code with Biome and oxlint
lint *args:
    {{ bun }} run lint {{ args }}
    just justfile-format-check

# Run tests
[arg('parallel', long, short='p', value='true', help='Run test files in parallel')]
test parallel='false' *args:
    {{ bun }} run test {{ if parallel == 'true' { '--parallel' } else { '' } }} {{ args }}

# Run a production CPU profile and write a Markdown report
[arg('seconds', pattern='[1-9][0-9]*', help='Profile duration in seconds')]
profile-cpu seconds='30': build
    #!/usr/bin/env bash
    set -euo pipefail

    mkdir -p profiles
    timeout={{ seconds }}
    bun --cpu-prof-md --cpu-prof-dir profiles .output/server/index.mjs &
    pid=$!
    sleep "$timeout"
    kill -INT "$pid"
    wait "$pid" || true

# Run a production heap profile and write a Markdown report
[arg('seconds', pattern='[1-9][0-9]*', help='Profile duration in seconds')]
profile-heap seconds='30': build
    #!/usr/bin/env bash
    set -euo pipefail

    mkdir -p profiles
    timeout={{ seconds }}
    bun --heap-prof-md --heap-prof-dir profiles .output/server/index.mjs &
    pid=$!
    sleep "$timeout"
    kill -INT "$pid"
    wait "$pid" || true
