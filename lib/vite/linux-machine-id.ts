import type { Plugin } from 'vite'
import dedent from 'dedent'

// Replace dynamic platform detection with static Linux import
// Original uses switch(process.platform) with dynamic import() which bundlers can't resolve
export function linuxMachineId(): Plugin {
  return {
    name: 'linux-machine-id',
    transform(_code, id) {
      if (
        !id.includes('@opentelemetry/resources') ||
        !id.endsWith('getMachineId.js')
      )
        return

      return dedent`
        import { promises as fs } from 'fs';
        export async function getMachineId() {
          for (const path of ['/etc/machine-id', '/var/lib/dbus/machine-id']) {
            try { return (await fs.readFile(path, 'utf8')).trim(); } catch {}
          }
        }
      `
    }
  }
}
