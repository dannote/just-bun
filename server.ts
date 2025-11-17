import { Elysia } from 'elysia'
import { type } from 'arktype'

import { getLogger } from '@logtape/logtape'

import { name } from './package.json'

import { setupLogs } from './lib/log'

await setupLogs()

const logger = getLogger([name, 'web'])

const app = new Elysia()
  .get(
    '/api/hello',
    ({ query: { id } }) => `🦊 Hello from Elysia! Your number is ${id}`,
    {
      query: type({ id: 'string.numeric.parse' })
    }
  )
  .onRequest((ctx) => {
    logger.info`${ctx.request.method} ${ctx.request.url}`
  })

export default app

export type App = typeof app
