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
    just _justfile-format

# Check all Just modules are canonically formatted
_justfile-format-check:
    #!/usr/bin/env bash
    set -euo pipefail

    while IFS= read -r file; do
      just --justfile "$file" --fmt --check
    done < <(find Justfile recipes -type f \( -name 'Justfile' -o -name '*.just' \) | sort)

# Format all Just modules
_justfile-format:
    #!/usr/bin/env bash
    set -euo pipefail

    while IFS= read -r file; do
      just --justfile "$file" --fmt
    done < <(find Justfile recipes -type f \( -name 'Justfile' -o -name '*.just' \) | sort)

# Lint code with Biome and oxlint
lint *args:
    {{ bun }} run lint {{ args }}
    just _justfile-format-check

# Run tests
[arg('parallel', long, short='p', value='true', help='Run test files in parallel')]
test parallel='false' *args:
    {{ bun }} run test {{ if parallel == 'true' { '--parallel' } else { '' } }} {{ args }}
