# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/),
and this project adheres to [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Added
- Kysely database layer with type-safe queries and bundled migrations
- Database repository pattern in `lib/db/repo/` for query encapsulation
- App service management commands: `enable`, `disable`, `uninstall`, `version`, `prune`
- OpenTelemetry tracing with OTLP export to any compatible backend
- Local binary repository for managing Caddy, Vector, and mc binaries
- Vector log aggregator with journald collection and S3 export
- MinIO client (`mc`) for S3-compatible storage operations
- Envsubst-based config templating in `configs/`
- Delta transfers via rsync with stable cache paths
- Vite plugin to patch `@opentelemetry/resources` dynamic imports for Bun compatibility

### Changed
- Restructured deployment recipes into `accessories/` and `repo/` modules
