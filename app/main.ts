import { createApp } from 'vue'
import { createRouter, createWebHistory } from 'vue-router'
import { createHead } from '@unhead/vue/client'
import { ValidatePlugin } from 'unhead/plugins'
import { routes, handleHotUpdate } from 'vue-router/auto-routes'

import './assets/main.css'

import App from './App.vue'

const router = createRouter({
  history: createWebHistory(),
  routes
})

if (import.meta.hot) {
  handleHotUpdate(router)
}

const head = createHead({
  plugins: import.meta.env.DEV ? [ValidatePlugin()] : []
})

const app = createApp(App)

app.use(head)
app.use(router)

app.mount('#app')
