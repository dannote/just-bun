import type { ColumnType, Generated, Insertable } from 'kysely'

export interface PersonTable {
  id: Generated<string>
  name: ColumnType<string>
  age: ColumnType<number>
}

export interface Database {
  person: PersonTable
}

export type Person = Insertable<PersonTable>
