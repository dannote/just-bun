import "../colors.just"

# Test container management
mod vm "./vm.just"

root_dir := justfile_directory()
e2e_dir := root_dir + "/recipes/e2e"
tests_dir := e2e_dir + "/tests"
env_file := e2e_dir + "/fixtures/.env.e2e"

# Prepare binaries required by the selected suite
[arg('suite', pattern='all|deploy|forgejo|litestream')]
_prepare suite:
    #!/usr/bin/env bash
    set -euo pipefail
    cd "{{ root_dir }}"
    set -a && source "{{ env_file }}" && set +a
    export REPO_OS="${DEPLOY_TARGET%%-*}"
    export REPO_ARCH="${DEPLOY_TARGET#*-}"

    case "{{ suite }}" in
      all) just repo collect-all && just app release "$DEPLOY_TARGET" ;;
      deploy)
        just repo caddy collect
        just repo mc collect
        just repo vector collect
        just app release "$DEPLOY_TARGET"
        ;;
      forgejo) just repo forgejo collect ;;
      litestream) just repo litestream collect ;;
    esac

# Run e2e tests from a clean checkout
[arg('suite', pattern='all|deploy|forgejo|litestream', help='Test suite to run')]
test suite="all": (_prepare suite) vm::up
    #!/usr/bin/env bash
    cd "{{ root_dir }}"

    # Load e2e environment
    set -a && source "{{ env_file }}" && set +a

    # Resolve relative SSH key path
    if [[ "$DEPLOY_SSH_KEY" != /* ]]; then
      export DEPLOY_SSH_KEY="$PWD/$DEPLOY_SSH_KEY"
    fi

    if [ "{{ suite }}" = "all" ]; then
      bats "{{ tests_dir }}"/*.bats
    else
      bats "{{ tests_dir }}/{{ suite }}.bats"
    fi

# Cleanup test container
clean: vm::down

# SSH into the test container
ssh *args:
    @just e2e::vm::ssh {{ args }}
