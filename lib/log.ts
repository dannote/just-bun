import { configure, getConfig, getConsoleSink } from '@logtape/logtape'

import { getSyslogSink } from '@logtape/syslog'

import { name } from '../package.json'

const isDev = process.env.NODE_ENV !== 'production'
const sinks = ['console', ...(isDev ? [] : ['syslog'])]

export async function setupLogs() {
  // Workaround for HMR
  if (!getConfig()) {
    await configure({
      sinks: {
        console: getConsoleSink(),
        ...(isDev ? {} : { syslog: getSyslogSink() })
      },
      loggers: [
        { category: ['logtape', 'meta'], sinks },
        { category: name, lowestLevel: isDev ? 'debug' : 'info', sinks }
      ],
      reset: !!import.meta.hot
    })
  }
}
