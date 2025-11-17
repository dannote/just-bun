import { edenFetch } from '@elysiajs/eden'

import type { ClassValue } from 'clsx'
import { clsx } from 'clsx'
import { twMerge } from 'tailwind-merge'

import type { App } from '~/server'

const fetch = edenFetch<App>(location.origin)

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs))
}

export { fetch }
