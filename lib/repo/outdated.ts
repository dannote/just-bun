type Fetcher = typeof fetch

type VersionSource = {
  current: string
  latest: (fetcher: Fetcher) => Promise<string>
}

type Release = {
  draft?: boolean
  prerelease?: boolean
  tag_name: string
}

export type VersionStatus = {
  name: string
  current: string
  latest: string
  update: 'current' | 'major' | 'minor' | 'patch'
}

const stableVersion = /^v?\d+\.\d+\.\d+$/

const responseText = async (
  fetcher: Fetcher,
  url: string,
  attempt = 0
): Promise<string> => {
  try {
    const response = await fetcher(url, {
      headers: { accept: 'application/json', 'user-agent': 'just-bun' }
    })

    if (!response.ok) {
      throw new Error(`${url}: ${response.status} ${response.statusText}`)
    }

    return response.text()
  } catch (error) {
    if (attempt === 2) throw error
    await Bun.sleep(500 * (attempt + 1))
    return responseText(fetcher, url, attempt + 1)
  }
}

const github = (repository: string) => async (fetcher: Fetcher) => {
  const releases = JSON.parse(
    await responseText(
      fetcher,
      `https://api.github.com/repos/${repository}/releases?per_page=30`
    )
  ) as Release[]

  const release = releases.find(
    ({ draft, prerelease, tag_name }) =>
      !draft && !prerelease && stableVersion.test(tag_name)
  )

  if (!release) throw new Error(`${repository}: no stable release found`)
  return release.tag_name.replace(/^v/, '')
}

const forgejo = async (fetcher: Fetcher) => {
  const releases = JSON.parse(
    await responseText(
      fetcher,
      'https://codeberg.org/api/v1/repos/forgejo/forgejo/releases/latest'
    )
  ) as Release

  if (
    releases.draft ||
    releases.prerelease ||
    !stableVersion.test(releases.tag_name)
  ) {
    throw new Error('forgejo: latest release is not stable')
  }

  return releases.tag_name.replace(/^v/, '')
}

const minioClient = async (fetcher: Fetcher) => {
  const page = await responseText(
    fetcher,
    'https://dl.min.io/client/mc/release/linux-amd64/archive/'
  )
  const versions = [
    ...page.matchAll(/mc\.RELEASE\.([\dTZ-]+)\.sha256sum/g)
  ].map((match) => match[1])

  const latest = versions.toSorted().at(-1)
  if (!latest) throw new Error('mc: no stable release found')
  return latest
}

const compare = (current: string, latest: string): VersionStatus['update'] => {
  if (current === latest) return 'current'
  if (current.includes('T') || latest.includes('T')) return 'patch'

  const before = current.split('.').map(Number)
  const after = latest.split('.').map(Number)
  if (before[0] !== after[0]) return 'major'
  if (before[1] !== after[1]) return 'minor'
  return 'patch'
}

export const checkBinaryVersions = async (
  current: Record<string, string>,
  fetcher: Fetcher = fetch
): Promise<VersionStatus[]> => {
  const sources: Record<string, VersionSource['latest']> = {
    caddy: github('caddyserver/caddy'),
    forgejo,
    gatus: github('TwiN/gatus'),
    litestream: github('benbjohnson/litestream'),
    mc: minioClient,
    typst: github('typst/typst'),
    vector: github('vectordotdev/vector')
  }

  return Promise.all(
    Object.entries(sources).map(async ([name, latest]) => {
      const latestVersion = await latest(fetcher)
      return {
        name,
        current: current[name],
        latest: latestVersion,
        update: compare(current[name], latestVersion)
      }
    })
  )
}

const parseCurrentVersions = () =>
  Object.fromEntries(
    process.argv.slice(2).map((value) => {
      const [name, version] = value.split('=', 2)
      if (!name || !version)
        throw new Error(`Invalid version argument: ${value}`)
      return [name, version]
    })
  )

const printStatuses = (statuses: VersionStatus[]) => {
  const widths = [
    Math.max(6, ...statuses.map(({ name }) => name.length)),
    Math.max(7, ...statuses.map(({ current }) => current.length)),
    Math.max(6, ...statuses.map(({ latest }) => latest.length))
  ]

  console.log(
    ['BINARY', 'CURRENT', 'LATEST', 'UPDATE']
      .map((value, index) => value.padEnd(widths[index] ?? 0))
      .join('  ')
  )

  for (const status of statuses) {
    console.log(
      [status.name, status.current, status.latest]
        .map((value, index) => value.padEnd(widths[index] ?? 0))
        .concat(status.update)
        .join('  ')
    )
  }
}

if (import.meta.main) {
  try {
    const statuses = await checkBinaryVersions(parseCurrentVersions())
    printStatuses(statuses)

    if (
      process.env.CHECK_BINARY_VERSIONS === '1' &&
      statuses.some(({ update }) => update !== 'current')
    ) {
      process.exitCode = 1
    }
  } catch (error) {
    console.error(error instanceof Error ? error.message : error)
    process.exitCode = 1
  }
}
