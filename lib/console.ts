import { inspect } from 'node:util'
import vm from 'node:vm'
import readline from 'node:readline'

import type { Elysia } from 'elysia'

import { name } from '../package.json'
import { db } from './db'

const createContext = (app: Elysia) => {
  const config = {
    name,
    nodeEnv: process.env.NODE_ENV ?? 'development',
    databaseURL: process.env.DATABASE_URL ?? 'app.db'
  }

  const env = process.env
  const routes = app.routes.map(({ method, path }) => ({ method, path }))

  return vm.createContext({
    app,
    db,
    env,
    config,
    routes,
    Bun,
    console,
    fetch,
    setTimeout,
    clearTimeout,
    setInterval,
    clearInterval
  })
}

export const runConsole = async (app: Elysia) => {
  if (process.env.ENABLE_CONSOLE !== '1') {
    throw new Error('ENABLE_CONSOLE=1 is required to run the console')
  }

  const context = createContext(app)
  const transpiler = new Bun.Transpiler({
    loader: 'tsx',
    replMode: true
  } as Bun.TranspilerOptions)

  const rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout,
    terminal: true
  })

  rl.setPrompt('just-bun> ')
  rl.prompt()

  const handleLine = async (line: string) => {
    const trimmed = line.trim()
    if (!trimmed) {
      rl.prompt()
      return
    }

    try {
      const transformed = transpiler.transformSync(line)
      const result = await vm.runInContext(transformed, context)
      const value =
        result && typeof result === 'object' && 'value' in result
          ? (result as { value: unknown }).value
          : result

      if (typeof value !== 'undefined') {
        console.log(inspect(value, { colors: true, depth: 5 }))
      }
    } catch (error) {
      console.error(error)
    }

    rl.prompt()
  }

  rl.on('line', (line) => {
    handleLine(line).catch((error) => {
      console.error(error)
      rl.prompt()
    })
  })

  await new Promise<void>((resolve) => {
    rl.on('close', resolve)
  })
}
