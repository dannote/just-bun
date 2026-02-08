set dotenv-load

set unstable
set script-interpreter := ['bun', '--bun', 'run']

import "recipes/ssh.just"
import "recipes/vite.just"
import "recipes/bun.just"

# Caddy reverse proxy management
mod caddy "recipes/accessories/caddy.just"
# Forgejo Git forge management
mod forgejo "recipes/accessories/forgejo.just"
# Litestream SQLite replication management
mod litestream "recipes/accessories/litestream.just"
# Vector log aggregator management
mod vector "recipes/accessories/vector.just"
# Gatus health monitoring
mod gatus "recipes/accessories/gatus.just"
# MinIO client management
mod mc "recipes/accessories/mc.just"
# Application deployment and management
mod app "recipes/app.just"
# Database migrations
mod db "recipes/db.just"
# shadcn-vue components
mod shadcn "recipes/shadcn.just"
# Binary repository management
mod repo "recipes/repo.just"
# Host discovery and management
mod host "recipes/host.just"
# End-to-end deployment tests
mod e2e "recipes/e2e/e2e.just"

alias install := app::install
alias release := app::release
alias deploy := app::deploy

# Open SSH session to deploy target
ssh: _ssh-open
  - {{ssh-run}}

# Example script recipe
[script]
example:
  import { $ } from "bun"

  console.log("This is how to run a JS script")

  await $`echo "Hello from shell"`
