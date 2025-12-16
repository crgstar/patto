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

// カレンダーのサイズを2または3に制限する関数
const normalizeCalendarSize = (size) => {
  // 1以下 -> 2
  // 2 -> 2
  // 3 -> 3
  // 4以上 -> 3
  if (size <= 1) return 2
  if (size === 2) return 2
  return 3  // 3以上は全て3
}

const handleLayoutUpdated = (newLayout) => {
  // カレンダーを正方形に強制（grid-layout-plusの内部更新後も保証）
  const correctedLayout = newLayout.map(item => {
    if (item.sticky && item.sticky.type === 'Calendar') {
      const maxSize = Math.max(item.w, item.h)
      const size = normalizeCalendarSize(maxSize)
      if (item.w !== size || item.h !== size) {
        return { ...item, w: size, h: size }
      }
    }
    return item
  })

  emit('update:layout', correctedLayout)
  emit('layout-updated', correctedLayout)
}

// リサイズ中のイベントハンドラー（カレンダーを正方形に強制）
const handleResize = (i, newH, newW) => {
  // リサイズされているアイテムを見つける
  const item = props.layout.find(layoutItem => layoutItem.i === i)
  if (!item || !item.sticky) return

  // カレンダーの場合、正方形に強制
  if (item.sticky.type === 'Calendar') {
    // より大きい方の値に合わせて、2または3に正規化
    const maxSize = Math.max(newW, newH)
    const size = normalizeCalendarSize(maxSize)

    // 現在のサイズと異なる場合のみ更新
    if (item.w !== size || item.h !== size) {
      // layoutを更新
      const updatedLayout = props.layout.map(layoutItem => {
        if (layoutItem.i === i) {
          return {
            ...layoutItem,
            w: size,
            h: size
          }
        }
        return layoutItem
      })

      // レイアウトを更新
      emit('update:layout', updatedLayout)
    }
  }
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
      @resize="handleResize"
    >
      <slot name="item" :item="item" />
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
