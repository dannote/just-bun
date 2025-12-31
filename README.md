# Just Bun! — Opinionated Bun + Elysia + Vue Starter

Skip Docker pulls. Ship a single Bun binary with a Vue frontend, using Bun's
bundler, test runner, and SQLite.

<p>
  <img src="app/assets/logos/bun.svg" alt="Bun logo" width="64" />
  <img src="app/assets/logos/vite.svg" alt="Vite logo" width="64" />
  <img src="app/assets/logos/vue.svg" alt="Vue logo" width="64" />
  <img src="app/assets/logos/elysia.svg" alt="Elysia logo" width="64" />
  <img src="app/assets/logos/arktype.svg" alt="ArkType logo" width="64" />
  <img src="app/assets/logos/shadcn-vue.svg" alt="shadcn-vue logo" width="64" />
  <img src="app/assets/logos/reka-ui.svg" alt="Reka UI logo" width="64" />
  <img src="app/assets/logos/cva.svg" alt="CVA logo" width="64" />
</p>

## Motivation
I was tired of slow Docker builds and container registries for every small change. This starter leans on [Bun](https://bun.sh) and [Vite](https://vite.dev) to ship a single binary with a Vue 3 frontend.

## Why this starter
- Bun-native toolchain: built-in bundler, `bun:test`, `bun:sqlite`, `Bun.serve`, and an S3-friendly runtime so you ship more with fewer deps—no extra SDKs required.
- Fast API layer: [Elysia](https://elysiajs.com) + [ArkType](https://arktype.io) give typed routes that stay close to the edge.
- Modern UI: [Vue 3](https://vuejs.org) SFCs with auto-routed pages, [shadcn-vue](https://www.shadcn-vue.com) + [Reka UI](https://reka-ui.com) primitives, and [CVA](https://beta.cva.style)-driven variants.
- Minimal DevOps: build a single executable, [rsync](https://rsync.samba.org), and let [systemd](https://systemd.io) + [Caddy](https://caddyserver.com) keep it running—no images or registries required.

## Getting started
The shortest path is: install `just`, run `just bun`, and start the dev server. You can scaffold with Bun or clone the repo.

**Using `bun create`**

```bash
bun create dannote/just-bun my-app
```

**Cloning directly**

```bash
just install
cp .env.example .env.local
just dev
```

When you're ready to ship, create a production env file:

```bash
cp .env.example .env.production
```

## Environment
- `.env.local` is for local development.
- `.env.production` is read at deploy time.
- `.env.example` documents the full set; copy from it instead of committing secrets.

Key variables:
- `DEPLOY_HOST`, `DEPLOY_USER`, `DEPLOY_GROUP`: SSH target for rsync/systemd.
- `DEPLOY_PROJECT_NAME`, `DEPLOY_TARGET`: control where the compiled binary lands and which Bun target to build.

## Just setup
Install [`just`](https://just.systems) first—installing `just` lets you run `just bun`, which installs Bun for you, so you literally install just to install bun and end up with Just Bun!. One straight-line way to see it:

```
# Install Just
curl https://just.systems/install.sh | bash -s -- --to /usr/local/bin

# Install Bun
just bun

# Deploy
just deploy
```

Prefer packages? Grab `just` via:

- macOS: `brew install just`
- Ubuntu: `sudo apt-get install just`
- Fedora: `sudo dnf install just`
- Other distros: see the package list at [just.systems/man/en/packages](https://just.systems/man/en/packages.html).

After installing `just`, run `just bun` to fetch Bun if it is not on your PATH. Verify `just --version`, then explore available tasks with `just --list`. Read the full docs at [just.systems/man](https://just.systems/man/en/) if you want to extend the taskfile.

## Commands
- `just bun` — install Bun if it is not already available.
- `just dev` — run the full stack locally.
- `just build` — [Vite](https://vite.dev) build + [Nitro](https://nitro.unjs.io) output.
- `just test` — bun:test example suite.
- `just format` / `just lint` — [Biome](https://biomejs.dev) + [oxlint](https://oxc-project.github.io/oxlint/) for consistency.
- `just app release` — compile the server to a static Bun binary in `releases/`.
- `just ssh` — open an interactive shell on the deploy target.
- `just repo collect|status|verify` — manage the local binary repository. See [The repository](#the-repository).
- `just app start|stop|restart|status` — manage the app service.
- `just app enable|disable` — enable or disable the app service without removing files.
- `just app logs <journalctl args>` — stream service logs like `just app logs -f`.
- `just app version` — show currently deployed version hash.
- `just app versions` — list all available versions on server.
- `just app rollback [hash]` — rollback to previous version or a specific hash.
- `just app prune` — remove old binary versions, keeping latest 3.
- `just app uninstall` — remove service, configs, binaries, and all app data.
- `just db migrate|status|new|rollback` — manage database migrations with [Kysely](https://kysely.dev).
- `just host apps` — list all apps deployed on the server.
- `just host databases` — list all SQLite databases on the server.
- `just host services` — list running app services on the server.
- `just deploy` — build, upload, and restart everything in one command.

## End-to-end tests

The deployment workflow has a lot of moving parts: building binaries, uploading via rsync, managing symlinks, configuring systemd, and coordinating restarts. To verify everything works together, the `recipes/e2e/` directory contains a full end-to-end test suite.

The tests spin up a Fedora container with systemd using Docker that mimics a real production server. They then run through the entire deployment lifecycle—build, release, upload, service setup, start/stop, rollback, and cleanup—verifying each step works correctly. This catches integration issues that unit tests miss, like permission problems, missing dependencies, or broken systemd configurations.

Tests are written in [Bats](https://github.com/bats-core/bats-core), the Bash Automated Testing System, which keeps them readable and close to the actual shell commands you'd run manually. Run `just e2e test` to execute the full suite, or use `just e2e ssh` to drop into the test container for debugging.

- `just e2e test` — run all e2e tests against a local container.
- `just e2e test deploy` — run only deployment tests.
- `just e2e test forgejo` — run only Forgejo tests.
- `just e2e test litestream` — run only Litestream replication tests (starts MinIO S3).
- `just e2e clean` — tear down the test container.
- `just e2e ssh` — SSH into the test container for debugging.

## Deployment
This starter compiles the backend into a single executable with [`bun build --compile`](https://bun.sh/docs/bundler/executables). Deployment uses [rsync](https://rsync.samba.org) with delta transfers—only changed bytes are uploaded, making iterative deploys fast even for large binaries. A symlink flip enables instant rollback to any previous version. [systemd](https://systemd.io) keeps the process healthy, and [Caddy](https://caddyserver.com) fronts it with automatic TLS.

Caddy fetches and renews Let's Encrypt certificates automatically for any configured domain as soon as DNS points at your server. Service templates live in `configs/`, keeping secrets out of version control.

The deployment follows standard [FHS](https://en.wikipedia.org/wiki/Filesystem_Hierarchy_Standard) paths:

```
/usr/local/bin/
├── just-bun -> just-bun.a1b2c3d      # symlink to current version
├── just-bun.a1b2c3d                  # current binary
├── just-bun.f4e5d6c                  # previous version (instant rollback)
├── caddy
├── forgejo
└── vector

/etc/
├── just-bun/
│   └── .env.production
├── caddy/
│   ├── Caddyfile
│   └── sites.d/
│       ├── just-bun.caddy
│       └── forgejo.caddy
├── forgejo/
│   └── app.ini
└── vector/
    └── vector.yaml

/var/www/just-bun/                    # static assets served by Caddy
├── index.html
├── favicon.svg
└── assets/

/var/lib/just-bun/                    # app working directory
└── app.db                            # SQLite database

/var/lib/forgejo/                     # Forgejo working directory
├── data/
│   ├── forgejo.db                    # Forgejo SQLite database
│   └── repositories/                 # Git repositories
└── custom/                           # custom templates and assets

/var/cache/just-bun/                  # rsync target for delta transfers
└── just-bun
```

## Accessories
Accessory services live under `recipes/accessories/` and follow the same
deploy-and-manage flow as the app: rsync a pinned binary, render configs from
`configs/`, and let systemd supervise it. They are intentionally optional, so
you can turn them on only when you need them. Caddy fronts the app with TLS and
static assets, Vector ships journald logs to S3, Litestream replicates SQLite
databases to S3, and Forgejo adds a self-hosted Git forge. Each one can be
deployed and managed independently via `just caddy`, `just litestream`,
`just vector`, or `just forgejo`.

- `just caddy deploy|start|stop|restart|status` — manage the Caddy reverse proxy.
- `just forgejo deploy|start|stop|restart|status` — manage the Forgejo Git forge.
- `just forgejo generate-secrets` — generate secrets for Forgejo's app.ini.
- `just forgejo add-remote [name]` — add Forgejo as Git remote for current repo.
- `just litestream deploy|start|stop|restart|status` — manage the Litestream replication.
- `just litestream restore [db]` — restore database from S3 (defaults to current app's DB).
- `just litestream snapshots [db]` — list snapshots (defaults to current app's DB).
- `just litestream databases` — show which databases are being replicated.
- `just vector deploy|start|stop|restart|status` — manage the Vector log aggregator.

## The repository

Docker solved dependency distribution by bundling everything into container images. But images are opaque blobs that hide what's actually running, require a registry to host, and add cold-start latency. This starter takes a different approach: static binaries distributed directly.

The `repo/` directory is a local binary repository organized by platform. Instead of pulling container images, you collect verified binaries once and rsync them to your servers:

```bash
just repo collect        # download and verify all binaries
just repo status         # see what's in your local repo
just repo verify         # re-verify checksums
```

Each binary is version-pinned and checksum-verified against upstream signatures. The repo structure mirrors target platforms, so you can cross-deploy from any development machine:

```
repo/
├── linux/
│   └── amd64/
│       ├── caddy.2.10.2
│       ├── caddy.2.10.2.sig
│       ├── forgejo.13.0.3
│       ├── forgejo.13.0.3.sig
│       ├── litestream.0.5.5
│       ├── litestream.0.5.5.sig
│       ├── vector.0.52.0
│       ├── vector.0.52.0.sig
│       └── just-bun.a1b2c3d
└── darwin/
    └── arm64/
        └── ...
```

This approach means you always know exactly what's running because it's right there in `repo/`, deployments are reproducible without network access to registries, and there's no container runtime overhead. Your app, Caddy, Vector, and any other tools are just executables managed by systemd.

## Stack highlights
- **[Bun](https://bun.sh) runtime**: fast start, built-in bundler, `bun:test`, `bun:sqlite`, native HTTP, and an S3-capable runtime without extra SDKs.
- **[Kysely](https://kysely.dev)**: type-safe SQL query builder with migrations, wired to `bun:sqlite`.
- **[Elysia](https://elysiajs.com) + [ArkType](https://arktype.io)**: ergonomic, typed HTTP handlers for the API surface.
- **[Vue 3](https://vuejs.org) SFC + [Vite](https://vite.dev)**: auto-routed pages, hot reload, and TypeScript-first ergonomics.
- **[shadcn-vue](https://www.shadcn-vue.com) + [Reka UI](https://reka-ui.com) + [CVA](https://beta.cva.style)**: accessible primitives with typed variants to keep props sane.
- **[Unhead](https://unhead.unjs.io)**: declarative head/meta management for Vue out of the box.
- **[Logtape](https://logtape.dev)**: structured logging wired for console in dev and syslog in production.
- **[OpenTelemetry](https://opentelemetry.io)**: distributed tracing with OTLP export to any compatible backend.
- **[Vector](https://vector.dev)**: log aggregation from journald with S3 export for observability.
- **[Litestream](https://litestream.io)**: streaming SQLite replication to S3—continuous backups without stopping writes.
- **[Forgejo](https://forgejo.org)**: self-hosted Git forge you can deploy as a single binary alongside your app.

## What you get out of the box
- A home page that showcases the stack and links you to the docs and API example.
- A typed `/api/hello` route you can extend.
- An example bun:test in `test/api.test.ts` to keep the lights green.
- Opinionated defaults for formatting, linting, and routing that stay out of your way.

## Philosophy
Keep the stack small, keep the feedback loop tight, and ship binaries instead of containers when you can. Lean on Bun's built-ins before adding dependencies, and prefer well-typed primitives (Elysia, ArkType, CVA, shadcn-vue) over bespoke glue.
