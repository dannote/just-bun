import "../colors.just"

# Test container management
mod vm "./vm.just"

root_dir := justfile_directory()
e2e_dir := root_dir + "/recipes/e2e"
tests_dir := e2e_dir + "/tests"
env_file := e2e_dir + "/fixtures/.env.e2e"

# Run e2e tests (use suite=deploy or suite=forgejo to run specific tests)
test suite="all": vm::up
  #!/usr/bin/env bash
  cd "{{root_dir}}"

  # Load e2e environment
  set -a && source "{{env_file}}" && set +a

  # Resolve relative SSH key path
  if [[ "$DEPLOY_SSH_KEY" != /* ]]; then
    export DEPLOY_SSH_KEY="$PWD/$DEPLOY_SSH_KEY"
  fi

  if [ "{{suite}}" = "all" ]; then
    bats "{{tests_dir}}"/*.bats
  else
    bats "{{tests_dir}}/{{suite}}.bats"
  fi

# Cleanup test container
clean: vm::down

# SSH into the test container
ssh *args:
  @just e2e::vm::ssh {{args}}
