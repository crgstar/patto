<script setup>
import { onMounted, ref } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import { useStickyStore } from '@/stores/sticky'
import { Card, CardHeader, CardTitle, CardContent } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Textarea } from '@/components/ui/textarea'
import { VueDraggable } from 'vue-draggable-plus'

const router = useRouter()
const authStore = useAuthStore()
const stickyStore = useStickyStore()

const editingId = ref(null)

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

const createSticky = async () => {
  const maxPosition = stickyStore.stickies.length > 0
    ? Math.max(...stickyStore.stickies.map(s => s.position))
    : 0

  await stickyStore.createSticky({
    type: 'Sticky',
    title: '',
    content: '',
    position: maxPosition + 1
  })
}

const updateSticky = async (id, field, value) => {
  await stickyStore.updateSticky(id, { [field]: value })
}

const deleteSticky = async (id) => {
  if (confirm('この付箋を削除してもよろしいですか？')) {
    await stickyStore.deleteSticky(id)
  }
}

const handleDragEnd = async () => {
  // 現在の順番でpositionを更新
  const reorderedStickies = stickyStore.stickies.map((sticky, index) => ({
    ...sticky,
    position: index + 1
  }))

  await stickyStore.reorderStickies(reorderedStickies)
}
</script>

<template>
  <div class="min-h-screen bg-background p-4">
    <div class="max-w-4xl mx-auto">
      <Card class="mb-4 shadow-md">
        <CardHeader class="flex flex-row items-center justify-between">
          <CardTitle>ダッシュボード</CardTitle>
          <Button @click="handleLogout" variant="outline">
            ログアウト
          </Button>
        </CardHeader>
        <CardContent>
          <div v-if="authStore.user" class="space-y-2">
            <p class="text-sm text-muted-foreground">ログイン中のユーザー</p>
            <p class="text-lg font-semibold text-foreground">{{ authStore.user.email }}</p>
          </div>
          <div v-else class="text-center text-muted-foreground">
            ユーザー情報を読み込み中...
          </div>
        </CardContent>
      </Card>

      <!-- Sticky一覧 -->
      <div class="mb-4">
        <div class="flex items-center justify-between mb-4">
          <h2 class="text-2xl font-bold text-foreground">付箋</h2>
          <Button @click="createSticky" data-testid="create-sticky-button">
            新しい付箋
          </Button>
        </div>

        <div v-if="stickyStore.stickies.length === 0" class="text-center py-12 text-muted-foreground">
          付箋がありません
        </div>

        <VueDraggable
          v-else
          v-model="stickyStore.stickies"
          @end="handleDragEnd"
          class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4"
          :animation="200"
        >
          <Card
            v-for="sticky in stickyStore.stickies"
            :key="sticky.id"
            class="bg-gradient-to-br from-blue-50 to-indigo-50 border-blue-200 cursor-move shadow-sm hover:shadow-md transition-shadow"
          >
            <CardHeader>
              <input
                :value="sticky.title"
                @blur="updateSticky(sticky.id, 'title', $event.target.value)"
                :data-testid="`sticky-${sticky.id}-title`"
                placeholder="タイトル"
                class="font-semibold bg-transparent border-none focus-visible:ring-0 p-0 w-full outline-none text-foreground placeholder:text-muted-foreground"
              />
            </CardHeader>
            <CardContent>
              <textarea
                :value="sticky.content"
                @blur="updateSticky(sticky.id, 'content', $event.target.value)"
                :data-testid="`sticky-${sticky.id}-content`"
                placeholder="内容を入力..."
                class="bg-transparent border-none focus-visible:ring-0 resize-none min-h-[100px] w-full outline-none text-foreground placeholder:text-muted-foreground"
              />
              <div class="mt-4 flex justify-end">
                <Button
                  @click="deleteSticky(sticky.id)"
                  :data-testid="`delete-sticky-${sticky.id}`"
                  variant="ghost"
                  size="sm"
                  class="text-destructive hover:text-destructive/80"
                >
                  削除
                </Button>
              </div>
            </CardContent>
          </Card>
        </VueDraggable>
      </div>
    </div>
  </div>
</template>
