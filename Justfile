set dotenv-load

set unstable
set script-interpreter := ['bun', '--bun', 'run']

import "recipes/ssh.just"
import "recipes/vite.just"
import "recipes/bun.just"

mod caddy "recipes/caddy.just"
mod app "recipes/app.just"
mod shadcn "recipes/shadcn.just"

alias install := app::install
alias release := app::release
alias deploy := app::deploy

ssh: _ssh-open
  - {{ssh-run}}

[script]
example:
  import { $ } from "bun"

  console.log("This is how to run a JS script")

  await $`echo "Hello from shell"`
