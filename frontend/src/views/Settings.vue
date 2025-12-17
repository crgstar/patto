<script setup>
import { ref, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { useFeedSourceStore } from '@/stores/feedSource'
import { Card, CardHeader, CardTitle, CardDescription, CardContent } from '@/components/ui/card'
import { Input } from '@/components/ui/input'
import { Textarea } from '@/components/ui/textarea'
import { Label } from '@/components/ui/label'
import { Button } from '@/components/ui/button'
import {
  AlertDialog,
  AlertDialogContent,
  AlertDialogHeader,
  AlertDialogTitle,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogCancel,
  AlertDialogAction
} from '@/components/ui/alert-dialog'
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuTrigger
} from '@/components/ui/dropdown-menu'
import { ArrowLeft, Plus, Edit, Trash2, MoreVertical } from 'lucide-vue-next'

const router = useRouter()
const feedSourceStore = useFeedSourceStore()

// フォーム入力
const url = ref('')
const title = ref('')
const description = ref('')

// 編集モード
const editingId = ref(null)
const editingData = ref({ title: '', description: '' })

// 削除確認ダイアログ
const deleteDialogOpen = ref(false)
const deleteTargetId = ref(null)

onMounted(async () => {
  await feedSourceStore.fetchFeedSources()
})

const handleCreate = async () => {
  const success = await feedSourceStore.createFeedSource({
    url: url.value,
    title: title.value || null,
    description: description.value || null
  })

  if (success) {
    // フォームをクリア
    url.value = ''
    title.value = ''
    description.value = ''
  }
}

const startEdit = (feedSource) => {
  editingId.value = feedSource.id
  editingData.value = {
    title: feedSource.title || '',
    description: feedSource.description || ''
  }
}

const handleUpdate = async (id) => {
  const success = await feedSourceStore.updateFeedSource(id, editingData.value)
  if (success) {
    editingId.value = null
  }
}

const cancelEdit = () => {
  editingId.value = null
}

const openDeleteDialog = (id) => {
  deleteTargetId.value = id
  deleteDialogOpen.value = true
}

const handleDelete = async () => {
  if (deleteTargetId.value) {
    await feedSourceStore.deleteFeedSource(deleteTargetId.value)
    deleteDialogOpen.value = false
    deleteTargetId.value = null
  }
}
</script>

