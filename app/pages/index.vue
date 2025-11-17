<script setup lang="ts">
import { useHead } from '@unhead/vue'
import { useClipboard } from '@vueuse/core'

import { Icon } from '@iconify/vue'

import { Button } from '~/app/components/ui/button'
import { cn, fetch } from '~/app/lib/utils'

import bunLogo from '~/app/assets/logos/bun.svg'
import cvaLogo from '~/app/assets/logos/cva.svg'
import elysiaLogo from '~/app/assets/logos/elysia.svg'
import arktypeLogo from '~/app/assets/logos/arktype.svg'
import rekaLogo from '~/app/assets/logos/reka-ui.svg'
import shadcnLogo from '~/app/assets/logos/shadcn-vue.svg'
import viteLogo from '~/app/assets/logos/vite.svg'
import vueLogo from '~/app/assets/logos/vue.svg'

const tech = [
  {
    name: 'Bun',
    tagline: 'Runtime, bundler, test runner, SQLite, S3-friendly APIs.',
    accent: 'bg-gradient-to-br from-amber-200 to-pink-300',
    logo: bunLogo,
    href: 'https://bun.sh',
    alt: 'Bun logo'
  },
  {
    name: 'Elysia',
    tagline: 'Typed HTTP handlers with edge-ready ergonomics.',
    accent: 'bg-gradient-to-br from-sky-200 to-blue-400',
    logo: elysiaLogo,
    href: 'https://elysiajs.com',
    alt: 'Elysia logo'
  },
  {
    name: 'ArkType',
    tagline: '1:1 TypeScript validation with zero boilerplate.',
    accent: 'bg-gradient-to-br from-cyan-200 to-sky-400',
    logo: arktypeLogo,
    href: 'https://arktype.io',
    alt: 'ArkType logo'
  },
  {
    name: 'Vue 3',
    tagline: 'Reactive UI with Composition API and SFCs.',
    accent: 'bg-gradient-to-br from-slate-100 to-slate-300',
    logo: vueLogo,
    href: 'https://vuejs.org',
    alt: 'Vue logo'
  },
  {
    name: 'Vite',
    tagline: 'Instant dev server and modern build tooling.',
    accent: 'bg-gradient-to-br from-purple-200 to-orange-300',
    logo: viteLogo,
    href: 'https://vite.dev',
    alt: 'Vite logo'
  },
  {
    name: 'shadcn-vue',
    tagline: 'Headless UI patterns with consistent API.',
    accent: 'bg-gradient-to-br from-slate-200 to-indigo-300',
    logo: shadcnLogo,
    href: 'https://www.shadcn-vue.com',
    alt: 'shadcn-vue logo'
  },
  {
    name: 'Reka UI',
    tagline: 'Accessible primitives that stay lightweight.',
    accent: 'bg-gradient-to-br from-emerald-100 to-teal-200',
    logo: rekaLogo,
    href: 'https://reka-ui.com',
    alt: 'Reka UI logo'
  },
  {
    name: 'CVA',
    tagline: 'Type-safe variants that prevent prop explosion.',
    accent: 'bg-gradient-to-br from-amber-200 to-pink-300',
    logo: cvaLogo,
    href: 'https://beta.cva.style',
    alt: 'CVA logo'
  }
]

const commandSteps = [
  {
    title: 'Create from the template',
    fullCommand: 'bun create dannote/just-bun my-app',
    tokens: [
      { type: 'cmd', value: 'bun' },
      { type: 'arg', value: 'create' },
      { type: 'arg', value: 'dannote/just-bun' },
      { type: 'arg', value: 'my-app' }
    ]
  },
  {
    title: 'Install deps and scaffold the environment',
    fullCommand: 'just install && cp .env.example .env.local',
    tokens: [
      { type: 'cmd', value: 'just' },
      { type: 'arg', value: 'install' },
      { type: 'arg', value: '&&' },
      { type: 'cmd', value: 'cp' },
      { type: 'arg', value: '.env.example' },
      { type: 'arg', value: '.env.local' }
    ]
  },
  {
    title: 'Run the full stack locally',
    fullCommand: 'just dev',
    tokens: [
      { type: 'cmd', value: 'just' },
      { type: 'arg', value: 'dev' }
    ]
  },
  {
    title: 'Deploy in a single command!',
    fullCommand: 'just deploy',
    tokens: [
      { type: 'cmd', value: 'just' },
      { type: 'arg', value: 'deploy' }
    ]
  }
]

const { copy, copied, text: copiedText } = useClipboard({ legacy: true })

async function handleHit() {
  try {
    const { data } = await fetch('/api/hello', { query: { id: 42 } })

    alert(data)
  } catch (error) {
    console.error('Error hitting API', error)
  }
}

