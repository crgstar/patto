<script setup>
import {
  ContextMenu,
  ContextMenuTrigger,
  ContextMenuContent,
  ContextMenuItem,
  ContextMenuSeparator
} from '@/components/ui/context-menu'
import { StickyNote, CheckSquare, Calendar, Rss } from 'lucide-vue-next'

const emit = defineEmits(['create-sticky', 'create-checklist', 'create-calendar', 'create-feedreader'])

const handleCreateSticky = (event) => {
  emit('create-sticky', event)
}

const handleCreateChecklist = (event) => {
  emit('create-checklist', event)
}

const handleCreateCalendar = (event) => {
  emit('create-calendar', event)
}

const handleCreateFeedReader = (event) => {
  emit('create-feedreader', event)
}
</script>

<template>
  <ContextMenu>
    <ContextMenuTrigger as-child>
      <slot />
    </ContextMenuTrigger>
    <ContextMenuContent class="w-56">
      <ContextMenuItem
        @select="handleCreateSticky"
        class="cursor-pointer"
      >
        <StickyNote class="mr-2 h-4 w-4" />
        <span>付箋を作成</span>
      </ContextMenuItem>
      <ContextMenuSeparator />
      <ContextMenuItem
        @select="handleCreateChecklist"
        class="cursor-pointer"
      >
        <CheckSquare class="mr-2 h-4 w-4" />
        <span>チェックリスト</span>
      </ContextMenuItem>
      <ContextMenuItem
        @select="handleCreateCalendar"
        class="cursor-pointer"
      >
        <Calendar class="mr-2 h-4 w-4" />
        <span>カレンダー</span>
      </ContextMenuItem>
      <ContextMenuItem
        @select="handleCreateFeedReader"
        class="cursor-pointer"
      >
        <Rss class="mr-2 h-4 w-4" />
        <span>フィードリーダー</span>
      </ContextMenuItem>
    </ContextMenuContent>
  </ContextMenu>
</template>
