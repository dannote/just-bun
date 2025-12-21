import { Database } from 'bun:sqlite'
import { Kysely } from 'kysely'
import { BunSqliteDialect } from 'kysely-bun-sqlite'

import type { Database as DatabaseSchema } from './schema'

const dbPath = process.env.DATABASE_URL || 'app.db'

export const db = new Kysely<DatabaseSchema>({
  dialect: new BunSqliteDialect({
    database: new Database(dbPath, { create: true })
  })
})
