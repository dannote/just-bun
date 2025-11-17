import { describe, expect, it } from 'bun:test'
import { treaty } from '@elysiajs/eden'

import app from '../server'

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
