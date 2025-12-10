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
import { User, Plus, Edit2, Trash2, MoreVertical } from 'lucide-vue-next'

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
      <div class="flex items-center justify-end gap-3 px-6 py-4">
        <!-- 新しい付箋ボタン -->
        <Button
          @click="createSticky"
          data-testid="create-sticky-button"
          variant="ghost"
          size="icon"
          class="rounded-full bg-blue-50 hover:bg-blue-100"
        >
          <Plus class="h-5 w-5 text-blue-600" />
        </Button>

        <!-- ユーザーメニュー -->
        <DropdownMenu>
          <DropdownMenuTrigger as-child>
            <Button variant="ghost" size="icon" class="rounded-full bg-blue-50 hover:bg-blue-100">
              <User class="h-5 w-5 text-blue-600" />
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
    </header>

    <!-- 付箋一覧 -->
    <main class="px-4 py-6">
      <div v-if="stickyStore.stickies.length === 0" class="text-center py-12 text-muted-foreground">
        付箋がありません。右クリックで付箋を作成できます。
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
                class="group bg-gradient-to-br from-blue-50 to-indigo-50 border-blue-200 shadow-sm hover:shadow-md transition-shadow h-full overflow-hidden"
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
                      class="font-semibold bg-transparent border-b border-blue-300 focus:border-blue-500 p-1 w-full outline-none text-foreground placeholder:text-muted-foreground"
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
                        class="h-6 w-6 hover:bg-gray-200"
                      >
                        <MoreVertical class="h-4 w-4 text-gray-600" />
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
