<script setup>
import { ref, computed, watch, onMounted, onUnmounted } from 'vue'
import { useStickyFeedSourceStore } from '@/stores/stickyFeedSource'
import { useFeedItemStore } from '@/stores/feedItem'
import { useFeedSourceStore } from '@/stores/feedSource'
import { Button } from '@/components/ui/button'
import {
  Select,
  SelectContent,
  SelectItem,
  SelectSeparator,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select'
import {
  Tooltip,
  TooltipContent,
  TooltipProvider,
  TooltipTrigger,
} from '@/components/ui/tooltip'
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuTrigger,
} from '@/components/ui/dropdown-menu'
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog'
import FeedSourceManager from '@/components/FeedSourceManager.vue'
import { MoreVertical, Trash2, RefreshCw, Settings } from 'lucide-vue-next'
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

// State
const selectedFeedSourceId = ref('all') // 'all' = 'すべてのフィード'
const previousFeedSourceId = ref('all') // Dialog開く前の値を保持
const page = ref(0)
const limit = ref(20)
const hasMore = ref(true)
const loading = ref(false)
const refreshing = ref(false)
const manageDialogOpen = ref(false)

// Computed
const unreadCounts = computed(() => {
  const counts = { all: 0 }
  feedItemStore.feedItems.forEach(item => {
    if (!item.read) {
      counts.all++
      const feedSourceId = String(item.feed_source_id)
      if (!counts[feedSourceId]) {
        counts[feedSourceId] = 0
      }
      counts[feedSourceId]++
    }
  })
  return counts
})

// Methods
const fetchFeedItems = async () => {
  loading.value = true
  try {
    const feedSourceId = selectedFeedSourceId.value === 'all' ? null : parseInt(selectedFeedSourceId.value)
    await feedItemStore.fetchFeedItems(props.feedReader.id, {
      offset: page.value * limit.value,
      limit: limit.value,
      feed_source_id: feedSourceId,
    })
  } catch (error) {
    console.error('Failed to fetch feed items:', error)
  } finally {
    loading.value = false
  }
}

const handleRefresh = async () => {
  refreshing.value = true
  try {
    await feedItemStore.refreshAll(props.feedReader.id)
    page.value = 0
    await fetchFeedItems()
  } catch (error) {
    console.error('Failed to refresh feed items:', error)
  } finally {
    refreshing.value = false
  }
}

const handleItemClick = async (item) => {
  // 既読化
  if (!item.read) {
    await feedItemStore.markAsRead(props.feedReader.id, item.id)
  }
  // URLを開く
  window.open(item.url, '_blank')
}

const formatDate = (dateString) => {
  const date = new Date(dateString)
  const now = new Date()
  const diff = now - date

  if (diff < 3600000) { // 1時間以内
    const minutes = Math.floor(diff / 60000)
    return minutes === 0 ? 'たった今' : `${minutes}分前`
  }

  if (diff < 86400000) { // 1日以内
    return `${Math.floor(diff / 3600000)}時間前`
  }

  if (diff < 604800000) { // 1週間以内
    return `${Math.floor(diff / 86400000)}日前`
  }

  return date.toLocaleDateString('ja-JP', {
    year: 'numeric',
    month: 'short',
    day: 'numeric'
  })
}

// 削除ハンドラー
const handleDelete = () => {
  emit('delete', props.feedReader.id)
}

// フィードソース更新ハンドラー
const handleFeedSourceUpdated = async () => {
  await stickyFeedSourceStore.fetchStickyFeedSources(props.feedReader.id)
  manageDialogOpen.value = false
  // フィードアイテムを再取得
  page.value = 0
  await fetchFeedItems()
}

// Lifecycle
onMounted(async () => {
  await stickyFeedSourceStore.fetchStickyFeedSources(props.feedReader.id)
  await fetchFeedItems()
})