useHead({
  title: 'Just Bun! — Bun + Elysia + Vue Starter',
  meta: [
    {
      name: 'description',
      content:
        'Ship fast with Bun, Elysia, Vue 3, shadcn-vue + CVA, and zero-Docker deployments.'
    }
  ]
})
</script>

<template>
  <main class="min-h-screen bg-linear-to-b from-background via-background to-muted/50">
    <div class="mx-auto flex max-w-4xl flex-col gap-16 px-6 py-16">
      <section class="space-y-12">
        <div class="space-y-6">
          <p
            class="animate-in fade-in slide-in-from-bottom-4 duration-500 fill-mode-both inline-flex items-center gap-2 rounded-full bg-secondary px-3 py-1 text-sm font-medium text-secondary-foreground">
            Bun × Elysia × Vue starter
          </p>
          <div class="space-y-4">
            <h1
              class="animate-in fade-in slide-in-from-bottom-4 duration-500 delay-200 fill-mode-both text-4xl font-semibold leading-tight tracking-tighter md:text-5xl flex items-center ">
              <span class="text-amber-500">Just Bun</span>
              <Icon icon="bi:exclamation-lg" class="-ml-2 h-18 w-18 inline rotate-12 text-rose-500"
                aria-hidden="true" />
            </h1>
            <h2
              class="animate-in fade-in slide-in-from-bottom-4 duration-500 delay-300 fill-mode-both text-3xl font-semibold tracking-tight text-foreground">
              Ship a TypeScript backend + Vue in one binary.
            </h2>
            <p
              class="animate-in fade-in slide-in-from-bottom-4 duration-500 delay-400 fill-mode-both text-lg text-muted-foreground">
              Batteries-included runtime, typed API routes, and a tidy component stack,
              with a deployment loop that dodges Docker drag entirely.
            </p>
          </div>
          <div
            class="animate-in fade-in slide-in-from-bottom-4 duration-500 delay-600 fill-mode-both flex flex-wrap gap-3">
            <Button as="a" href="https://github.com/dannote/just-bun" size="lg">
              <Icon icon="bi:github" class="mr-1 h-5 w-5" aria-hidden="true" />
              View on GitHub
            </Button>
            <Button type="button" variant="secondary" size="lg" class="transition-transform hover:-translate-y-0.5"
              @click="handleHit">
              <Icon icon="bi:lightning" class="mr-1 h-5 w-5" aria-hidden="true" />
              Hit the API
            </Button>
          </div>
        </div>
      </section>

      <section class="animate-in fade-in slide-in-from-bottom-4 duration-500 delay-800 fill-mode-both space-y-4">
        <h2 class="text-2xl font-semibold tracking-tight">Getting started</h2>
        <ol class="space-y-4">
          <li v-for="(step, index) in commandSteps" :key="step.fullCommand"
            class="rounded-lg bg-card p-4 shadow-sm ring-1 ring-border/40 max-w-xl">
            <div class="flex items-start gap-4">
              <span
                class="flex h-8 w-8 shrink-0 items-center justify-center rounded-full bg-muted text-sm font-semibold text-muted-foreground">
                {{ index + 1 }}
              </span>
              <div class="flex-1 min-w-0">
                <p class="font-medium text-foreground">
                  {{ step.title }}
                </p>
                <div class="relative group mt-2">
                  <pre
                    class="block max-w-full overflow-x-auto whitespace-pre rounded-md bg-muted/50 p-3 pr-12 font-mono text-sm text-muted-foreground"><code><template v-for="(token, i) in step.tokens" :key="i"><span :class="[
                      token.type === 'cmd' && 'font-semibold text-primary',
                      token.type === 'flag' && 'text-sky-400',
                      token.type === 'arg' && 'text-foreground/80'
                    ]">{{ token.value }}</span>{{ ' ' }}</template></code></pre>
                  <button @click="copy(step.fullCommand)"
                    class="absolute top-1/2 right-2 -translate-y-1/2 rounded-md p-1.5 text-muted-foreground opacity-0 transition-opacity group-hover:opacity-100 hover:bg-muted hover:text-foreground focus:opacity-100 focus:outline-none"
                    aria-label="Copy command">
                    <span v-if="copied && copiedText === step.fullCommand" class="block h-4 w-4 text-emerald-500">
                      <svg fill="none" viewBox="0 0 24 24" stroke-width="2.5" stroke="currentColor">
                        <path stroke-linecap="round" stroke-linejoin="round" d="M4.5 12.75l6 6 9-13.5" />
                      </svg>
                    </span>
                    <span v-else class="block h-4 w-4">
                      <svg fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor">
                        <path stroke-linecap="round" stroke-linejoin="round"
                          d="M15.666 3.888A2.25 2.25 0 0013.5 2.25h-3c-1.03 0-1.9.693-2.166 1.638m7.332 0c.055.194.084.4.084.612v0a2.25 2.25 0 01-2.25 2.25h-1.5a2.25 2.25 0 01-2.25-2.25v0c0-.212.03-.418.084-.612m7.332 0c.646.049 1.288.11 1.927.184 1.1.128 1.907 1.077 1.907 2.185V19.5a2.25 2.25 0 01-2.25 2.25H6.75A2.25 2.25 0 014.5 19.5V6.257c0-1.108.806-2.057 1.907-2.185a48.208 48.208 0 011.927-.184" />
                      </svg>
                    </span>
                  </button>
                </div>
              </div>
            </div>
          </li>
        </ol>
      </section>


      <section class="animate-in fade-in slide-in-from-bottom-4 duration-500 delay-1000 fill-mode-both space-y-6">
        <div>
          <h2 class="text-2xl font-semibold tracking-tight text-foreground">The Stack</h2>
          <p class="mt-2 text-sm text-muted-foreground">
            A modern, performant, and type-safe foundation for full-stack apps.
          </p>
        </div>
        <ul class="grid gap-4 md:grid-cols-2">
          <li v-for="entry in tech" :key="entry.name">
            <a :href="entry.href" target="_blank" rel="noreferrer"
              class="flex items-start gap-4 rounded-lg bg-card/70 p-4 shadow-sm ring-1 ring-border/40 transition-shadow hover:shadow-md focus:outline-none focus-visible:ring-2 focus-visible:ring-ring">
              <div :class="cn(
                'mt-0.5 flex h-12 w-12 shrink-0 items-center justify-center rounded-lg p-2 shadow-inner shadow-black/10',
                entry.accent
              )" aria-hidden="true">
                <img :src="entry.logo" :alt="entry.alt" class="h-full w-full object-contain" />
              </div>
              <div class="space-y-1">
                <p class="text-base font-semibold leading-tight">{{ entry.name }}</p>
                <p class="mt-2 text-sm text-muted-foreground">{{ entry.tagline }}</p>
              </div>
            </a>
          </li>
        </ul>
      </section>

      <section class="animate-in fade-in slide-in-from-bottom-4 duration-500 delay-1200 fill-mode-both space-y-6">
        <div>
          <h2 class="text-2xl font-semibold tracking-tight text-foreground">What this template gives you</h2>
          <p class="mt-2 text-sm text-muted-foreground">
            Typed routes, batteries from Bun, and a UI stack that stays accessible.
          </p>
        </div>
        <ul class="grid gap-4 md:grid-cols-2">
          <li class="rounded-lg bg-card/40 p-4 shadow-sm ring-1 ring-border/40 transition-shadow hover:shadow-md">
            <p class="font-medium text-foreground">Bun-native toolchain</p>
            <p class="mt-2 text-sm text-muted-foreground">
              Use
              <code
                class="relative rounded bg-muted px-[0.3rem] py-[0.2rem] font-mono text-sm font-semibold text-foreground">bun:test</code>,
              <code
                class="relative rounded bg-muted px-[0.3rem] py-[0.2rem] font-mono text-sm font-semibold text-foreground">bun:sqlite</code>,
              and the built-in bundler
              without adding extra SDKs.
            </p>
          </li>
          <li class="rounded-lg bg-card/40 p-4 shadow-sm ring-1 ring-border/40 transition-shadow hover:shadow-md">
            <p class="font-medium text-foreground">Deploy as a single binary</p>
            <p class="mt-2 text-sm text-muted-foreground">
              Compile with <code
                class="relative rounded bg-muted px-[0.3rem] py-[0.2rem] font-mono text-sm font-semibold text-foreground">bun
          build --compile</code>, rsync it,
              and let systemd keep it alive.
            </p>
          </li>
          <li class="rounded-lg bg-card/40 p-4 shadow-sm ring-1 ring-border/40 transition-shadow hover:shadow-md">
            <p class="font-medium text-foreground">shadcn-vue + CVA</p>
            <p class="mt-2 text-sm text-muted-foreground">
              Compose variants without prop soup, powered by reka-ui primitives.
            </p>
          </li>
          <li class="rounded-lg bg-card/40 p-4 shadow-sm ring-1 ring-border/40 transition-shadow hover:shadow-md">
            <p class="font-medium text-foreground">Typed API starter</p>
            <p class="mt-2 text-sm text-muted-foreground">
              <code
                class="relative rounded bg-muted px-[0.3rem] py-[0.2rem] font-mono text-sm font-semibold text-foreground">/api/hello</code>
              is ready to extend; see
              <code
                class="relative rounded bg-muted px-[0.3rem] py-[0.2rem] font-mono text-sm font-semibold text-foreground">server.ts</code>
              and
              <code
                class="relative rounded bg-muted px-[0.3rem] py-[0.2rem] font-mono text-sm font-semibold text-foreground">test/api.test.ts</code>.
            </p>
          </li>
        </ul>
      </section>
    </div>
  </main>
</template>
