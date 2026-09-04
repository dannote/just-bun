import { Database } from 'bun:sqlite'
import { Kysely, SqliteDialect } from 'kysely'

import type { Database as DatabaseSchema } from './schema'
import { BunSqliteDatabase } from './bun-sqlite'

const dbPath = process.env.DATABASE_URL || 'app.db'

export const db = new Kysely<DatabaseSchema>({
  dialect: new SqliteDialect({
    database: new BunSqliteDatabase(new Database(dbPath, { create: true }))
  })
})
