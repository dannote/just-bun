# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/),
and this project adheres to [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Added
- Type-aware Oxlint policy checks and Oxfmt formatting configured for concise, actionable agent feedback
- Bun 1.4-powered parallel test mode, dependency audit, and lockfile deduplication checks
- Regression tests for Just flags, argument validation, confirmations, and deployment-target paths
- Modern Just command metadata with grouped recipe listings, generated argument help, typed flags, and argument validation
- Minimum Just version enforcement and a command listing when `just` is run without a recipe
- Confirmation prompts for destructive database and uninstall commands
- Native Just lists, parallel dependency mapping, and cached Gatus builds for binary repository work
- Litestream SQLite replication to S3-compatible storage with automatic database discovery
- Forgejo self-hosted Git forge with `add-remote` command for easy repo setup
- Host discovery commands: `just host apps`, `databases`, `services`
- E2E tests for Forgejo deployment and service lifecycle
- E2E tests for Litestream replication with MinIO S3 container
- Rails-style app console over SSH via `just app console` (requires `ENABLE_CONSOLE=1`)
- E2E coverage for the app console command
- Kysely database layer with type-safe queries and bundled migrations
- Database repository pattern in `lib/db/repo/` for query encapsulation
- App service management commands: `enable`, `disable`, `uninstall`, `version`, `versions`, `rollback`, `prune`
- OpenTelemetry tracing with OTLP export to any compatible backend
- Local binary repository for managing Caddy, Vector, Forgejo, and Litestream binaries
- Vector log aggregator with journald collection and S3 export
- MinIO client (`mc`) for S3-compatible storage operations
- Envsubst-based config templating in `configs/`
- Delta transfers via rsync with stable cache paths

### Changed
- Upgraded Nitro to the current v3 beta and adopted its typed `noExternals` configuration
- Upgraded Kysely to 0.29, replaced the stale Bun SQLite dialect dependency with Kysely's built-in SQLite driver adapter, and propagate request cancellation to database queries
- Upgraded LogTape and its syslog sink to v2, and reduced internal diagnostics to warnings
- Upgraded to Vue Router 5's built-in file-based routing and removed `unplugin-vue-router`
- Upgraded Unhead to v3 and enabled development-time head validation
- Upgraded to Vite 8 with Rolldown, enabled browser-console forwarding during development, and removed the obsolete OpenTelemetry machine-ID transform
- Replaced Biome with Oxfmt and upgraded the Oxlint TypeScript linting stack
- Upgraded compatible Elysia, Vue, Tailwind, ArkType, Reka UI, and build-tool dependencies
- Added a configurable Vector file-log sink to prevent recursive journald output in e2e tests
- Replaced the amd64-only e2e systemd image with a digest-pinned Fedora 43 image supporting amd64 and arm64
- Standardized all Just modules with `just --fmt` and added formatting checks to `just format` and `just lint`
- Accessory deployment paths now follow `DEPLOY_TARGET` instead of assuming `linux-amd64`
- `just app upload` and `just app deploy` now expose first-class `--force`/`-f` flags
- Restructured deployment recipes into `accessories/` and `repo/` modules
