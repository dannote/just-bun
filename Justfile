set minimum-version := '1.58.0'
set default-list
set dotenv-load

set unstable
set lists
set script-interpreter := ['bun', '--bun', 'run']

import "recipes/ssh.just"
import "recipes/vite.just"
import "recipes/bun.just"

# Caddy reverse proxy management
[group('accessories')]
mod caddy "recipes/accessories/caddy.just"
# Forgejo Git forge management
[group('accessories')]
mod forgejo "recipes/accessories/forgejo.just"
# Litestream SQLite replication management
[group('accessories')]
mod litestream "recipes/accessories/litestream.just"
# Vector log aggregator management
[group('accessories')]
mod vector "recipes/accessories/vector.just"
# Gatus health monitoring
[group('accessories')]
mod gatus "recipes/accessories/gatus.just"
# MinIO client management
[group('accessories')]
mod mc "recipes/accessories/mc.just"
# Typst document compiler
[group('accessories')]
mod typst "recipes/accessories/typst.just"
# Application deployment and management
[group('deployment')]
mod app "recipes/app.just"
# Database migrations
[group('development')]
mod db "recipes/db.just"
# shadcn-vue components
[group('development')]
mod shadcn "recipes/shadcn.just"
# Binary repository management
[group('deployment')]
mod repo "recipes/repo.just"
# Host discovery and management
[group('deployment')]
mod host "recipes/host.just"
# End-to-end deployment tests
[group('testing')]
mod e2e "recipes/e2e/e2e.just"

alias install := app::install
alias release := app::release
alias deploy := app::deploy

# Open SSH session to deploy target
[group('deployment')]
ssh: _ssh-open
    - {{ ssh-run }}

# Example script recipe
[group('development')]
[script]
example:
    import { $ } from "bun"

    console.log("This is how to run a JS script")

    await $`echo "Hello from shell"`
