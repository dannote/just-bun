import { trace, context } from '@opentelemetry/api'
import type { SpanProcessor } from '@opentelemetry/sdk-trace-base'
import {
  BasicTracerProvider,
  BatchSpanProcessor
} from '@opentelemetry/sdk-trace-base'
import { resourceFromAttributes } from '@opentelemetry/resources'
import { ATTR_SERVICE_NAME } from '@opentelemetry/semantic-conventions'
import { OTLPTraceExporter } from '@opentelemetry/exporter-trace-otlp-proto'
import { AsyncLocalStorageContextManager } from '@opentelemetry/context-async-hooks'

const OTLP_ENDPOINT =
  process.env.OTEL_EXPORTER_OTLP_ENDPOINT || 'http://127.0.0.1:4318'

type TracingOptions = {
  spanProcessors?: SpanProcessor[]
}

export function setupTracing(
  serviceName: string,
  options: TracingOptions = {}
) {
  const contextManager = new AsyncLocalStorageContextManager()
  contextManager.enable()
  context.setGlobalContextManager(contextManager)

  const provider = new BasicTracerProvider({
    resource: resourceFromAttributes({
      [ATTR_SERVICE_NAME]: serviceName
    }),
    spanProcessors: options.spanProcessors ?? [
      new BatchSpanProcessor(
        new OTLPTraceExporter({
          url: `${OTLP_ENDPOINT}/v1/traces`
        })
      )
    ]
  })

  trace.setGlobalTracerProvider(provider)
}
