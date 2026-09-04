import type { AbortableQueryOptions } from 'kysely'

import { db } from '../client'
import type { Person } from '../schema'

export function findAllPeople(options?: AbortableQueryOptions) {
  return db.selectFrom('person').selectAll().execute(options)
}

export function findPerson(id: string, options?: AbortableQueryOptions) {
  return db
    .selectFrom('person')
    .selectAll()
    .where('id', '=', id)
    .executeTakeFirst(options)
}

export function createPerson(person: Person, options?: AbortableQueryOptions) {
  return db
    .insertInto('person')
    .values(person)
    .returningAll()
    .executeTakeFirst(options)
}
