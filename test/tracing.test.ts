import { afterEach, describe, expect, it } from 'bun:test'
import { context, trace } from '@opentelemetry/api'
import {
  InMemorySpanExporter,
  SimpleSpanProcessor
} from '@opentelemetry/sdk-trace-base'

import { setupTracing } from '../lib/tracing'

afterEach(() => {
  trace.disable()
  context.disable()
})

describe('tracing', () => {
  it('lets the Elysia plugin reuse the configured provider', async () => {
    const exporter = new InMemorySpanExporter()
    setupTracing('tracing-test', {
      spanProcessors: [new SimpleSpanProcessor(exporter)]
    })

    const [{ Elysia }, { opentelemetry }] = await Promise.all([
      import('elysia'),
      import('@elysiajs/opentelemetry')
    ])

    const app = new Elysia()
      .use(opentelemetry({ serviceName: 'tracing-test' }))
      .get('/trace', () => 'ok')

    const response = await app.handle(new Request('http://localhost/trace'))
    expect(await response.text()).toBe('ok')

    const spans = exporter.getFinishedSpans()
    expect(spans.map((span) => span.name)).toEqual(['Handle'])
  })
})
