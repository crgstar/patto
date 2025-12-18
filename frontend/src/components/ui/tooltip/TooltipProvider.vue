<script setup>
import { TooltipProvider, useForwardProps } from 'reka-ui'

const props = defineProps({
  delayDuration: { type: Number, required: false, default: 700 },
  skipDelayDuration: { type: Number, required: false, default: 300 },
  disableHoverableContent: { type: Boolean, required: false },
  disableClosingTrigger: { type: Boolean, required: false },
  disabled: { type: Boolean, required: false },
  ignoreNonKeyboardFocus: { type: Boolean, required: false },
})

const forwardedProps = useForwardProps(props)
</script>

<template>
  <TooltipProvider v-bind="forwardedProps">
    <slot />
  </TooltipProvider>
</template>
