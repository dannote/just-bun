kysely := "bunx --bun kysely"

migrate:
  {{kysely}} migrate:latest

new name:
  {{kysely}} migrate:make {{name}}

rollback:
  {{kysely}} migrate:down

up:
  {{kysely}} migrate:up

status:
  {{kysely}} migrate:list

reset:
  {{kysely}} migrate:rollback

seed-new name:
  {{kysely}} seed:make {{name}}

seed:
  {{kysely}} seed:run
