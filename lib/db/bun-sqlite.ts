import type { Database, SQLQueryBindings, Statement } from 'bun:sqlite'
import type { SqliteDatabase, SqliteStatement } from 'kysely'

class BunSqliteStatement implements SqliteStatement {
  readonly #statement: Statement

  constructor(statement: Statement) {
    this.#statement = statement
  }

  get reader() {
    return this.#statement.columnNames.length > 0
  }

  all(parameters: ReadonlyArray<unknown>) {
    return this.#statement.all(...this.#bindings(parameters))
  }

  run(parameters: ReadonlyArray<unknown>) {
    return this.#statement.run(...this.#bindings(parameters))
  }

  iterate(parameters: ReadonlyArray<unknown>) {
    return this.#statement.iterate(...this.#bindings(parameters))
  }

  #bindings(parameters: ReadonlyArray<unknown>) {
    return parameters as SQLQueryBindings[]
  }
}

export class BunSqliteDatabase implements SqliteDatabase {
  readonly #database: Database

  constructor(database: Database) {
    this.#database = database
  }

  close() {
    this.#database.close()
  }

  prepare(sql: string) {
    return new BunSqliteStatement(this.#database.prepare(sql))
  }
}
