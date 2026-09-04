import { fileURLToPath, URL } from 'node:url'

import { defineConfig } from 'vite'

import { nitro } from 'nitro/vite'
import tailwindcss from '@tailwindcss/vite'
import vue from '@vitejs/plugin-vue'
import autoImport from 'unplugin-auto-import/vite'
import vueRouter from 'vue-router/vite'
import { VueRouterAutoImports } from 'vue-router/unplugin'

export default defineConfig({
  server: {
    forwardConsole: true
  },
  resolve: {
    alias: {
      '~': fileURLToPath(new URL('./', import.meta.url))
    }
  },
  plugins: [
    // Nitro is just the bundling shell; Elysia still serves the HTTP requests.
    nitro({
      noExternals: ['bun:sqlite'],
      serveStatic: false,
      preset: 'bun'
    }),
    tailwindcss(),
    vueRouter({ routesFolder: 'app/pages', dts: 'route-map.d.ts' }),
    autoImport({ imports: ['vue', VueRouterAutoImports] }),
    vue()
  ]
})