<template>
  <div class="min-h-screen bg-background">
    <!-- Header -->
    <header class="border-b bg-background sticky top-0 z-10">
      <div class="flex items-center justify-between px-4 py-3 max-w-4xl mx-auto">
        <div class="flex items-center gap-3">
          <Button
            variant="ghost"
            size="icon"
            @click="router.push('/')"
            class="rounded-full hover:bg-accent/10"
          >
            <ArrowLeft class="h-5 w-5" />
          </Button>
          <h1 class="text-2xl font-bold">フィード設定</h1>
        </div>
      </div>
    </header>

    <!-- Main Content -->
    <main class="px-4 py-6 max-w-4xl mx-auto space-y-6">
      <!-- エラー表示 -->
      <div
        v-if="feedSourceStore.error"
        class="p-3 text-sm text-destructive-foreground bg-destructive/10 rounded-md border border-destructive/30"
      >
        {{ feedSourceStore.error }}
      </div>

      <!-- フィード追加フォーム -->
      <Card>
        <CardHeader>
          <CardTitle>新しいフィードを追加</CardTitle>
          <CardDescription>RSSまたはAtomフィードのURLを入力してください</CardDescription>
        </CardHeader>
        <CardContent class="space-y-4">
          <div class="space-y-2">
            <Label for="url">URL *</Label>
            <Input
              id="url"
              v-model="url"
              type="url"
              placeholder="https://example.com/feed.xml"
              required
            />
          </div>

          <div class="space-y-2">
            <Label for="title">タイトル（任意）</Label>
            <Input
              id="title"
              v-model="title"
              placeholder="自動取得されますが、上書きできます"
            />
          </div>

          <div class="space-y-2">
            <Label for="description">説明（任意）</Label>
            <Textarea
              id="description"
              v-model="description"
              placeholder="メモや説明を入力"
              class="min-h-[80px]"
            />
          </div>

          <Button
            @click="handleCreate"
            :disabled="!url || feedSourceStore.loading"
            class="w-full"
          >
            <Plus class="mr-2 h-4 w-4" />
            {{ feedSourceStore.loading ? '追加中...' : 'フィードを追加' }}
          </Button>
        </CardContent>
      </Card>

      <!-- フィード一覧 -->
      <div>
        <h2 class="text-xl font-semibold mb-4">登録済みフィード</h2>

        <div v-if="feedSourceStore.feedSources.length === 0" class="text-center py-8">
          <p class="text-muted-foreground">まだフィードが登録されていません</p>
        </div>

        <div v-else class="grid grid-cols-1 md:grid-cols-2 gap-4">
          <Card
            v-for="feedSource in feedSourceStore.feedSources"
            :key="feedSource.id"
            class="relative"
          >
            <CardHeader>
              <div class="flex items-start justify-between gap-2">
                <div class="flex-1 min-w-0">
                  <!-- 編集モード -->
                  <div v-if="editingId === feedSource.id" class="space-y-2">
                    <Input
                      v-model="editingData.title"
                      placeholder="タイトル"
                    />
                    <Textarea
                      v-model="editingData.description"
                      placeholder="説明"
                      class="min-h-[60px]"
                    />
                    <div class="flex gap-2">
                      <Button
                        @click="handleUpdate(feedSource.id)"
                        size="sm"
                      >
                        保存
                      </Button>
                      <Button
                        @click="cancelEdit"
                        variant="ghost"
                        size="sm"
                      >
                        キャンセル
                      </Button>
                    </div>
                  </div>

                  <!-- 通常表示 -->
                  <div v-else>
                    <CardTitle class="text-lg break-words">
                      {{ feedSource.title || 'タイトルなし' }}
                    </CardTitle>
                    <p class="text-xs text-muted-foreground mt-1 break-all">
                      {{ feedSource.url }}
                    </p>
                    <p v-if="feedSource.description" class="text-sm text-muted-foreground mt-2 break-words">
                      {{ feedSource.description }}
                    </p>
                  </div>
                </div>

                <!-- アクションメニュー -->
                <DropdownMenu>
                  <DropdownMenuTrigger as-child>
                    <Button
                      variant="ghost"
                      size="icon"
                      class="h-8 w-8 flex-shrink-0"
                    >
                      <MoreVertical class="h-4 w-4" />
                    </Button>
                  </DropdownMenuTrigger>
                  <DropdownMenuContent align="end">
                    <DropdownMenuItem @click="startEdit(feedSource)">
                      <Edit class="mr-2 h-4 w-4" />
                      編集
                    </DropdownMenuItem>
                    <DropdownMenuItem
                      @click="openDeleteDialog(feedSource.id)"
                      class="text-destructive focus:text-destructive"
                    >
                      <Trash2 class="mr-2 h-4 w-4" />
                      削除
                    </DropdownMenuItem>
                  </DropdownMenuContent>
                </DropdownMenu>
              </div>
            </CardHeader>
          </Card>
        </div>
      </div>
    </main>

    <!-- 削除確認ダイアログ -->
    <AlertDialog v-model:open="deleteDialogOpen">
      <AlertDialogContent>
        <AlertDialogHeader>
          <AlertDialogTitle>フィードを削除しますか?</AlertDialogTitle>
          <AlertDialogDescription>
            このフィードを削除すると、このフィードを使用しているすべてのStickyから削除されます。この操作は取り消せません。
          </AlertDialogDescription>
        </AlertDialogHeader>
        <AlertDialogFooter>
          <AlertDialogCancel>キャンセル</AlertDialogCancel>
          <AlertDialogAction
            @click="handleDelete"
            class="bg-destructive text-destructive-foreground hover:bg-destructive/90"
          >
            削除
          </AlertDialogAction>
        </AlertDialogFooter>
      </AlertDialogContent>
    </AlertDialog>
  </div>
</template>
