<script setup>
import { GridLayout as GridLayoutPlus, GridItem } from 'grid-layout-plus'

const props = defineProps({
  layout: {
    type: Array,
    required: true
  },
  colNum: {
    type: Number,
    default: 12
  },
  rowHeight: {
    type: Number,
    default: 100
  },
  isDraggable: {
    type: Boolean,
    default: true
  },
  isResizable: {
    type: Boolean,
    default: true
  },
  verticalCompact: {
    type: Boolean,
    default: true
  },
  preventCollision: {
    type: Boolean,
    default: false
  },
  margin: {
    type: Array,
    default: () => [10, 10]
  },
  useCssTransforms: {
    type: Boolean,
    default: true
  }
})

const emit = defineEmits(['update:layout', 'layout-updated'])

const handleLayoutUpdated = (newLayout) => {
  emit('update:layout', newLayout)
  emit('layout-updated', newLayout)
}
</script>

<template>
  <GridLayoutPlus
    :layout="layout"
    :col-num="colNum"
    :row-height="rowHeight"
    :is-draggable="isDraggable"
    :is-resizable="isResizable"
    :vertical-compact="verticalCompact"
    :prevent-collision="preventCollision"
    :margin="margin"
    :use-css-transforms="useCssTransforms"
    @layout-updated="handleLayoutUpdated"
  >
    <GridItem
      v-for="item in layout"
      :key="item.i"
      :x="item.x"
      :y="item.y"
      :w="item.w"
      :h="item.h"
      :i="item.i"
      :static="item.static || false"
    >
      <slot name="item" :item="item.sticky" />
    </GridItem>
  </GridLayoutPlus>
</template>

<style>
/* grid-layout-plusのスタイルを適用 */
.vgl-layout {
  /* プレースホルダーの背景色を落ち着いた色に変更 */
  --vgl-placeholder-bg: hsl(var(--muted-foreground)) !important;
  --vgl-placeholder-opacity: 15% !important;
  background: transparent;
}

.vgl-item {
  touch-action: none;
}

.vgl-item--placeholder {
  background: hsl(var(--muted-foreground) / 0.15) !important;
  opacity: 1 !important;
  transition-duration: 100ms;
  z-index: 2;
  border-radius: var(--radius);
}

.vgl-item__resizer {
  opacity: 0;
}

.vgl-item:not(.vgl-item--placeholder) {
  background: transparent;
  border: none;
}
</style>
