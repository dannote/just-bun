import { describe, expect, it } from 'bun:test'

const root = import.meta.dir + '/..'

const runJust = (...args: string[]) =>
  Bun.spawnSync(['just', ...args], {
    cwd: root,
    env: { ...process.env, NO_COLOR: '1' },
    stdout: 'pipe',
    stderr: 'pipe'
  })

const outputOf = (result: ReturnType<typeof runJust>) =>
  `${result.stdout.toString()}${result.stderr.toString()}`

describe('Just command interface', () => {
  it('documents the deploy force flag', () => {
    const result = runJust('--usage', 'app', 'deploy')

    expect(result.exitCode).toBe(0)
    expect(outputOf(result)).toContain('-f, --force')
  })

  it('accepts long and short force flags', () => {
    const long = runJust('--dry-run', 'app', 'upload', '--force')
    const short = runJust('--dry-run', 'app', 'upload', '-f')

    expect(long.exitCode).toBe(0)
    expect(short.exitCode).toBe(0)
    expect(outputOf(long)).toContain('force=true')
    expect(outputOf(short)).toContain('force=true')
  })

  it('rejects unknown e2e suites before execution', () => {
    const result = runJust('e2e', 'test', 'unknown')

    expect(result.exitCode).not.toBe(0)
    expect(outputOf(result)).toContain('does not match pattern')
  })

  it('rejects invalid rollback hashes before execution', () => {
    const result = runJust('app', 'rollback', 'not-a-hash')

    expect(result.exitCode).not.toBe(0)
    expect(outputOf(result)).toContain('does not match pattern')
  })

  it('requires confirmation for destructive commands', () => {
    const denied = runJust('--dry-run', 'db', 'reset')
    const accepted = runJust('--dry-run', '--yes', 'db', 'reset')

    expect(denied.exitCode).not.toBe(0)
    expect(outputOf(denied)).toContain('recipe `reset` was not confirmed')
    expect(accepted.exitCode).toBe(0)
  })

  it('uses DEPLOY_TARGET for accessory repository paths', () => {
    const result = Bun.spawnSync(['just', '--dry-run', 'caddy', 'upload'], {
      cwd: root,
      env: {
        ...process.env,
        DEPLOY_TARGET: 'linux-arm64',
        NO_COLOR: '1'
      },
      stdout: 'pipe',
      stderr: 'pipe'
    })

    expect(result.exitCode).toBe(0)
    expect(outputOf(result)).toContain('/repo/linux/arm64/caddy.2.11.4')
  })

  it('shares binary versions between repository and accessory recipes', () => {
    const info = runJust('repo', 'info')
    const upload = runJust('--dry-run', 'forgejo', 'upload')

    expect(info.exitCode).toBe(0)
    expect(outputOf(info)).toContain('forgejo 16.0.3')
    expect(upload.exitCode).toBe(0)
    expect(outputOf(upload)).toContain('/forgejo.16.0.3')
  })

  it('allows binary version overrides', () => {
    const result = Bun.spawnSync(['just', 'repo', 'caddy', 'info'], {
      cwd: root,
      env: { ...process.env, CADDY_VERSION: '9.9.9', NO_COLOR: '1' },
      stdout: 'pipe',
      stderr: 'pipe'
    })

    expect(result.exitCode).toBe(0)
    expect(outputOf(result)).toContain('caddy 9.9.9')
  })
})
