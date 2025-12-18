<script setup>
import { SelectValue, useForwardProps } from 'reka-ui'

const props = defineProps({
  placeholder: { type: String, required: false },
  asChild: { type: Boolean, required: false },
  as: { type: null, required: false },
})

const forwardedProps = useForwardProps(props)
</script>

<template>
  <SelectValue v-bind="forwardedProps">
    <slot />
  </SelectValue>
</template>
