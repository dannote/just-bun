import { describe, expect, it } from 'bun:test'
import { randomUUID } from 'node:crypto'
import { join } from 'node:path'

const databaseURL = join(import.meta.dir, `${randomUUID()}.db`)
process.env.DATABASE_URL = databaseURL

const { treaty } = await import('@elysiajs/eden')
const { default: app } = await import('../server')

describe('API hello route', () => {
  it('returns a typed greeting', async () => {
    const client = treaty(app)

    const { data, error } = await client.api.hello.get({
      query: { id: 42 }
    })

    expect(error).toBeFalsy()
    expect(data).toContain('Hello')
    expect(data).toContain('42')
  })
})