// Watch
watch(selectedFeedSourceId, (newValue, oldValue) => {
  // 「フィードソースを管理...」が選択された場合
  if (newValue === '__manage__') {
    manageDialogOpen.value = true
    // 元の値に戻す
    selectedFeedSourceId.value = previousFeedSourceId.value
    return
  }

  // 通常のフィードソース変更時
  previousFeedSourceId.value = newValue
  page.value = 0
  hasMore.value = true
  fetchFeedItems()
})
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
      <div class="flex items-center gap-2">
        <!-- フィードソース選択 -->
        <Select v-model="selectedFeedSourceId" class="flex-1">
          <SelectTrigger class="h-7 text-xs">
            <SelectValue placeholder="すべてのフィード" />
          </SelectTrigger>
          <SelectContent>
            <SelectItem value="all">
              すべてのフィード ({{ unreadCounts.all || 0 }})
            </SelectItem>
            <SelectSeparator v-if="stickyFeedSourceStore.stickyFeedSources.length > 0" />
            <SelectItem
              v-for="sfs in stickyFeedSourceStore.stickyFeedSources"
              :key="sfs.id"
              :value="String(sfs.feed_source_id)"
            >
              {{ sfs.feed_source.title || sfs.feed_source.url }} ({{ unreadCounts[String(sfs.feed_source_id)] || 0 }})
            </SelectItem>
            <SelectSeparator />
            <SelectItem value="__manage__">
              <Settings class="mr-2 h-3.5 w-3.5 inline" />
              フィードソースを管理...
            </SelectItem>
          </SelectContent>
        </Select>

        <!-- リフレッシュボタン -->
        <Button
          @click="handleRefresh"
          size="icon"
          variant="ghost"
          class="h-7 w-7"
          :disabled="refreshing"
        >
          <RefreshCw :class="cn('h-3.5 w-3.5', refreshing && 'animate-spin')" />
        </Button>
      </div>
    </div>

    <!-- フィードアイテムリスト -->
    <div class="flex-1 overflow-y-auto px-2 py-1 scrollbar-subtle">
      <div v-if="feedItemStore.feedItems.length === 0 && !loading" class="py-4 text-center">
        <p class="text-sm text-muted-foreground">フィードがありません</p>
      </div>
      <div v-else class="space-y-1">
        <TooltipProvider :delay-duration="0">
          <template v-for="item in feedItemStore.feedItems" :key="item.id">
            <!-- descriptionがある場合: Tooltip付き -->
            <Tooltip v-if="item.description">
              <TooltipTrigger as-child>
                <div
                  @click="handleItemClick(item)"
                  :class="cn(
                    'p-2 rounded-md cursor-pointer transition-colors',
                    'hover:bg-accent/10',
                    !item.read && 'bg-accent/5'
                  )"
                >
                  <div class="flex items-start gap-2">
                    <!-- 未読インジケーター -->
                    <div v-if="!item.read" class="w-2 h-2 rounded-full bg-secondary mt-1 flex-shrink-0" />
                    <div v-else class="w-2 flex-shrink-0" />

                    <div class="flex-1 min-w-0">
                      <!-- タイトル -->
                      <h4 class="text-sm font-medium line-clamp-2">{{ item.title }}</h4>

                      <!-- 説明（省略表示） -->
                      <p class="text-xs text-muted-foreground line-clamp-1">
                        {{ item.description }}
                      </p>

                      <!-- 日付 -->
                      <p class="text-[10px] text-muted-foreground mt-0.5">
                        {{ formatDate(item.published_at) }}
                      </p>
                    </div>
                  </div>
                </div>
              </TooltipTrigger>
              <TooltipContent side="right">
                <p class="max-w-xs">{{ item.description }}</p>
              </TooltipContent>
            </Tooltip>

            <!-- descriptionがない場合: Tooltipなし -->
            <div
              v-else
              @click="handleItemClick(item)"
              :class="cn(
                'p-2 rounded-md cursor-pointer transition-colors',
                'hover:bg-accent/10',
                !item.read && 'bg-accent/5'
              )"
            >
              <div class="flex items-start gap-2">
                <!-- 未読インジケーター -->
                <div v-if="!item.read" class="w-2 h-2 rounded-full bg-secondary mt-1 flex-shrink-0" />
                <div v-else class="w-2 flex-shrink-0" />

                <div class="flex-1 min-w-0">
                  <!-- タイトル -->
                  <h4 class="text-sm font-medium line-clamp-2">{{ item.title }}</h4>

                  <!-- 日付 -->
                  <p class="text-[10px] text-muted-foreground mt-0.5">
                    {{ formatDate(item.published_at) }}
                  </p>
                </div>
              </div>
            </div>
          </template>
        </TooltipProvider>

        <!-- ローディング -->
        <div v-if="loading" class="py-2 text-center">
          <RefreshCw class="h-4 w-4 animate-spin inline" />
        </div>
      </div>
    </div>

    <!-- フィードソース管理Dialog -->
    <Dialog v-model:open="manageDialogOpen">
      <DialogContent>
        <FeedSourceManager
          :sticky-id="feedReader.id"
          @updated="handleFeedSourceUpdated"
        />
      </DialogContent>
    </Dialog>
  </div>
</template>
