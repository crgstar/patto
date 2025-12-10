<script setup>
import {
  ContextMenu,
  ContextMenuTrigger,
  ContextMenuContent,
  ContextMenuItem,
  ContextMenuSeparator
} from '@/components/ui/context-menu'
import { StickyNote, ListTodo, Calendar } from 'lucide-vue-next'

const emit = defineEmits(['create-sticky'])

const handleCreateSticky = (event) => {
  emit('create-sticky', event)
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
      <ContextMenuItem disabled class="cursor-not-allowed opacity-50">
        <ListTodo class="mr-2 h-4 w-4" />
        <span>TODO</span>
        <span class="ml-auto text-xs text-muted-foreground">未実装</span>
      </ContextMenuItem>
      <ContextMenuItem disabled class="cursor-not-allowed opacity-50">
        <Calendar class="mr-2 h-4 w-4" />
        <span>カレンダー</span>
        <span class="ml-auto text-xs text-muted-foreground">未実装</span>
      </ContextMenuItem>
    </ContextMenuContent>
  </ContextMenu>
</template>
