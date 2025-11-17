<script setup lang="ts">
import type { AsTag } from 'reka-ui'
import type { Component, HTMLAttributes } from 'vue'
import type { ButtonVariants } from '.'

import { Primitive } from 'reka-ui'
import { cn } from '~/app/lib/utils'
import { buttonVariants } from '.'

type Props = {
  asChild?: boolean
  as?: AsTag | Component
  variant?: ButtonVariants['variant']
  size?: ButtonVariants['size']
  class?: HTMLAttributes['class']
}

const props = withDefaults(defineProps<Props>(), {
  as: 'button'
})
</script>

<template>
  <Primitive
    data-slot="button"
    :as="as"
    :as-child="asChild"
    :class="cn(buttonVariants({ variant, size }), props.class)"
  >
    <slot />
  </Primitive>
</template>
