import { defineStore } from 'pinia'
import { ref } from 'vue'
import apiClient from '@/lib/apiClient'

export const useStickyFeedSourceStore = defineStore('stickyFeedSource', () => {
  const stickyFeedSources = ref([])
  const loading = ref(false)
  const error = ref(null)

  // Sticky用フィードソース一覧を取得
  const fetchStickyFeedSources = async (stickyId) => {
    loading.value = true
    error.value = null

    try {
      const response = await apiClient.get(`/stickies/${stickyId}/sticky_feed_sources`)
      stickyFeedSources.value = response.data.sticky_feed_sources
    } catch (err) {
      error.value = err.response?.data?.error || 'Sticky用フィード一覧の取得に失敗しました'
    } finally {
      loading.value = false
    }
  }

  // Sticky用フィードソースを作成
  const createStickyFeedSource = async (stickyId, feedSourceId) => {
    loading.value = true
    error.value = null

    try {
      const response = await apiClient.post(`/stickies/${stickyId}/sticky_feed_sources`, {
        sticky_feed_source: { feed_source_id: feedSourceId }
      })

      stickyFeedSources.value.push(response.data.sticky_feed_source)
      return true
    } catch (err) {
      error.value = err.response?.data?.errors?.[0] || 'Sticky用フィードの追加に失敗しました'
      return false
    } finally {
      loading.value = false
    }
  }

  // Sticky用フィードソースを削除
  const deleteStickyFeedSource = async (stickyId, stickyFeedSourceId) => {
    loading.value = true
    error.value = null

    try {
      await apiClient.delete(`/stickies/${stickyId}/sticky_feed_sources/${stickyFeedSourceId}`)

      stickyFeedSources.value = stickyFeedSources.value.filter(sfs => sfs.id !== stickyFeedSourceId)
      return true
    } catch (err) {
      error.value = err.response?.data?.error || 'Sticky用フィードの削除に失敗しました'
      return false
    } finally {
      loading.value = false
    }
  }

  return {
    stickyFeedSources,
    loading,
    error,
    fetchStickyFeedSources,
    createStickyFeedSource,
    deleteStickyFeedSource
  }
})
