<script setup>
import { AlertDialogCancel } from 'reka-ui'
import { buttonVariants } from '@/components/ui/button'
import { cn } from '@/lib/utils'

const props = defineProps({
  class: String
})
</script>

<template>
  <AlertDialogCancel
    :class="cn(
      buttonVariants({ variant: 'outline' }),
      'mt-2 sm:mt-0',
      props.class
    )"
  >
    <slot />
  </AlertDialogCancel>
</template>
