<script setup>
import { onMounted, ref } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import { useStickyStore } from '@/stores/sticky'
import { Card, CardHeader, CardTitle, CardContent } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import GridLayout from '@/components/GridLayout.vue'
import StickyContextMenu from '@/components/StickyContextMenu.vue'
import Calendar from '@/components/Calendar.vue'
import Checklist from '@/components/Checklist.vue'
import FeedReader from '@/components/FeedReader.vue'
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuLabel,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from '@/components/ui/dropdown-menu'
import {
  AlertDialog,
  AlertDialogAction,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
} from '@/components/ui/alert-dialog'
import { ThemeToggle } from '@/components/ui/theme-toggle'
import { User, Plus, Trash2, MoreVertical, StickyNote, Settings } from 'lucide-vue-next'
import { cn } from '@/lib/utils'

const router = useRouter()
const authStore = useAuthStore()
const stickyStore = useStickyStore()

const editingId = ref(null)
const deleteDialogOpen = ref(false)
const deleteTargetId = ref(null)
const deleteTargetType = ref(null) // 'sticky', 'calendar', 'checklist', or 'feedreader'

const startEditingTitle = (id) => {
  editingId.value = id
  // 次のティックでinputにフォーカス
  setTimeout(() => {
    const input = document.querySelector(`[data-sticky-title-id="${id}"]`)
    if (input) input.focus()
  }, 0)
}

const finishEditingTitle = (id, value) => {
  editingId.value = null
  updateSticky(id, 'title', value)
}

onMounted(async () => {
  const success = await authStore.fetchCurrentUser()
  if (!success) {
    router.push('/login')
    return
  }

  await stickyStore.fetchStickies()
})

const handleLogout = async () => {
  await authStore.logout()
  router.push('/login')
}

// 新しい付箋を作成（ヘッダーのボタン用）
const createSticky = async () => {
  await stickyStore.createSticky({
    type: 'Sticky',
    title: '',
    content: ''
  })
}

// コンテキストメニューから付箋を作成（座標指定なし）
const handleCreateStickyFromContext = async () => {
  await createSticky()
}

// コンテキストメニューからカレンダーを作成（デフォルトで2x2の正方形）
const handleCreateCalendarFromContext = async () => {
  await stickyStore.createSticky({
    type: 'Calendar',
    title: '',
    content: '',
    width: 2,
    height: 2
  })
}

// コンテキストメニューからチェックリストを作成（デフォルトで2x2の正方形）
const handleCreateChecklistFromContext = async () => {
  await stickyStore.createSticky({
    type: 'Checklist',
    title: '',
    content: '',
    width: 2,
    height: 2
  })
}

// コンテキストメニューからフィードリーダーを作成（デフォルトで3x3）
const handleCreateFeedReaderFromContext = async () => {
  await stickyStore.createSticky({
    type: 'FeedReader',
    title: '',
    content: '',
    width: 3,
    height: 3
  })
}

// チェックリストアイテムのハンドラー
const handleAddChecklistItem = async (checklistId, content) => {
  await stickyStore.createChecklistItem(checklistId, content)
}

const handleUpdateChecklistItem = async (checklistId, itemId, updates) => {
  await stickyStore.updateChecklistItem(checklistId, itemId, updates)
}

const handleDeleteChecklistItem = async (checklistId, itemId) => {
  await stickyStore.deleteChecklistItem(checklistId, itemId)
}

const handleReorderChecklistItems = async (checklistId, items) => {
  await stickyStore.reorderChecklistItems(checklistId, items)
}

const updateSticky = async (id, field, value) => {
  await stickyStore.updateSticky(id, { [field]: value })
}

const openDeleteDialog = (id, type) => {
  deleteTargetId.value = id
  deleteTargetType.value = type
  deleteDialogOpen.value = true
}

const deleteSticky = (id) => {
  openDeleteDialog(id, 'sticky')
}

// カレンダー専用のハンドラー
const deleteCalendar = (id) => {
  openDeleteDialog(id, 'calendar')
}

// チェックリスト専用のハンドラー
const deleteChecklist = (id) => {
  openDeleteDialog(id, 'checklist')
}

// フィードリーダー専用のハンドラー
const deleteFeedReader = (id) => {
  openDeleteDialog(id, 'feedreader')
}

const confirmDelete = async () => {
  if (deleteTargetId.value !== null) {
    await stickyStore.deleteSticky(deleteTargetId.value)
    deleteDialogOpen.value = false
    deleteTargetId.value = null
    deleteTargetType.value = null
  }
}

// レイアウト変更時の処理
const handleLayoutUpdated = async (newLayout) => {
  await stickyStore.updateLayout(newLayout)
}

