import { stat } from 'node:fs/promises'
import { join } from 'node:path'
import { pathToFileURL } from 'node:url'

import { Migrator, type Migration } from 'kysely'
import { getLogger } from '@logtape/logtape'

import { db } from './client'

const loadBundledMigrations = () => {
  try {
    const migrationModules = import.meta.glob<Migration>(
      '../../migrations/*.ts',
      { eager: true }
    )

    return Object.fromEntries(
      Object.entries(migrationModules).map(([path, module]) => [
        path.replace('../../migrations/', '').replace('.ts', ''),
        module
      ])
    )
  } catch {
    return null
  }
}

const loadFilesystemMigrations = async () => {
  try {
    const migrationsDir = join(process.cwd(), 'migrations')

    try {
      await stat(migrationsDir)
    } catch (error) {
      const err = error as { code?: string }
      if (err?.code === 'ENOENT') {
        return {}
      }

      throw error
    }

    const migrationsDirUrl = pathToFileURL(`${migrationsDir}/`)
    const glob = new Bun.Glob('*.ts')
    const migrations = new Map<string, Migration>()

    for await (const path of glob.scan({ cwd: migrationsDir })) {
      const module = (await import(new URL(path, migrationsDirUrl).href)) as Migration
      migrations.set(path.replace('.ts', ''), module)
    }

    return Object.fromEntries(migrations)
  } catch {
    return {}
  }
}

const loadMigrations = async () => {
  return loadBundledMigrations() ?? loadFilesystemMigrations()
}

export async function migrate() {
  const logger = getLogger(['migrate'])
  const migrator = new Migrator({
    db,
    provider: {
      async getMigrations() {
        return loadMigrations()
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
