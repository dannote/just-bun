import { Elysia } from 'elysia'
import { opentelemetry } from '@elysiajs/opentelemetry'
import { type } from 'arktype'

import { getLogger } from '@logtape/logtape'

import { name } from './package.json'

import { runConsole } from './lib/console'
import { setupLogs } from './lib/log'
import { setupTracing } from './lib/tracing'
import { migrate } from './lib/db/migrate'

import { createPerson, findAllPeople, findPerson } from './lib/db/repo/people'

await setupLogs()
setupTracing(name)
await migrate()

const logger = getLogger([name, 'web'])

const app = new Elysia()
  .use(opentelemetry({ serviceName: name }))
  .get(
    '/api/hello',
    ({ query: { id } }) => `🦊 Hello from Elysia! Your number is ${id}`,
    {
      query: type({ id: 'string.numeric.parse' })
    }
  )
  .get('/api/people', () => findAllPeople())
  .get(
    '/api/people/:id',
    async ({ params: { id } }) => {
      const person = await findPerson(id)
      if (!person) throw new Error('Person not found')
      return person
    },
    { params: type({ id: 'string' }) }
  )
  .post('/api/people', ({ body }) => createPerson(body), {
    body: type({ name: 'string', age: 'number' })
  })
  .onRequest((ctx) => logger.info`${ctx.request.method} ${ctx.request.url}`)

if (process.argv[2] === 'console') {
  try {
    await runConsole(app)
    process.exit(0)
  } catch (error) {
    console.error(error)
    process.exit(1)
  }
}

export default app

export type App = typeof app
