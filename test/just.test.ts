import { describe, expect, it } from 'bun:test'
import { spawnSync } from 'node:child_process'

const runJust = (...args: string[]) =>
  spawnSync('just', args, {
    cwd: import.meta.dir + '/..',
    env: { ...process.env, NO_COLOR: '1' },
    stdout: 'pipe',
    stderr: 'pipe'
  })

const outputOf = (result: ReturnType<typeof runJust>) =>
  `${result.stdout.toString()}${result.stderr.toString()}`

describe('Just command interface', () => {
  it('documents the deploy force flag', () => {
    const result = runJust('--usage', 'app', 'deploy')

    expect(result.status).toBe(0)
    expect(outputOf(result)).toContain('-f, --force')
  })

  it('accepts long and short force flags', () => {
    const long = runJust('--dry-run', 'app', 'upload', '--force')
    const short = runJust('--dry-run', 'app', 'upload', '-f')

    expect(long.status).toBe(0)
    expect(short.status).toBe(0)
    expect(outputOf(long)).toContain('force=true')
    expect(outputOf(short)).toContain('force=true')
  })

  it('rejects unknown e2e suites before execution', () => {
    const result = runJust('e2e', 'test', 'unknown')

    expect(result.status).not.toBe(0)
    expect(outputOf(result)).toContain('does not match pattern')
  })

  it('rejects invalid rollback hashes before execution', () => {
    const result = runJust('app', 'rollback', 'not-a-hash')

    expect(result.status).not.toBe(0)
    expect(outputOf(result)).toContain('does not match pattern')
  })

  it('requires confirmation for destructive commands', () => {
    const denied = runJust('--dry-run', 'db', 'reset')
    const accepted = runJust('--dry-run', '--yes', 'db', 'reset')

    expect(denied.status).not.toBe(0)
    expect(outputOf(denied)).toContain('recipe `reset` was not confirmed')
    expect(accepted.status).toBe(0)
  })

  it('uses DEPLOY_TARGET for accessory repository paths', () => {
    const result = spawnSync('just', ['--dry-run', 'caddy', 'upload'], {
      cwd: import.meta.dir + '/..',
      env: {
        ...process.env,
        DEPLOY_TARGET: 'linux-arm64',
        NO_COLOR: '1'
      },
      stdout: 'pipe',
      stderr: 'pipe'
    })

    expect(result.status).toBe(0)
    expect(outputOf(result)).toContain('/repo/linux/arm64/caddy.')
  })
})
