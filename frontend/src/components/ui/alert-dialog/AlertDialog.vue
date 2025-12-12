<script setup>
import { AlertDialogRoot } from 'reka-ui'

const props = defineProps({
  open: Boolean
})

const emit = defineEmits(['update:open'])
</script>

<template>
  <AlertDialogRoot
    :open="open"
    @update:open="emit('update:open', $event)"
  >
    <slot />
  </AlertDialogRoot>
</template>
