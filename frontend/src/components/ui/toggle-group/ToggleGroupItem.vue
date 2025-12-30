<script setup>
import { ToggleGroupItem } from 'reka-ui'
import { cn } from '@/lib/utils'
import { toggleGroupItemVariants } from '.'

const props = defineProps({
  value: { type: String, required: true },
  variant: { type: null, required: false },
  size: { type: null, required: false },
  class: { type: null, required: false },
  disabled: { type: Boolean, required: false },
})
</script>

<template>
  <ToggleGroupItem
    :value="value"
    :disabled="disabled"
    :class="cn(toggleGroupItemVariants({ variant, size }), props.class)"
  >
    <slot />
  </ToggleGroupItem>
</template>
