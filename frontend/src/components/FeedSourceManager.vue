<script setup>
import { ref, computed, onMounted } from 'vue'
import { useFeedSourceStore } from '@/stores/feedSource'
import { useStickyFeedSourceStore } from '@/stores/stickyFeedSource'
import { Checkbox } from '@/components/ui/checkbox'
import { Label } from '@/components/ui/label'

const props = defineProps({
  stickyId: {
    type: Number,
    required: true
  }
})

const emit = defineEmits(['updated'])

const feedSourceStore = useFeedSourceStore()
const stickyFeedSourceStore = useStickyFeedSourceStore()

const loading = ref(false)

// 選択済みのフィードソースIDのセット
const selectedFeedSourceIds = computed(() => {
  return new Set(
    stickyFeedSourceStore.stickyFeedSources.map(sfs => sfs.feed_source_id)
  )
})

// 各フィードソースが選択されているかチェック
const isSelected = (feedSourceId) => {
  return selectedFeedSourceIds.value.has(feedSourceId)
}

// フィードソースの選択/選択解除を処理
const handleToggle = async (feedSourceId, checked) => {
  loading.value = true

  try {
    if (checked) {
      // 追加
      const success = await stickyFeedSourceStore.createStickyFeedSource(
        props.stickyId,
        feedSourceId
      )
      if (success) {
        emit('updated')
      }
    } else {
      // 削除
      const stickyFeedSource = stickyFeedSourceStore.stickyFeedSources.find(
        sfs => sfs.feed_source_id === feedSourceId
      )
      if (stickyFeedSource) {
        const success = await stickyFeedSourceStore.deleteStickyFeedSource(
          props.stickyId,
          stickyFeedSource.id
        )
        if (success) {
          emit('updated')
        }
      }
    }
  } finally {
    loading.value = false
  }
}

// 初期化
onMounted(async () => {
  await feedSourceStore.fetchFeedSources()
  await stickyFeedSourceStore.fetchStickyFeedSources(props.stickyId)
})
</script>

<template>
  <div class="space-y-4">
    <p class="text-sm text-muted-foreground">
      このフィードリーダーに表示するフィードを選択してください
    </p>

    <div v-if="feedSourceStore.loading" class="py-4 text-center">
      <p class="text-sm text-muted-foreground">読み込み中...</p>
    </div>

    <div v-else-if="feedSourceStore.feedSources.length === 0" class="py-4 text-center">
      <p class="text-sm text-muted-foreground">フィードがありません</p>
    </div>

    <div v-else class="space-y-3">
      <div
        v-for="feedSource in feedSourceStore.feedSources"
        :key="feedSource.id"
        class="flex items-start space-x-3 p-3 rounded-md border hover:bg-accent/50 transition-colors"
      >
        <Checkbox
          :id="`feed-source-${feedSource.id}`"
          :checked="isSelected(feedSource.id)"
          :disabled="loading"
          @update:modelValue="(checked) => handleToggle(feedSource.id, checked)"
        />
        <div class="flex-1 space-y-1">
          <Label
            :for="`feed-source-${feedSource.id}`"
            class="text-sm font-medium leading-none cursor-pointer"
          >
            {{ feedSource.title }}
          </Label>
          <p class="text-xs text-muted-foreground">
            {{ feedSource.url }}
          </p>
          <p v-if="feedSource.description" class="text-xs text-muted-foreground">
            {{ feedSource.description }}
          </p>
        </div>
      </div>
    </div>

    <div v-if="feedSourceStore.error" class="text-sm text-destructive">
      {{ feedSourceStore.error }}
    </div>

    <div v-if="stickyFeedSourceStore.error" class="text-sm text-destructive">
      {{ stickyFeedSourceStore.error }}
    </div>
  </div>
</template>