// 付箋のサイズに基づいてフォントサイズを計算
const getFontSize = (sticky) => {
  const area = sticky.width * sticky.height

  // 面積に応じてフォントサイズを調整
  if (area <= 1) {
    // 1x1: 極小
    return { content: 'text-xs', title: 'text-sm' }
  } else if (area <= 2) {
    // 1x2, 2x1: 小
    return { content: 'text-sm', title: 'text-base' }
  } else if (area <= 4) {
    // 2x2: 中
    return { content: 'text-base', title: 'text-lg' }
  } else if (area <= 6) {
    // 2x3, 3x2: やや大
    return { content: 'text-lg', title: 'text-xl' }
  } else {
    // 3x3以上: 大
    return { content: 'text-xl', title: 'text-2xl' }
  }
}

// 付箋のサイズに基づいて余白を計算
const getPadding = (sticky) => {
  const area = sticky.width * sticky.height

  // 面積に応じて余白を調整
  if (area <= 1) {
    // 1x1: 最小余白
    return {
      header: 'p-2 pb-0.5',
      content: 'p-2 pt-0',
      contentHeight: 'h-[calc(100%-32px)]'
    }
  } else if (area <= 2) {
    // 1x2, 2x1: 小さめ余白
    return {
      header: 'p-2.5 pb-1',
      content: 'p-2.5 pt-0',
      contentHeight: 'h-[calc(100%-38px)]'
    }
  } else if (area <= 4) {
    // 2x2: 標準余白
    return {
      header: 'p-3 pb-1.5',
      content: 'p-3 pt-0',
      contentHeight: 'h-[calc(100%-44px)]'
    }
  } else if (area <= 6) {
    // 2x3, 3x2: やや大きめ余白
    return {
      header: 'p-4 pb-2',
      content: 'p-4 pt-0',
      contentHeight: 'h-[calc(100%-56px)]'
    }
  } else {
    // 3x3以上: 大きめ余白
    return {
      header: 'p-5 pb-2.5',
      content: 'p-5 pt-0',
      contentHeight: 'h-[calc(100%-68px)]'
    }
  }
}
</script>

