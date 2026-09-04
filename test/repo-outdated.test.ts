import { describe, expect, it } from 'bun:test'

import { checkBinaryVersions } from '../lib/repo/outdated'

const json = (value: unknown) =>
  new Response(JSON.stringify(value), {
    headers: { 'content-type': 'application/json' }
  })

const fetcher = Object.assign(
  async (input: string | URL | Request) => {
    let url: string
    if (typeof input === 'string') url = input
    else if (input instanceof URL) url = input.href
    else url = input.url

    if (url.includes('codeberg.org')) {
      return json({ tag_name: 'v16.1.0', prerelease: false })
    }

    if (url.includes('dl.min.io')) {
      return new Response(
        'mc.RELEASE.2025-01-01T00-00-00Z.sha256sum ' +
          'mc.RELEASE.2025-08-13T08-35-41Z.sha256sum'
      )
    }

    let latest = 'v1.2.4'
    if (url.includes('caddyserver')) latest = 'v3.0.0-beta.1'
    if (url.includes('vectordotdev')) latest = 'v0.59.0'

    return json([
      { tag_name: latest, prerelease: latest.includes('beta') },
      { tag_name: url.includes('caddyserver') ? 'v2.11.5' : 'v1.2.3' }
    ])
  },
  { preconnect: fetch.preconnect }
) satisfies typeof fetch

describe('binary version checker', () => {
  it('reports stable updates and ignores prereleases', async () => {
    const statuses = await checkBinaryVersions(
      {
        caddy: '2.11.4',
        forgejo: '16.0.3',
        gatus: '1.2.3',
        litestream: '1.2.2',
        mc: '2025-08-13T08-35-41Z',
        typst: '1.1.0',
        vector: '0.58.0'
      },
      fetcher
    )

    expect(statuses).toContainEqual({
      name: 'caddy',
      current: '2.11.4',
      latest: '2.11.5',
      update: 'patch'
    })
    expect(statuses).toContainEqual({
      name: 'forgejo',
      current: '16.0.3',
      latest: '16.1.0',
      update: 'minor'
    })
    expect(statuses).toContainEqual({
      name: 'mc',
      current: '2025-08-13T08-35-41Z',
      latest: '2025-08-13T08-35-41Z',
      update: 'current'
    })
    expect(statuses).toContainEqual({
      name: 'vector',
      current: '0.58.0',
      latest: '0.59.0',
      update: 'minor'
    })
  })
})
