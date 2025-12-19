<script setup>
import { ref, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { useFeedSourceStore } from '@/stores/feedSource'
import { Input } from '@/components/ui/input'
import { Textarea } from '@/components/ui/textarea'
import { Label } from '@/components/ui/label'
import { Button } from '@/components/ui/button'
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogDescription,
  DialogTrigger
} from '@/components/ui/dialog'
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
import { ArrowLeft, Plus, Edit, Trash2, Check, X } from 'lucide-vue-next'

const router = useRouter()
const feedSourceStore = useFeedSourceStore()

// フォーム入力
const url = ref('')
const title = ref('')
const description = ref('')

// フィード追加ダイアログ
const addDialogOpen = ref(false)

// 編集モード
const editingId = ref(null)
const editingData = ref({ title: '', description: '' })

// 削除確認ダイアログ
const deleteDialogOpen = ref(false)
const deleteTargetId = ref(null)

onMounted(async () => {
  await feedSourceStore.fetchFeedSources()
})

const clearForm = () => {
  url.value = ''
  title.value = ''
  description.value = ''
}

const handleCreate = async () => {
  const success = await feedSourceStore.createFeedSource({
    url: url.value,
    title: title.value || null,
    description: description.value || null
  })

  if (success) {
    // フォームをクリアしてダイアログを閉じる
    clearForm()
    addDialogOpen.value = false
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
      <!-- エラー表示（編集・削除時のみ） -->
      <div
        v-if="feedSourceStore.error && !addDialogOpen"
        class="p-3 text-sm text-destructive-foreground bg-destructive/10 rounded-md border border-destructive/30"
      >
        {{ feedSourceStore.error }}
      </div>

      <!-- フィード一覧 -->
      <div>
        <div class="flex justify-between items-center mb-4">
          <h2 class="text-xl font-semibold"></h2>

          <!-- フィード追加ダイアログ -->
          <Dialog v-model:open="addDialogOpen" @update:open="(open) => !open && clearForm()">
            <DialogTrigger as-child>
              <Button>
                <Plus class="mr-2 h-4 w-4" />
                新しいフィードを追加
              </Button>
            </DialogTrigger>
            <DialogContent class="sm:max-w-[500px]">
              <DialogHeader>
                <DialogTitle>新しいフィードを追加</DialogTitle>
                <DialogDescription>
                  RSSまたはAtomフィードのURLを入力してください
                </DialogDescription>
              </DialogHeader>

              <!-- エラー表示（作成時のみ） -->
              <div
                v-if="feedSourceStore.error && addDialogOpen"
                class="p-3 text-sm text-destructive-foreground bg-destructive/10 rounded-md border border-destructive/30"
              >
                {{ feedSourceStore.error }}
              </div>

              <div class="space-y-4 py-4">
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
              </div>

              <div class="flex justify-end gap-3">
                <Button
                  variant="outline"
                  @click="addDialogOpen = false"
                >
                  キャンセル
                </Button>
                <Button
                  @click="handleCreate"
                  :disabled="!url || feedSourceStore.loading"
                >
                  <Plus class="mr-2 h-4 w-4" />
                  {{ feedSourceStore.loading ? '追加中...' : 'フィードを追加' }}
                </Button>
              </div>
            </DialogContent>
          </Dialog>
        </div>

        <div v-if="feedSourceStore.feedSources.length === 0" class="text-center py-8 border border-border rounded-lg bg-card">
          <p class="text-muted-foreground">まだフィードが登録されていません</p>
        </div>

        <div v-else class="border border-border rounded-lg overflow-hidden">
          <!-- テーブルヘッダー -->
          <div class="bg-muted/50 border-b border-border">
            <div class="grid grid-cols-[2fr_3fr_3fr_auto] gap-4 px-4 py-2 items-center">
              <div class="text-xs font-medium text-muted-foreground">タイトル</div>
              <div class="text-xs font-medium text-muted-foreground">URL</div>
              <div class="text-xs font-medium text-muted-foreground">説明</div>
              <div class="text-xs font-medium text-muted-foreground text-center w-20">操作</div>
            </div>
          </div>

          <!-- テーブルボディ -->
          <div class="divide-y divide-border bg-card">
            <div
              v-for="feedSource in feedSourceStore.feedSources"
              :key="feedSource.id"
              class="transition-colors hover:bg-accent/5"
            >
              <!-- 編集モード -->
              <div v-if="editingId === feedSource.id" class="grid grid-cols-[2fr_3fr_3fr_auto] gap-4 px-4 py-3 items-start">
                <Input
                  v-model="editingData.title"
                  placeholder="タイトル"
                  class="h-9"
                />
                <div class="text-xs text-muted-foreground py-2 break-all">
                  {{ feedSource.url }}
                </div>
                <Textarea
                  v-model="editingData.description"
                  placeholder="説明"
                  class="min-h-[36px] resize-none"
                  rows="1"
                />
                <div class="flex gap-1 justify-center w-20">
                  <Button
                    @click="handleUpdate(feedSource.id)"
                    variant="ghost"
                    size="icon"
                    class="h-8 w-8 text-green-600 hover:text-green-700 hover:bg-green-50 dark:text-green-500 dark:hover:text-green-400 dark:hover:bg-green-950"
                    title="保存"
                  >
                    <Check class="h-4 w-4" />
                  </Button>
                  <Button
                    @click="cancelEdit"
                    variant="ghost"
                    size="icon"
                    class="h-8 w-8 text-muted-foreground hover:text-foreground"
                    title="キャンセル"
                  >
                    <X class="h-4 w-4" />
                  </Button>
                </div>
              </div>

              <!-- 通常表示 -->
              <div v-else class="grid grid-cols-[2fr_3fr_3fr_auto] gap-4 px-4 py-3 items-center">
                <div class="text-sm font-medium text-foreground truncate" :title="feedSource.title || 'タイトルなし'">
                  {{ feedSource.title || 'タイトルなし' }}
                </div>
                <div class="text-xs text-muted-foreground truncate" :title="feedSource.url">
                  {{ feedSource.url }}
                </div>
                <div class="text-xs text-muted-foreground truncate" :title="feedSource.description || ''">
                  {{ feedSource.description || '-' }}
                </div>
                <div class="flex gap-1 justify-center w-20">
                  <Button
                    @click="startEdit(feedSource)"
                    variant="ghost"
                    size="icon"
                    class="h-8 w-8"
                    title="編集"
                  >
                    <Edit class="h-4 w-4" />
                  </Button>
                  <Button
                    @click="openDeleteDialog(feedSource.id)"
                    variant="ghost"
                    size="icon"
                    class="h-8 w-8 text-destructive hover:text-destructive"
                    title="削除"
                  >
                    <Trash2 class="h-4 w-4" />
                  </Button>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </main>

    <!-- 削除確認ダイアログ -->
    <AlertDialog v-model:open="deleteDialogOpen">
      <AlertDialogContent>
        <AlertDialogHeader>
          <AlertDialogTitle>フィードを削除しますか?</AlertDialogTitle>
          <AlertDialogDescription>
            このフィードを削除すると、このフィードを使用しているすべてのフィードリーダーから削除されます。この操作は取り消せません。
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