<template>
  <div class="min-h-screen bg-background">
    <!-- ヘッダー -->
    <header class="border-b bg-background">
      <div class="flex items-center justify-between px-3 py-1.5">
        <!-- 左側: アプリケーションタイトル -->
        <div class="flex items-center gap-2">
          <StickyNote class="h-6 w-6 text-secondary" />
          <h1 class="text-xl font-bold text-foreground">Patto</h1>
        </div>

        <!-- 右側: アクションボタン -->
        <div class="flex items-center gap-3">
          <!-- 新しい付箋ボタン -->
          <Button
            @click="createSticky"
            data-testid="create-sticky-button"
            variant="ghost"
            size="icon"
            class="rounded-full hover:bg-accent/10"
          >
            <Plus class="h-5 w-5" />
          </Button>

          <!-- テーマ切り替えボタン -->
          <ThemeToggle />

          <!-- ユーザーメニュー -->
          <DropdownMenu>
            <DropdownMenuTrigger as-child>
              <Button variant="ghost" size="icon" class="rounded-full hover:bg-accent/10">
                <User class="h-5 w-5" />
              </Button>
            </DropdownMenuTrigger>
            <DropdownMenuContent align="end" class="w-56">
              <DropdownMenuLabel>
                <div class="flex flex-col space-y-1">
                  <p class="text-sm font-medium leading-none">ログインユーザー</p>
                  <p class="text-xs leading-none text-muted-foreground" v-if="authStore.user">
                    {{ authStore.user.email }}
                  </p>
                </div>
              </DropdownMenuLabel>
              <DropdownMenuSeparator />
              <DropdownMenuItem @click="router.push('/settings')">
                <Settings class="mr-2 h-4 w-4" />
                フィード設定
              </DropdownMenuItem>
              <DropdownMenuItem @click="handleLogout">
                ログアウト
              </DropdownMenuItem>
            </DropdownMenuContent>
          </DropdownMenu>
        </div>
      </div>
    </header>

    <!-- 付箋一覧 -->
    <main class="px-1 py-1">
      <div v-if="stickyStore.stickies.length === 0" class="flex flex-col items-center justify-center py-8 text-center">
        <StickyNote class="h-16 w-16 text-muted-foreground/50 mb-4" />
        <h2 class="text-xl font-semibold text-foreground mb-2">
          まだ付箋がありません
        </h2>
        <p class="text-muted-foreground mb-6 max-w-sm">
          右クリックまたは上部の<Plus class="inline h-4 w-4 mx-1" />ボタンで付箋を作成できます
        </p>
        <Button @click="createSticky" variant="secondary">
          <Plus class="mr-2 h-4 w-4" />
          最初の付箋を作成
        </Button>
      </div>

      <StickyContextMenu
        @create-sticky="handleCreateStickyFromContext"
        @create-calendar="handleCreateCalendarFromContext"
        @create-checklist="handleCreateChecklistFromContext"
        @create-feedreader="handleCreateFeedReaderFromContext"
        v-else
      >
        <div class="min-h-[600px]">
          <GridLayout
            :layout="stickyStore.layout"
            :col-num="12"
            :row-height="100"
            :is-draggable="true"
            :is-resizable="true"
            :vertical-compact="true"
            :prevent-collision="false"
            @layout-updated="handleLayoutUpdated"
          >
            <template #item="{ item }">
              <!-- チェックリスト付箋 -->
              <Checklist
                v-if="item.sticky.type === 'Checklist'"
                :checklist="item.sticky"
                :width="item.w"
                :height="item.h"
                @add-item="handleAddChecklistItem(item.sticky.id, $event)"
                @update-item="(itemId, updates) => handleUpdateChecklistItem(item.sticky.id, itemId, updates)"
                @delete-item="handleDeleteChecklistItem(item.sticky.id, $event)"
                @reorder-items="handleReorderChecklistItems(item.sticky.id, $event)"
                @delete="deleteChecklist"
              />

              <!-- カレンダー付箋 -->
              <Calendar
                v-else-if="item.sticky.type === 'Calendar'"
                :sticky="item.sticky"
                @delete="deleteCalendar"
              />

              <!-- フィードリーダー付箋 -->
              <FeedReader
                v-else-if="item.sticky.type === 'FeedReader'"
                :feed-reader="item.sticky"
                :width="item.w"
                :height="item.h"
                @delete="deleteFeedReader"
              />

              <!-- 通常の付箋 -->
              <Card
                v-else
                class="group bg-card border-border shadow-sm hover:shadow-md hover:border-accent/50 transition-all h-full overflow-hidden"
              >
                <CardHeader :class="cn('flex flex-row items-center justify-between space-y-0', getPadding(item.sticky).header)">
                  <!-- タイトル表示/編集 -->
                  <div class="flex-1 flex items-center gap-1">
                    <input
                      v-if="editingId === item.sticky.id"
                      :value="item.sticky.title"
                      @blur="finishEditingTitle(item.sticky.id, $event.target.value)"
                      @keyup.enter="finishEditingTitle(item.sticky.id, $event.target.value)"
                      :data-sticky-title-id="item.sticky.id"
                      :data-testid="`sticky-${item.sticky.id}-title`"
                      placeholder="タイトル"
                      :class="cn('font-semibold bg-transparent border-b border-accent focus:border-accent px-0.5 py-0 w-full outline-none text-foreground placeholder:text-muted-foreground', getFontSize(item.sticky).title)"
                    />
                    <div
                      v-else
                      @click="startEditingTitle(item.sticky.id)"
                      class="flex items-center gap-2 flex-1 cursor-text"
                    >
                      <span :class="cn('font-semibold truncate', item.sticky.title ? 'text-foreground' : 'text-muted-foreground', getFontSize(item.sticky).title)">
                        {{ item.sticky.title || 'タイトル' }}
                      </span>
                    </div>
                  </div>

                  <!-- オプションメニュー -->
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
                        @click="deleteSticky(item.sticky.id)"
                        :data-testid="`delete-sticky-${item.sticky.id}`"
                        class="text-destructive focus:text-destructive"
                      >
                        <Trash2 class="mr-2 h-4 w-4" />
                        削除
                      </DropdownMenuItem>
                    </DropdownMenuContent>
                  </DropdownMenu>
                </CardHeader>
                <CardContent :class="cn('overflow-hidden', getPadding(item.sticky).content, getPadding(item.sticky).contentHeight)">
                  <textarea
                    :value="item.sticky.content"
                    @blur="updateSticky(item.sticky.id, 'content', $event.target.value)"
                    :data-testid="`sticky-${item.sticky.id}-content`"
                    placeholder="内容を入力..."
                    :class="cn('bg-transparent border-none focus-visible:ring-0 resize-none w-full h-full outline-none text-foreground placeholder:text-muted-foreground overflow-hidden', getFontSize(item.sticky).content)"
                  />
                </CardContent>
              </Card>
            </template>
          </GridLayout>
        </div>
      </StickyContextMenu>
    </main>

    <!-- 削除確認ダイアログ -->
    <AlertDialog v-model:open="deleteDialogOpen">
      <AlertDialogContent>
        <AlertDialogHeader>
          <AlertDialogTitle>削除の確認</AlertDialogTitle>
          <AlertDialogDescription>
            この{{ deleteTargetType === 'calendar' ? 'カレンダー' : deleteTargetType === 'checklist' ? 'チェックリスト' : deleteTargetType === 'feedreader' ? 'フィードリーダー' : '付箋' }}を削除してもよろしいですか？この操作は取り消せません。
          </AlertDialogDescription>
        </AlertDialogHeader>
        <AlertDialogFooter>
          <AlertDialogCancel>キャンセル</AlertDialogCancel>
          <AlertDialogAction
            @click="confirmDelete"
            class="bg-destructive text-destructive-foreground hover:bg-destructive/90"
          >
            削除
          </AlertDialogAction>
        </AlertDialogFooter>
      </AlertDialogContent>
    </AlertDialog>
  </div>
</template>
