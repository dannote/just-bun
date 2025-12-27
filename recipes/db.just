kysely := "bunx --bun kysely"

# Run all pending migrations
migrate:
  {{kysely}} migrate:latest

# Create a new migration
new name:
  {{kysely}} migrate:make {{name}}

# Rollback last migration
rollback:
  {{kysely}} migrate:down

# Run next pending migration
up:
  {{kysely}} migrate:up

# Show migration status
status:
  {{kysely}} migrate:list

# Rollback all migrations
reset:
  {{kysely}} migrate:rollback

# Create a new seed file
seed-new name:
  {{kysely}} seed:make {{name}}

# Run all seed files
seed:
  {{kysely}} seed:run
