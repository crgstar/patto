<script setup>
import { AlertDialogAction } from 'reka-ui'
import { buttonVariants } from '@/components/ui/button'
import { cn } from '@/lib/utils'

const props = defineProps({
  class: String
})
</script>

<template>
  <AlertDialogAction
    :class="cn(buttonVariants(), props.class)"
  >
    <slot />
  </AlertDialogAction>
</template>
