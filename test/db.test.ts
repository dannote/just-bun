import { describe, expect, it } from 'bun:test'
import { Database } from 'bun:sqlite'
import { Kysely, SqliteDialect } from 'kysely'

import { BunSqliteDatabase } from '../lib/db/bun-sqlite'

type TestDatabase = {
  item: {
    id: number
    name: string
  }
}

const createDatabase = () =>
  new Kysely<TestDatabase>({
    dialect: new SqliteDialect({
      database: new BunSqliteDatabase(new Database(':memory:'))
    })
  })

describe('Bun SQLite dialect adapter', () => {
  it('runs reads, writes, returning queries, and savepoints', async () => {
    const db = createDatabase()

    await db.schema
      .createTable('item')
      .addColumn('id', 'integer', (column) => column.primaryKey())
      .addColumn('name', 'text', (column) => column.notNull())
      .execute()

    const inserted = await db
      .insertInto('item')
      .values({ id: 1, name: 'first' })
      .returningAll()
      .executeTakeFirstOrThrow()

    expect(inserted).toEqual({ id: 1, name: 'first' })

    const transaction = await db.startTransaction().execute()
    const savepoint = await transaction.savepoint('temporary').execute()

    await transaction
      .insertInto('item')
      .values({ id: 2, name: 'second' })
      .execute()
    await savepoint
      .insertInto('item')
      .values({ id: 3, name: 'third' })
      .execute()
    await savepoint.releaseSavepoint('temporary').execute()
    await transaction.commit().execute()

    const rows = await db.selectFrom('item').selectAll().orderBy('id').execute()
    expect(rows).toEqual([
      { id: 1, name: 'first' },
      { id: 2, name: 'second' },
      { id: 3, name: 'third' }
    ])

    await db.destroy()
  })

  it('honors an already-aborted query signal', async () => {
    const db = createDatabase()
    const controller = new AbortController()
    controller.abort('cancelled')

    expect(
      db
        .selectNoFrom((expression) => expression.val(1).as('value'))
        .execute({
          signal: controller.signal
        })
    ).rejects.toThrow()

    await db.destroy()
  })
})
