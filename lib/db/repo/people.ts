import { db } from '../client'
import type { Person } from '../schema'

export function findAllPeople() {
  return db.selectFrom('person').selectAll().execute()
}

export function findPerson(id: string) {
  return db
    .selectFrom('person')
    .selectAll()
    .where('id', '=', id)
    .executeTakeFirst()
}

export function createPerson(person: Person) {
  return db
    .insertInto('person')
    .values(person)
    .returningAll()
    .executeTakeFirst()
}
