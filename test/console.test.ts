import { describe, expect, it } from 'bun:test'
import { spawn } from 'node:child_process'
import { randomUUID } from 'node:crypto'
import { join } from 'node:path'

const databaseURL = join(import.meta.dir, `${randomUUID()}.db`)

const stripAnsi = (value: string) => Bun.stripANSI(value)

const commands = [
  'const amount: number = 2',
  'amount + 3',
  'await Promise.resolve(9)',
  'const double = (',
  'value: number',
  ') => value * 2',
  'double(6)',
  '.routes',
  '.help',
  '.exit'
]

const runConsole = () =>
  new Promise<string>((resolve, reject) => {
    const proc = spawn('bun', ['--bun', 'run', 'server.ts', 'console'], {
      env: {
        ...process.env,
        ENABLE_CONSOLE: '1',
        NODE_ENV: 'test',
        DATABASE_URL: databaseURL
      }
    })

    let output = ''
    let errorOutput = ''
    let commandIndex = 0
    let handledPrompts = 0

    const onTimeout = setTimeout(() => {
      proc.kill('SIGKILL')
      reject(new Error('Console did not exit in time'))
    }, 15000)

    const handleData = (chunk: Buffer) => {
      const text = chunk.toString()
      output += text

      const promptCount = output.match(/just-bun> |\| /g)?.length ?? 0
      while (handledPrompts < promptCount && commandIndex < commands.length) {
        handledPrompts++
        proc.stdin.write(`${commands[commandIndex++]}\n`)
      }
    }

    proc.stdout.on('data', handleData)
    proc.stderr.on('data', (chunk: Buffer) => {
      errorOutput += chunk.toString()
    })

    proc.on('close', () => {
      clearTimeout(onTimeout)
      resolve(stripAnsi(`${output}\n${errorOutput}`))
    })

    proc.on('error', (error) => {
      clearTimeout(onTimeout)
      reject(error)
    })
  })

describe('app console', () => {
  it('supports TypeScript, persistent scope, await, routes, and help', async () => {
    const output = await runConsole()

    expect(output).toContain('5')
    expect(output).toContain('9')
    expect(output).toContain('12')
    expect(output).toContain('/api/hello')
    expect(output).toContain('GET')
    expect(output).toContain('.routes')
    expect(output).toContain('.exit')
  }, 20000)
})
