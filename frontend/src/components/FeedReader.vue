<script setup>
import { ref, computed, watch, onMounted, onUnmounted } from 'vue'
import { useStickyFeedSourceStore } from '@/stores/stickyFeedSource'
import { useFeedItemStore } from '@/stores/feedItem'
import { useFeedSourceStore } from '@/stores/feedSource'
import { Button } from '@/components/ui/button'
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuTrigger,
} from '@/components/ui/dropdown-menu'
import { MoreVertical, Trash2 } from 'lucide-vue-next'
import { cn } from '@/lib/utils'

const props = defineProps({
  feedReader: {
    type: Object,
    required: true,
  },
  width: {
    type: Number,
    required: true,
  },
  height: {
    type: Number,
    required: true,
  },
})

const emit = defineEmits(['delete'])

// ストア
const stickyFeedSourceStore = useStickyFeedSourceStore()
const feedItemStore = useFeedItemStore()
const feedSourceStore = useFeedSourceStore()

// 削除ハンドラー
const handleDelete = () => {
  emit('delete', props.feedReader.id)
}
</script>

<template>
  <div
    :class="
      cn(
        'h-full w-full bg-card border border-border rounded-lg shadow-sm flex flex-col overflow-hidden relative',
      )
    "
  >
    <!-- 削除ボタン（右上に配置、常に表示） -->
    <div class="absolute top-1 right-1 z-10">
      <DropdownMenu>
        <DropdownMenuTrigger as-child>
          <Button
            variant="ghost"
            size="icon"
            class="h-5 w-5 hover:bg-accent/10 p-0 flex-shrink-0"
          >
            <MoreVertical class="h-3.5 w-3.5" />
          </Button>
        </DropdownMenuTrigger>
        <DropdownMenuContent align="end">
          <DropdownMenuItem
            @click="handleDelete"
            data-testid="delete-feedreader-button"
            class="text-destructive focus:text-destructive"
          >
            <Trash2 class="mr-2 h-4 w-4" />
            削除
          </DropdownMenuItem>
        </DropdownMenuContent>
      </DropdownMenu>
    </div>

    <!-- ヘッダー -->
    <div class="px-3 pt-2 pb-1 pr-8">
      <p class="text-sm text-muted-foreground">フィードリーダー</p>
    </div>

    <!-- コンテンツエリア（プレースホルダー） -->
    <div class="flex-1 overflow-y-auto px-2 py-1">
      <div class="py-4 text-center">
        <p class="text-sm text-muted-foreground">フィードを読み込み中...</p>
      </div>
    </div>
  </div>
</template>
