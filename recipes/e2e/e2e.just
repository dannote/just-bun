import "../colors.just"

mod vm "./vm.just"

root_dir := justfile_directory()
e2e_dir := root_dir + "/recipes/e2e"
tests_dir := e2e_dir + "/tests"

# Load e2e environment for app commands
_load-env:
  @cp "{{e2e_dir}}/fixtures/.env.e2e" "{{root_dir}}/.env.e2e"

# Run e2e tests
test: vm::up _load-env
  #!/usr/bin/env bash
  set -euo pipefail

  cd "{{root_dir}}"
  set -a && source .env.e2e && set +a

  # Resolve relative SSH key path relative to project root
  if [[ "$DEPLOY_SSH_KEY" != /* ]]; then
    export DEPLOY_SSH_KEY="$PWD/$DEPLOY_SSH_KEY"
  fi

  bats "{{tests_dir}}/deploy.bats"

# Cleanup after tests
clean: vm::down
  rm -f "{{root_dir}}/.env.e2e"
