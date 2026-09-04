import { mkdir } from 'node:fs/promises'
import { dirname, join } from 'node:path'
import repl from 'node:repl'
import { inspect } from 'node:util'
import vm from 'node:vm'

import type { AnyElysia } from 'elysia'

import { name } from '../package.json'
import { db } from './db'

type ConsoleContext = {
  app: AnyElysia
  db: typeof db
  env: NodeJS.ProcessEnv
  config: {
    name: string
    nodeEnv: string
    databaseURL: string
  }
  routes: Array<{ method: string; path: string }>
}

const createContext = (app: AnyElysia): ConsoleContext => ({
  app,
  db,
  env: process.env,
  config: {
    name,
    nodeEnv: process.env.NODE_ENV ?? 'development',
    databaseURL: process.env.DATABASE_URL ?? 'app.db'
  },
  routes: app.routes.map(({ method, path }) => ({ method, path }))
})

const isIncompleteInput = (error: unknown) => {
  const errors = error instanceof AggregateError ? error.errors : [error]

  return errors.some(
    (item) =>
      item instanceof Error &&
      (item.message.includes('end of file') ||
        item.message.includes('Unexpected end of file'))
  )
}

const createEvaluator = () => {
  const transpiler = new Bun.Transpiler({
    loader: 'tsx',
    replMode: true
  })

  return ((code, context, _file, callback) => {
    const evaluate = async () => {
      const transformed = transpiler.transformSync(code)
      const result = await vm.runInContext(transformed, context)
      return result && typeof result === 'object' && 'value' in result
        ? result.value
        : result
    }

    const finishEvaluation = (evaluation: {
      error: Error | null
      value: unknown
    }) => callback(evaluation.error, evaluation.value)

    void evaluate()
      .then((value) => ({ error: null, value }))
      .catch((error: Error) => ({
        error: isIncompleteInput(error) ? new repl.Recoverable(error) : error,
        value: undefined
      }))
      .then(finishEvaluation)
  }) satisfies repl.REPLEval
}

const addContext = (target: vm.Context, values: ConsoleContext) => {
  Object.assign(target, values)
}

const setupHistory = async (server: repl.REPLServer) => {
  const historyPath =
    process.env.CONSOLE_HISTORY || join(process.cwd(), '.console_history')
  await mkdir(dirname(historyPath), { recursive: true })

  await new Promise<void>((resolve, reject) => {
    server.setupHistory(historyPath, (error) => {
      if (error) reject(error)
      else resolve()
    })
  })
}

export const runConsole = async (app: AnyElysia) => {
  if (process.env.ENABLE_CONSOLE !== '1') {
    throw new Error('ENABLE_CONSOLE=1 is required to run the console')
  }

  const values = createContext(app)

  const server = repl.start({
    prompt: `${name}> `,
    input: process.stdin,
    output: process.stdout,
    terminal: process.stdout.isTTY,
    useColors: process.stdout.isTTY,
    ignoreUndefined: true,
    eval: createEvaluator(),
    writer: (value) =>
      inspect(value, { colors: process.stdout.isTTY, depth: 5 })
  })

  addContext(server.context, values)

  server.defineCommand('routes', {
    help: 'List registered Elysia routes',
    action() {
      this.clearBufferedCommand()
      this.output.write(
        `${inspect(values.routes, { colors: this.useColors })}\n`
      )
      this.displayPrompt()
    }
  })

  if (process.stdin.isTTY) {
    try {
      await setupHistory(server)
    } catch (error) {
      console.warn('Could not load console history:', error)
    }
  }

  await new Promise<void>((resolve) => server.on('exit', resolve))
}
