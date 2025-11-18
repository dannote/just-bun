# Just Bun! — Opinionated Bun + Elysia + Vue Starter

Stop waiting on Docker pulls. Ship a Bun binary and a Vue SFC frontend with the
runtime's own bundler, test runner, and SQLite baked in.

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
I was tired of waiting on slow Docker builds and container registries for every small change. This starter leans on [Bun](https://bun.sh)'s batteries and [Vite](https://vite.dev)'s DX to ship an all-in-one binary and a clean [Vue 3](https://vuejs.org) SFC frontend without the Docker tax.

## Why this starter
- Bun-native toolchain: built-in bundler, `bun:test`, `bun:sqlite`, `Bun.serve`, and an S3-friendly runtime so you ship more with fewer deps—no extra SDKs required.
- Fast API layer: [Elysia](https://elysiajs.com) + [ArkType](https://arktype.io) give typed routes that stay close to the edge.
- Modern UI: [Vue 3](https://vuejs.org) SFCs with auto-routed pages, [shadcn-vue](https://www.shadcn-vue.com) + [Reka UI](https://reka-ui.com) primitives, and [CVA](https://beta.cva.style)-driven variants.
- Minimal DevOps: build a single executable, [rsync](https://rsync.samba.org), and let [systemd](https://systemd.io) + [Caddy](https://caddyserver.com) keep it running—no images or registries required.

## Getting started
Call it **Just Bun!** because the happy path is literally: install `just`, run `just bun`, and boom—you've got “Just Bun!”.

You can grab it directly with Bun or just™ clone it—your call.

**Using `bun create` (direct)**

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
- `DEPLOY_PROJECTS_DIR`, `DEPLOY_PROJECT_NAME`, `DEPLOY_TARGET`: control where the compiled binary lands and which Bun target to build.

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
- `just caddy deploy|start|stop|restart|status` — manage the Caddy reverse proxy helper.
- `just deploy` — alias of `app::deploy` to push a build to your server.

## Deployment (no Docker required)
This starter compiles the backend into a single executable with [`bun build --compile`](https://bun.sh/docs/bundler/executables). Deployment is a quick [rsync](https://rsync.samba.org) plus a symlink flip driven by the `recipes/app.just` targets. [systemd](https://systemd.io) keeps the process healthy, and [Caddy](https://caddyserver.com) (see `Caddyfile`) can front it with TLS. Roll back by pointing the symlink at the previous binary—no registries, layers, or cold image pulls.

Caddy will fetch and renew Let's Encrypt certificates automatically for any host
in the `Caddyfile` as soon as DNS points at your server; the first HTTPS check
may take a few seconds while ACME completes.

The generated `app.service` applies systemd hardening flags
(`ProtectSystem=strict`, `ProtectHome=yes`, `PrivateTmp=yes`,
`PrivateDevices=yes`, `ProtectKernelTunables=yes`, `ProtectKernelModules=yes`,
`ProtectControlGroups=yes`). Binaries live in `bin/`, config in `etc/`, and
static files in `public/`.

Here’s what the directory structure can look like on the server:

```
/opt
├── caddy
│   ├── Caddyfile
│   ├── caddy
│   └── caddy.service
└── projects
    └── just-bun
        ├── app.service
        ├── bin
        │   ├── server -> /opt/projects/just-bun/bin/server.f977374
        │   ├── server.433db9e
        │   ├── server.8503300
        │   ├── server.a6aa7bf
        │   ├── server.f78495a
        │   ├── server.f977374
        │   └── server.latest
        ├── etc
        │   ├── Caddyfile
        │   └── vars.caddy
        └── public
            ├── assets
            │   ├── elysia-BWovwTWN.svg
            │   ├── index-6YzeFRVx.css
            │   ├── index-DNvYkrHy.js
            │   └── pages-B7j4pB_e.js
            ├── favicon.svg
            └── robots.txt
```

## Stack highlights
- **[Bun](https://bun.sh) runtime**: fast start, built-in bundler, `bun:test`, `bun:sqlite`, native HTTP, and an S3-capable runtime without extra SDKs.
- **[Elysia](https://elysiajs.com) + [ArkType](https://arktype.io)**: ergonomic, typed HTTP handlers for the API surface.
- **[Vue 3](https://vuejs.org) SFC + [Vite](https://vite.dev)**: auto-routed pages, hot reload, and TypeScript-first ergonomics.
- **[shadcn-vue](https://www.shadcn-vue.com) + [Reka UI](https://reka-ui.com) + [CVA](https://beta.cva.style)**: accessible primitives with typed variants to keep props sane.
- **[Unhead](https://unhead.unjs.io)**: declarative head/meta management for Vue out of the box.
- **[Logtape](https://logtape.dev)**: structured logging wired for console in dev and syslog in production.

## What you get out of the box
- A home page that showcases the stack and links you to the docs and API example.
- A typed `/api/hello` route you can extend.
- An example bun:test in `test/api.test.ts` to keep the lights green.
- Opinionated defaults for formatting, linting, and routing that stay out of your way.

## Philosophy
Keep the stack small, keep the feedback loop tight, and ship binaries instead of containers when you can. Lean on Bun's built-ins before adding dependencies, and prefer well-typed primitives (Elysia, ArkType, CVA, shadcn-vue) over bespoke glue.
