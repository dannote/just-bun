import { fileURLToPath, URL } from 'node:url'

import { defineConfig } from 'vite'

import { nitro } from 'nitro/vite'
import tailwindcss from '@tailwindcss/vite'
import vue from '@vitejs/plugin-vue'
import autoImport from 'unplugin-auto-import/vite'
import vueRouter from 'unplugin-vue-router/vite'
import { VueRouterAutoImports } from 'unplugin-vue-router'

import { linuxMachineId } from './lib/vite/linux-machine-id'

export default defineConfig({
  resolve: {
    alias: {
      '~': fileURLToPath(new URL('./', import.meta.url))
    }
  },
  plugins: [
    linuxMachineId(),
    // Nitro is just the bundling shell; Elysia still serves the HTTP requests.
    nitro({
      noExternals: true,
      serveStatic: false,
      preset: 'bun'
    }),
    tailwindcss(),
    vueRouter({ routesFolder: 'app/pages' }),
    autoImport({ imports: ['vue', VueRouterAutoImports] }),
    vue()
  ]
})
