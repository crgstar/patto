<script setup>
import { onMounted, ref } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import { useStickyStore } from '@/stores/sticky'
import { Card, CardHeader, CardTitle, CardContent } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import GridLayout from '@/components/GridLayout.vue'
import StickyContextMenu from '@/components/StickyContextMenu.vue'
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuLabel,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from '@/components/ui/dropdown-menu'
import { ThemeToggle } from '@/components/ui/theme-toggle'
import { User, Plus, Edit2, Trash2, MoreVertical, StickyNote } from 'lucide-vue-next'

const router = useRouter()
const authStore = useAuthStore()
const stickyStore = useStickyStore()

const editingId = ref(null)

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

const updateSticky = async (id, field, value) => {
  await stickyStore.updateSticky(id, { [field]: value })
}

const deleteSticky = async (id) => {
  if (confirm('この付箋を削除してもよろしいですか？')) {
    await stickyStore.deleteSticky(id)
  }
}

// レイアウト変更時の処理
const handleLayoutUpdated = async (newLayout) => {
  await stickyStore.updateLayout(newLayout)
}
</script>

<template>
  <div class="min-h-screen bg-background">
    <!-- ヘッダー -->
    <header class="border-b bg-background">
      <div class="flex items-center justify-between px-6 py-4">
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
              <DropdownMenuItem @click="handleLogout">
                ログアウト
              </DropdownMenuItem>
            </DropdownMenuContent>
          </DropdownMenu>
        </div>
      </div>
    </header>

    <!-- 付箋一覧 -->
    <main class="px-4 py-6">
      <div v-if="stickyStore.stickies.length === 0" class="flex flex-col items-center justify-center py-24 text-center">
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

      <StickyContextMenu @create-sticky="handleCreateStickyFromContext" v-else>
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
            <template #item="{ item: sticky }">
              <Card
                class="group bg-card border-border shadow-sm hover:shadow-md hover:border-accent/50 transition-all h-full overflow-hidden"
              >
                <CardHeader class="flex flex-row items-center justify-between space-y-0 pb-2">
                  <!-- タイトル表示/編集 -->
                  <div class="flex-1 flex items-center gap-2">
                    <input
                      v-if="editingId === sticky.id"
                      :value="sticky.title"
                      @blur="finishEditingTitle(sticky.id, $event.target.value)"
                      @keyup.enter="finishEditingTitle(sticky.id, $event.target.value)"
                      :data-sticky-title-id="sticky.id"
                      :data-testid="`sticky-${sticky.id}-title`"
                      placeholder="タイトル"
                      class="font-semibold bg-transparent border-b border-accent focus:border-accent p-1 w-full outline-none text-foreground placeholder:text-muted-foreground"
                    />
                    <div v-else class="flex items-center gap-2 flex-1">
                      <span class="font-semibold text-foreground">
                        {{ sticky.title || 'タイトル' }}
                      </span>
                      <Button
                        @click="startEditingTitle(sticky.id)"
                        variant="ghost"
                        size="icon"
                        class="h-6 w-6 opacity-0 group-hover:opacity-100 transition-opacity"
                      >
                        <Edit2 class="h-3 w-3" />
                      </Button>
                    </div>
                  </div>

                  <!-- オプションメニュー -->
                  <DropdownMenu>
                    <DropdownMenuTrigger as-child>
                      <Button
                        variant="ghost"
                        size="icon"
                        class="h-6 w-6 hover:bg-accent/10"
                      >
                        <MoreVertical class="h-4 w-4" />
                      </Button>
                    </DropdownMenuTrigger>
                    <DropdownMenuContent align="end">
                      <DropdownMenuItem @click="startEditingTitle(sticky.id)">
                        <Edit2 class="mr-2 h-4 w-4" />
                        タイトルを編集
                      </DropdownMenuItem>
                      <DropdownMenuSeparator />
                      <DropdownMenuItem
                        @click="deleteSticky(sticky.id)"
                        :data-testid="`delete-sticky-${sticky.id}`"
                        class="text-destructive focus:text-destructive"
                      >
                        <Trash2 class="mr-2 h-4 w-4" />
                        削除
                      </DropdownMenuItem>
                    </DropdownMenuContent>
                  </DropdownMenu>
                </CardHeader>
                <CardContent class="h-[calc(100%-60px)]">
                  <textarea
                    :value="sticky.content"
                    @blur="updateSticky(sticky.id, 'content', $event.target.value)"
                    :data-testid="`sticky-${sticky.id}-content`"
                    placeholder="内容を入力..."
                    class="bg-transparent border-none focus-visible:ring-0 resize-none w-full h-full outline-none text-foreground placeholder:text-muted-foreground"
                  />
                </CardContent>
              </Card>
            </template>
          </GridLayout>
        </div>
      </StickyContextMenu>
    </main>
  </div>
</template>
