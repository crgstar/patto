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
const limit = ref(20)
const refreshing = ref(false)
const manageDialogOpen = ref(false)
const scrollContainerRef = ref(null)
const unreadCountsCache = ref({}) // 各フィードソースの未読件数をキャッシュ

// カーソル追跡型ツールチップ用のState
const mouseX = ref(0)
const mouseY = ref(0)
const hoveredItem = ref(null)

// Computed
const currentOffset = computed(() => feedItemStore.feedItems.length)
const hasMore = computed(() => feedItemStore.hasMore)
const loading = computed(() => feedItemStore.loading)

const unreadCounts = computed(() => {
  // キャッシュから開始
  const counts = { ...unreadCountsCache.value }

  // 現在のfeedItemsから未読件数を計算
  const currentCounts = { all: 0 }
  feedItemStore.feedItems.forEach(item => {
    if (!item.read) {
      currentCounts.all++
      const feedSourceId = String(item.feed_source_id)
      if (!currentCounts[feedSourceId]) {
        currentCounts[feedSourceId] = 0
      }
      currentCounts[feedSourceId]++
    }
  })

  // キャッシュと現在のカウントをマージ（現在のカウントを優先）
  Object.keys(currentCounts).forEach(key => {
    counts[key] = currentCounts[key]
  })

  return counts
})

const selectedFeedName = computed(() => {
  if (selectedFeedSourceId.value === 'all') {
    return 'すべてのフィード'
  }
  const sfs = stickyFeedSourceStore.stickyFeedSources.find(
    s => String(s.feed_source_id) === selectedFeedSourceId.value
  )
  return sfs ? (sfs.feed_source.title || sfs.feed_source.url) : ''
})

const currentUnreadCount = computed(() => {
  if (selectedFeedSourceId.value === 'all') {
    return unreadCounts.value.all || 0
  }
  return unreadCounts.value[selectedFeedSourceId.value] || 0
})

// Methods
const fetchFeedItems = async (append = false) => {
  try {
    const feedSourceId = selectedFeedSourceId.value === 'all' ? null : parseInt(selectedFeedSourceId.value)
    await feedItemStore.fetchFeedItems(props.feedReader.id, {
      offset: append ? currentOffset.value : 0,
      limit: limit.value,
      feed_source_id: feedSourceId,
      append: append
    })
    // 取得したフィードアイテムから未読件数を計算してキャッシュに保存
    await updateUnreadCountsCache()
  } catch (error) {
    console.error('Failed to fetch feed items:', error)
  }
}

const updateUnreadCountsCache = async () => {
  // 現在のfeedItemsから未読件数を計算
  const counts = {}
  feedItemStore.feedItems.forEach(item => {
    if (!item.read) {
      const feedSourceId = String(item.feed_source_id)
      if (!counts[feedSourceId]) {
        counts[feedSourceId] = 0
      }
      counts[feedSourceId]++
    }
  })

  // キャッシュを更新（既存のキャッシュとマージ）
  unreadCountsCache.value = {
    ...unreadCountsCache.value,
    ...counts
  }
}

const handleScroll = async (event) => {
  const target = event.target
  const scrollTop = target.scrollTop
  const scrollHeight = target.scrollHeight
  const clientHeight = target.clientHeight

  // 底から100px以内でトリガー
  const threshold = 100
  const isNearBottom = scrollTop + clientHeight >= scrollHeight - threshold

  if (isNearBottom && hasMore.value && !loading.value) {
    await fetchFeedItems(true) // append=true
  }
}

