<script setup>
import { reactiveOmit } from '@vueuse/core'
import {
  TooltipContent,
  TooltipPortal,
  useForwardPropsEmits,
} from 'reka-ui'
import { cn } from '@/lib/utils'

const props = defineProps({
  ariaLabel: { type: String, required: false },
  asChild: { type: Boolean, required: false },
  as: { type: null, required: false },
  side: { type: String, required: false, default: 'top' },
  sideOffset: { type: Number, required: false, default: 4 },
  align: { type: String, required: false },
  alignOffset: { type: Number, required: false },
  avoidCollisions: { type: Boolean, required: false },
  collisionBoundary: { type: null, required: false },
  collisionPadding: { type: [Number, Object], required: false },
  arrowPadding: { type: Number, required: false },
  sticky: { type: String, required: false },
  hideWhenDetached: { type: Boolean, required: false },
  positionStrategy: { type: String, required: false },
  updatePositionStrategy: { type: String, required: false },
  prioritizePosition: { type: Boolean, required: false },
  forceMount: { type: Boolean, required: false },
  class: { type: null, required: false },
})

const emits = defineEmits(['escapeKeyDown', 'pointerDownOutside'])

const delegatedProps = reactiveOmit(props, 'class')
const forwarded = useForwardPropsEmits(delegatedProps, emits)
</script>

<template>
  <TooltipPortal>
    <TooltipContent
      v-bind="forwarded"
      :class="
        cn(
          'z-50 overflow-hidden rounded-md bg-card text-card-foreground border-2 border-secondary px-3 py-1.5 text-xs leading-relaxed shadow-sm data-[side=bottom]:slide-in-from-top-2 data-[side=left]:slide-in-from-right-2 data-[side=right]:slide-in-from-left-2 data-[side=top]:slide-in-from-bottom-2',
          props.class,
        )
      "
    >
      <slot />
    </TooltipContent>
  </TooltipPortal>
</template>
