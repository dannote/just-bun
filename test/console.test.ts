import { describe, expect, it } from 'bun:test'
import { spawn } from 'node:child_process'

const stripAnsi = (value: string) =>
  value.replace(/\x1b\[[0-9;]*m/g, '')

const runConsole = () =>
  new Promise<string>((resolve, reject) => {
    const proc = spawn('bun', ['--bun', 'run', 'server.ts', 'console'], {
      env: {
        ...process.env,
        ENABLE_CONSOLE: '1',
        NODE_ENV: 'test'
      }
    })

    let output = ''
    let errorOutput = ''
    let prompted = false

    const onTimeout = setTimeout(() => {
      proc.kill('SIGKILL')
      reject(new Error('Console did not exit in time'))
    }, 15000)

    const handleData = (chunk: Buffer) => {
      const text = chunk.toString()
      output += text

      if (!prompted && output.includes('just-bun> ')) {
        prompted = true
        proc.stdin.write('1 + 1\n')
        proc.stdin.write('routes\n')
        proc.stdin.end()
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
  it(
    'evaluates input and prints routes',
    async () => {
      const output = await runConsole()

      expect(output).toContain('2')
      expect(output).toContain('/api/hello')
      expect(output).toContain('GET')
    },
    20000
  )
})
