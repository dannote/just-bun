import { defineConfig } from 'kysely-ctl'

import { db } from './lib/db'

export default defineConfig({
  kysely: db,
  migrations: {
    migrationFolder: 'migrations'
  },
  seeds: {
    seedFolder: 'seeds'
  }
})
