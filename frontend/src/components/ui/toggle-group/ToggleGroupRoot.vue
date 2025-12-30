<script setup>
import { ToggleGroupRoot } from 'reka-ui'
import { cn } from '@/lib/utils'

const props = defineProps({
  modelValue: { type: String, required: false },
  type: { type: String, required: false, default: 'single' },
  class: { type: null, required: false },
})

const emit = defineEmits(['update:modelValue'])

const handleUpdateModelValue = (value) => {
  // 常に値が選択されている状態を維持（空にならないようにする）
  if (value) {
    emit('update:modelValue', value)
  }
}
</script>

<template>
  <ToggleGroupRoot
    :model-value="modelValue"
    :type="type"
    :class="cn('inline-flex items-center gap-0.5 rounded-md', props.class)"
    @update:model-value="handleUpdateModelValue"
  >
    <slot />
  </ToggleGroupRoot>
</template>