const handleRefresh = async () => {
  refreshing.value = true
  try {
    await feedItemStore.refreshAll(props.feedReader.id)
    feedItemStore.resetFeedItems()
    await fetchFeedItems(false)
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

// カーソル追跡型ツールチップのハンドラー
const handleMouseEnter = (event, item) => {
  if (item.description) {
    hoveredItem.value = item
    updateMousePosition(event)
  }
}

const handleMouseMove = (event) => {
  if (hoveredItem.value) {
    updateMousePosition(event)
  }
}

const handleMouseLeave = () => {
  hoveredItem.value = null
}

const updateMousePosition = (event) => {
  mouseX.value = event.clientX
  mouseY.value = event.clientY
}

// フィードソース更新ハンドラー
const handleFeedSourceUpdated = async () => {
  await stickyFeedSourceStore.fetchStickyFeedSources(props.feedReader.id)
  // フィードアイテムを再取得
  feedItemStore.resetFeedItems()
  await fetchFeedItems(false)
}

// Lifecycle
onMounted(async () => {
  await stickyFeedSourceStore.fetchStickyFeedSources(props.feedReader.id)
  await fetchFeedItems(false)
})

// Watch
watch(selectedFeedSourceId, (newValue, oldValue) => {
  if (newValue === '__manage__') {
    manageDialogOpen.value = true
    // 元の値に戻す
    selectedFeedSourceId.value = previousFeedSourceId.value
    return
  }

  // 通常のフィードソース変更時
  previousFeedSourceId.value = newValue
  feedItemStore.resetFeedItems()
  fetchFeedItems(false)
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
            <div class="flex items-center gap-2">
              <span class="truncate">{{ selectedFeedName }}</span>
              <span
                v-if="currentUnreadCount > 0"
                class="inline-flex items-center justify-center px-1.5 py-0.5 text-[10px] font-medium leading-none rounded-full bg-emerald-100 dark:bg-emerald-900/30 text-emerald-800 dark:text-emerald-300 flex-shrink-0 min-w-[20px]"
              >
                {{ currentUnreadCount }}
              </span>
            </div>
          </SelectTrigger>
          <SelectContent>
            <SelectItem value="all">
              <div class="flex items-center justify-between w-full gap-2">
                <span>すべてのフィード</span>
                <span
                  v-if="(unreadCounts.all || 0) > 0"
                  class="inline-flex items-center justify-center px-1.5 py-0.5 text-[10px] font-medium leading-none rounded-full bg-emerald-100 dark:bg-emerald-900/30 text-emerald-800 dark:text-emerald-300 flex-shrink-0 min-w-[20px]"
                >
                  {{ unreadCounts.all }}
                </span>
              </div>
            </SelectItem>
            <SelectSeparator v-if="stickyFeedSourceStore.stickyFeedSources.length > 0" />
            <SelectItem
              v-for="sfs in stickyFeedSourceStore.stickyFeedSources"
              :key="sfs.id"
              :value="String(sfs.feed_source_id)"
            >
              <div class="flex items-center justify-between w-full gap-2">
                <span class="truncate">{{ sfs.feed_source.title || sfs.feed_source.url }}</span>
                <span
                  v-if="(unreadCounts[String(sfs.feed_source_id)] || 0) > 0"
                  class="inline-flex items-center justify-center px-1.5 py-0.5 text-[10px] font-medium leading-none rounded-full bg-emerald-100 dark:bg-emerald-900/30 text-emerald-800 dark:text-emerald-300 flex-shrink-0 min-w-[20px]"
                >
                  {{ unreadCounts[String(sfs.feed_source_id)] }}
                </span>
              </div>
            </SelectItem>
            <SelectSeparator />
            <SelectItem value="__manage__">
              <Settings class="mr-2 h-3.5 w-3.5 inline" />
              フィードを管理
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
    <div
      ref="scrollContainerRef"
      @scroll="handleScroll"
      class="flex-1 overflow-y-auto px-2 py-1 scrollbar-subtle"
    >
      <div v-if="feedItemStore.feedItems.length === 0 && !loading" class="py-4 text-center">
        <p class="text-sm text-muted-foreground">フィードがありません</p>
      </div>
      <div v-else class="space-y-1">
        <div
          v-for="item in feedItemStore.feedItems"
          :key="item.id"
          @click="handleItemClick(item)"
          @mouseenter="handleMouseEnter($event, item)"
          @mousemove="handleMouseMove"
          @mouseleave="handleMouseLeave"
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
              <h4 class="text-sm font-normal leading-relaxed tracking-wide line-clamp-2">{{ item.title }}</h4>

              <!-- 説明（省略表示）: descriptionがある場合のみ表示 -->
              <p v-if="item.description" class="text-xs text-muted-foreground leading-relaxed line-clamp-1">
                {{ item.description }}
              </p>

              <!-- 日付とドメイン -->
              <div class="flex items-center gap-2 mt-1">
                <!-- 日付表示 -->
                <span class="text-xs text-muted-foreground tracking-wide">
                  {{ formatDate(item.published_at) }}
                </span>

                <!-- ドメインバッジ -->
                <div
                  v-if="item.feed_source?.domain"
                  class="inline-flex items-center gap-1 px-2 py-0.5 rounded-md bg-muted dark:bg-muted-foreground/20 border border-border text-xs text-muted-foreground"
                >
                  <img
                    :src="`https://www.google.com/s2/favicons?domain=${item.feed_source.domain}&sz=16`"
                    :alt="`${item.feed_source.domain} favicon`"
                    class="h-3 w-3 flex-shrink-0"
                    loading="lazy"
                    @error="$event.target.style.display='none'"
                  />
                  <span class="truncate max-w-[100px] tracking-wide">{{ item.feed_source.domain }}</span>
                </div>
              </div>
            </div>
          </div>
        </div>

        <!-- ローディング表示 -->
        <div v-if="loading" class="py-2 text-center">
          <RefreshCw class="h-4 w-4 animate-spin inline" />
          <span class="ml-2 text-xs text-muted-foreground">読み込み中...</span>
        </div>

        <!-- すべて読み込みました -->
        <div v-if="!hasMore && feedItemStore.feedItems.length > 0" class="py-2 text-center">
          <p class="text-xs text-muted-foreground">すべて読み込みました</p>
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

    <!-- カーソル追跡型カスタムツールチップ -->
    <Teleport to="body">
      <div
        v-if="hoveredItem"
        :style="{
          position: 'fixed',
          left: `${mouseX + 15}px`,
          top: `${mouseY + 15}px`,
          zIndex: 9999,
          pointerEvents: 'none'
        }"
        class="max-w-xl px-3 py-1.5 rounded-md bg-popover text-popover-foreground shadow-md border-2 border-secondary/30 divide-y divide-border/30"
      >
        <div class="text-sm pb-2">{{ hoveredItem.title }}</div>
        <div class="text-xs pt-2 leading-relaxed">{{ hoveredItem.description }}</div>
      </div>
    </Teleport>
  </div>
</template>
