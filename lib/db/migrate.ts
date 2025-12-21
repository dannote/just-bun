import { Migrator, type Migration } from 'kysely'
import { getLogger } from '@logtape/logtape'

import { db } from './client'

const migrationModules = import.meta.glob<Migration>('../../migrations/*.ts', {
  eager: true
})

const migrations = Object.fromEntries(
  Object.entries(migrationModules).map(([path, module]) => [
    path.replace('../../migrations/', '').replace('.ts', ''),
    module
  ])
)

export async function migrate() {
  const logger = getLogger(['migrate'])
  const migrator = new Migrator({
    db,
    provider: {
      async getMigrations() {
        return migrations
      }
    }
  })

  const { error, results } = await migrator.migrateToLatest()

  for (const result of results ?? []) {
    if (result.status === 'Success') {
      logger.info(`Applied ${result.migrationName}`)
    } else if (result.status === 'Error') {
      logger.error(`Failed ${result.migrationName}`)
    }
  }

  if (error) {
    logger.error(
      `Migration failed: ${error instanceof Error ? error.message : 'Unknown error'}`
    )
    throw error
  }
}
